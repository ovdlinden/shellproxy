#!/bin/bash
# shellproxy installer
# Usage: curl -fsSL https://raw.githubusercontent.com/ovdlinden/shellproxy/main/install.sh | bash
set -euo pipefail

INSTALL_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"
REPO_URL="https://github.com/ovdlinden/shellproxy.git"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}▸${NC} $*"; }
warn() { echo -e "${YELLOW}▸${NC} $*"; }
error() { echo -e "${RED}▸${NC} $*" >&2; }

# Parse arguments
LOCAL_INSTALL=false
SOURCE_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --local)
            LOCAL_INSTALL=true
            SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            shift
            ;;
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --local       Install from local directory (for development)"
            echo "  --dir <path>  Install to custom directory (default: ~/.shellproxy)"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BOLD}shellproxy installer${NC}"
echo ""

# Check dependencies
log "Checking dependencies..."

if ! command -v git &>/dev/null; then
    error "git is required but not installed"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    warn "docker not found - container routing will not work"
fi

if ! command -v curl &>/dev/null; then
    warn "curl not found - fast container health checks unavailable"
fi

# Remove existing installation
if [[ -d "$INSTALL_DIR" ]]; then
    warn "Existing installation found at $INSTALL_DIR"
    read -rp "Remove and reinstall? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        error "Installation cancelled"
        exit 1
    fi
fi

# Install
log "Installing to $INSTALL_DIR..."

if [[ "$LOCAL_INSTALL" == "true" ]]; then
    # Copy from local directory
    mkdir -p "$INSTALL_DIR"
    cp -r "$SOURCE_DIR"/{lib,hooks,dispatch,shellproxy} "$INSTALL_DIR/"
    mkdir -p "$INSTALL_DIR/bin"
else
    # Clone from GitHub
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || {
        error "Failed to clone repository"
        exit 1
    }

    # Clean up git files for cleaner installation
    rm -rf "$INSTALL_DIR/.git" "$INSTALL_DIR/.github" "$INSTALL_DIR/test"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/dispatch"
chmod +x "$INSTALL_DIR/shellproxy"
chmod +x "$INSTALL_DIR/lib/"*.sh
chmod +x "$INSTALL_DIR/hooks/"*.{zsh,bash,fish} 2>/dev/null || true

# Create default shims
log "Creating command shims..."

default_shims=(php node npm npx yarn pnpm composer artisan)

for cmd in "${default_shims[@]}"; do
    ln -sf "$INSTALL_DIR/dispatch" "$INSTALL_DIR/bin/$cmd"
done

log "Created shims for: ${default_shims[*]}"

# Detect shell and suggest hook installation
log "Detecting shell..."

shell_name=$(basename "$SHELL")
shell_rc=""
hook_file=""

case "$shell_name" in
    zsh)
        shell_rc="$HOME/.zshrc"
        hook_file="$INSTALL_DIR/hooks/hook.zsh"
        ;;
    bash)
        # Prefer .bashrc, fall back to .bash_profile
        if [[ -f "$HOME/.bashrc" ]]; then
            shell_rc="$HOME/.bashrc"
        else
            shell_rc="$HOME/.bash_profile"
        fi
        hook_file="$INSTALL_DIR/hooks/hook.bash"
        ;;
    fish)
        shell_rc="$HOME/.config/fish/config.fish"
        hook_file="$INSTALL_DIR/hooks/hook.fish"
        ;;
    *)
        warn "Unknown shell: $shell_name"
        warn "You'll need to manually add the hook to your shell config"
        ;;
esac

if [[ -n "$shell_rc" && -n "$hook_file" ]]; then
    source_line="source $hook_file"

    # Check if already added
    if [[ -f "$shell_rc" ]] && grep -qF "$hook_file" "$shell_rc" 2>/dev/null; then
        log "Hook already configured in $shell_rc"
    else
        {
            echo ""
            echo "# shellproxy - transparent Docker command routing"
            echo "$source_line"
        } >> "$shell_rc"
        log "Added hook to $shell_rc"
    fi
fi

# Done
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${NC}"
echo ""
echo "To activate in current shell:"
echo -e "  ${BOLD}source $hook_file${NC}"
echo ""
echo "Or restart your terminal."
echo ""
echo "Quick start:"
echo "  shellproxy status    # Show current project status"
echo "  shellproxy info      # Learn more"
echo "  shellproxy help      # See all commands"

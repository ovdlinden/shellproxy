#!/bin/bash
# shellproxy uninstaller
set -euo pipefail

INSTALL_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}▸${NC} $*"; }
warn() { echo -e "${YELLOW}▸${NC} $*"; }
error() { echo -e "${RED}▸${NC} $*" >&2; }

echo -e "${BOLD}shellproxy uninstaller${NC}"
echo ""

# Check if installed
if [[ ! -d "$INSTALL_DIR" ]]; then
    warn "shellproxy not found at $INSTALL_DIR"
    exit 0
fi

# Confirm
read -rp "Remove shellproxy from $INSTALL_DIR? [y/N] " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log "Uninstall cancelled"
    exit 0
fi

# Remove from shell configs
log "Cleaning up shell configurations..."

shell_configs=(
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.config/fish/config.fish"
)

for rc in "${shell_configs[@]}"; do
    if [[ -f "$rc" ]]; then
        # Remove shellproxy lines
        if grep -q "shellproxy" "$rc" 2>/dev/null; then
            # Create backup
            cp "$rc" "$rc.shellproxy-backup"

            # Remove lines containing shellproxy hook
            grep -v "shellproxy" "$rc" > "$rc.tmp" || true
            mv "$rc.tmp" "$rc"

            log "Cleaned $rc (backup: $rc.shellproxy-backup)"
        fi
    fi
done

# Remove installation directory
log "Removing $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"

# Done
echo ""
echo -e "${GREEN}${BOLD}Uninstallation complete!${NC}"
echo ""
echo "Restart your terminal to complete the removal."
echo ""
echo "Environment variables to unset (if needed):"
echo "  unset SHELLPROXY_PROJECT"
echo "  unset SHELLPROXY_CONTAINER"
echo "  unset SHELLPROXY_DIR"

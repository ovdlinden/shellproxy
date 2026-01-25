#!/bin/zsh
# shellproxy zsh hook - directory change detection
# Add to ~/.zshrc: source ~/.shellproxy/hooks/hook.zsh

SHELLPROXY_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"

# Export for child processes
export SHELLPROXY_DIR

# Add bin directory to PATH (prepend for priority)
if [[ ":$PATH:" != *":$SHELLPROXY_DIR/bin:"* ]]; then
    export PATH="$SHELLPROXY_DIR/bin:$PATH"
fi

# Source config library for find_project_root
source "$SHELLPROXY_DIR/lib/config.sh"

# Hook function called on directory change
_shellproxy_hook() {
    local project_root
    project_root=$(find_project_root "$PWD")

    if [[ -n "$project_root" ]]; then
        export SHELLPROXY_PROJECT="$project_root"

        # Parse container for quick reference
        local taskfile="$project_root/Taskfile"
        if [[ -f "$taskfile" ]]; then
            local container
            container=$(grep -oE '^TASKFILE_EXEC_CONTAINER="[^"]+"' "$taskfile" 2>/dev/null | cut -d'"' -f2)
            if [[ -n "$container" ]]; then
                export SHELLPROXY_CONTAINER="$container"
            else
                unset SHELLPROXY_CONTAINER
            fi
        fi
    else
        unset SHELLPROXY_PROJECT
        unset SHELLPROXY_CONTAINER
    fi
}

# Register with zsh's chpwd hook
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _shellproxy_hook

# Run once on shell startup
_shellproxy_hook

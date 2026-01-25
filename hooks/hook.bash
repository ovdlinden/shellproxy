#!/bin/bash
# shellproxy bash hook - directory change detection
# Add to ~/.bashrc: source ~/.shellproxy/hooks/hook.bash

SHELLPROXY_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"

# Export for child processes
export SHELLPROXY_DIR

# Add bin directory to PATH (prepend for priority)
if [[ ":$PATH:" != *":$SHELLPROXY_DIR/bin:"* ]]; then
    export PATH="$SHELLPROXY_DIR/bin:$PATH"
fi

# Source config library for find_project_root
source "$SHELLPROXY_DIR/lib/config.sh"

# Track last directory to avoid redundant work
__shellproxy_last_dir=""

# Hook function called via PROMPT_COMMAND
_shellproxy_hook() {
    # Skip if directory hasn't changed
    [[ "$PWD" == "$__shellproxy_last_dir" ]] && return
    __shellproxy_last_dir="$PWD"

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

# Add to PROMPT_COMMAND (preserve existing)
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_shellproxy_hook"
elif [[ "$PROMPT_COMMAND" != *"_shellproxy_hook"* ]]; then
    PROMPT_COMMAND="_shellproxy_hook;$PROMPT_COMMAND"
fi

# Run once on shell startup
_shellproxy_hook

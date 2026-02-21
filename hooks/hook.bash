#!/bin/bash
# shellproxy bash hook - directory change detection
# Add to ~/.bashrc: source ~/.shellproxy/hooks/hook.bash

export SHELLPROXY_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"

# Add bin directory to PATH (prepend for priority)
if [[ ":$PATH:" != *":$SHELLPROXY_DIR/bin:"* ]]; then
    export PATH="$SHELLPROXY_DIR/bin:$PATH"
fi

# Track last directory to avoid redundant calls
__shellproxy_last_dir=""

_shellproxy_hook() {
    [[ "$PWD" == "$__shellproxy_last_dir" ]] && return
    __shellproxy_last_dir="$PWD"

    eval "$("$SHELLPROXY_DIR/shellproxy" __hook-update "$PWD")"
}

# Add to PROMPT_COMMAND (preserve existing)
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_shellproxy_hook"
elif [[ "$PROMPT_COMMAND" != *"_shellproxy_hook"* ]]; then
    PROMPT_COMMAND="_shellproxy_hook;$PROMPT_COMMAND"
fi

# Run once on shell startup
_shellproxy_hook

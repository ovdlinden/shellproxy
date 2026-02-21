#!/bin/zsh
# shellproxy zsh hook - directory change detection
# Add to ~/.zshrc: source ~/.shellproxy/hooks/hook.zsh

export SHELLPROXY_DIR="${SHELLPROXY_DIR:-$HOME/.shellproxy}"

# Add bin directory to PATH (prepend for priority)
if [[ ":$PATH:" != *":$SHELLPROXY_DIR/bin:"* ]]; then
    export PATH="$SHELLPROXY_DIR/bin:$PATH"
fi

_shellproxy_hook() {
    eval "$("$SHELLPROXY_DIR/shellproxy" __hook-update "$PWD")"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _shellproxy_hook

# Run once on shell startup
_shellproxy_hook

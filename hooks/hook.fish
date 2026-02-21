#!/usr/bin/env fish
# shellproxy fish hook - directory change detection
# Add to ~/.config/fish/config.fish: source ~/.shellproxy/hooks/hook.fish

set -gx SHELLPROXY_DIR (test -n "$SHELLPROXY_DIR" && echo $SHELLPROXY_DIR || echo "$HOME/.shellproxy")

# Add bin directory to PATH (prepend for priority)
if not contains "$SHELLPROXY_DIR/bin" $PATH
    set -gx PATH "$SHELLPROXY_DIR/bin" $PATH
end

# Hook function called on directory change
function _shellproxy_hook --on-variable PWD
    eval ("$SHELLPROXY_DIR/shellproxy" __hook-update $PWD)
end

# Run once on shell startup
_shellproxy_hook

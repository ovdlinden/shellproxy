#!/usr/bin/env fish
# shellproxy fish hook - directory change detection
# Add to ~/.config/fish/config.fish: source ~/.shellproxy/hooks/hook.fish

set -gx SHELLPROXY_DIR (test -n "$SHELLPROXY_DIR" && echo $SHELLPROXY_DIR || echo "$HOME/.shellproxy")

# Add bin directory to PATH (prepend for priority)
if not contains "$SHELLPROXY_DIR/bin" $PATH
    set -gx PATH "$SHELLPROXY_DIR/bin" $PATH
end

# Find project root (directory containing Taskfile)
function __shellproxy_find_project_root
    set -l dir $argv[1]

    while test "$dir" != "/"
        if test -f "$dir/Taskfile"
            echo $dir
            return 0
        end
        set dir (dirname $dir)
    end

    return 1
end

# Hook function called on directory change
function _shellproxy_hook --on-variable PWD
    set -l project_root (__shellproxy_find_project_root $PWD)

    if test -n "$project_root"
        set -gx SHELLPROXY_PROJECT $project_root

        # Parse container for quick reference
        set -l taskfile "$project_root/Taskfile"
        if test -f $taskfile
            set -l container (grep -oE '^TASKFILE_EXEC_CONTAINER="[^"]+"' $taskfile 2>/dev/null | cut -d'"' -f2)
            if test -n "$container"
                set -gx SHELLPROXY_CONTAINER $container
            else
                set -e SHELLPROXY_CONTAINER
            end
        end
    else
        set -e SHELLPROXY_PROJECT
        set -e SHELLPROXY_CONTAINER
    end
end

# Run once on shell startup
_shellproxy_hook

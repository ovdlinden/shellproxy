#!/bin/bash
# Configuration parser - reads Taskfile settings
# shellcheck disable=SC2155

# Parse container name from Taskfile
# Supports formats:
#   TASKFILE_EXEC_CONTAINER="value"
#   TASKFILE_EXEC_CONTAINER='value'
#   TASKFILE_EXEC_CONTAINER=value
#   TASKFILE_EXEC_CONTAINER="value" # comment
get_container() {
    local taskfile="$1"
    [[ ! -f "$taskfile" ]] && return 0

    # Use sed for robust parsing:
    # 1. Find line starting with TASKFILE_EXEC_CONTAINER=
    # 2. Remove the variable name and =
    # 3. Remove inline comments (# followed by anything)
    # 4. Remove surrounding quotes
    # 5. Trim whitespace
    grep -E '^TASKFILE_EXEC_CONTAINER=' "$taskfile" 2>/dev/null | head -1 | \
        sed -E "
            s/^TASKFILE_EXEC_CONTAINER=//
            s/[[:space:]]*#.*$//
            s/^[\"']//
            s/[\"']$//
            s/^[[:space:]]+//
            s/[[:space:]]+$//
        " || true
}

# Parse commands to route from Taskfile
# Returns space-separated list of commands
get_commands() {
    local taskfile="$1"
    [[ ! -f "$taskfile" ]] && return 0

    grep -E '^TASKFILE_EXEC_COMMANDS=' "$taskfile" 2>/dev/null | head -1 | \
        sed -E "
            s/^TASKFILE_EXEC_COMMANDS=//
            s/[[:space:]]*#.*$//
            s/^[\"']//
            s/[\"']$//
            s/^[[:space:]]+//
            s/[[:space:]]+$//
        " || true
}

# Check if command should be routed for this project
command_allowed() {
    local taskfile="$1"
    local cmd="$2"

    local commands
    commands=$(get_commands "$taskfile")

    # If no commands specified, don't route anything
    [[ -z "$commands" ]] && return 1

    # Check if command is in the list
    [[ " $commands " == *" $cmd "* ]]
}

# Parse dependencies from Taskfile
get_deps() {
    local taskfile="$1"
    grep '^# TASKFILE_DEPS:' "$taskfile" 2>/dev/null | cut -d: -f2 | xargs || true
}

# Find project root (directory containing Taskfile)
find_project_root() {
    local dir="$1"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/Taskfile" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    return 1
}

# Find compose file for project
find_compose_file() {
    local project_dir="$1"
    local taskfile="$2"

    # 1. Check project directory
    for f in "$project_dir/docker-compose.yml" "$project_dir/docker-compose.yaml" "$project_dir/compose.yml" "$project_dir/compose.yaml"; do
        [[ -f "$f" ]] && echo "$f" && return 0
    done

    # 2. Check TASKFILE_DEPS
    local git_root
    git_root=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)
    [[ -z "$git_root" ]] && return 1

    local deps
    deps=$(get_deps "$taskfile")
    for dep in $deps; do
        for f in "$git_root/$dep/docker-compose.yml" "$git_root/$dep/docker-compose.yaml" "$git_root/$dep/compose.yml" "$git_root/$dep/compose.yaml"; do
            [[ -f "$f" ]] && echo "$f" && return 0
        done
    done

    return 1
}

# Get working directory inside container
get_container_workdir() {
    local project_dir="$1"
    local current_dir="$2"
    local base_path="${3:-/var/www/html}"

    # Verify current_dir is under project_dir
    if [[ "$current_dir" != "$project_dir"* ]]; then
        echo "$base_path"  # Fallback to base if not under project
        return
    fi

    # Calculate relative path from project to current
    local relative="${current_dir#"$project_dir"}"
    echo "${base_path}${relative}"
}

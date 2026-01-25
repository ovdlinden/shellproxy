#!/bin/bash
# Configuration parser - reads Taskfile settings
# shellcheck disable=SC2155

# Parse container name from Taskfile
get_container() {
    local taskfile="$1"
    grep -oE '^TASKFILE_EXEC_CONTAINER="[^"]+"' "$taskfile" 2>/dev/null | cut -d'"' -f2 || true
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

    # Calculate relative path from project to current
    local relative="${current_dir#"$project_dir"}"
    echo "${base_path}${relative}"
}

#!/bin/bash
# Docker infrastructure - health checks and execution
# shellcheck disable=SC2155

# Check if container is running via Docker socket (fast path)
# Falls back to docker inspect if socket not accessible
container_running() {
    local container="$1"

    # Fast path: direct socket query (~5ms)
    if [[ -S /var/run/docker.sock ]]; then
        if curl -sf --unix-socket /var/run/docker.sock \
            "http://localhost/containers/${container}/json" 2>/dev/null | \
            grep -q '"Running":true'; then
            return 0
        fi
    fi

    # Fallback: docker inspect (~50ms)
    [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" == "true" ]]
}

# Get container ID by name
container_id() {
    local container="$1"
    docker inspect -f '{{.Id}}' "$container" 2>/dev/null | head -c 12
}

# Execute command in container using docker compose
container_exec() {
    local compose_file="$1"
    local env_file="$2"
    local container="$3"
    local workdir="$4"
    shift 4

    local env_args=()
    [[ -n "$env_file" && -f "$env_file" ]] && env_args=(--env-file "$env_file")

    local tty_flag="-T"
    [[ -t 0 && -t 1 ]] && tty_flag=""

    # shellcheck disable=SC2086
    docker compose -f "$compose_file" "${env_args[@]}" exec $tty_flag -w "$workdir" "$container" "$@"
}

# Execute command in container using docker exec directly (faster)
container_exec_direct() {
    local container="$1"
    local workdir="$2"
    shift 2

    local tty_flag=""
    [[ -t 0 && -t 1 ]] && tty_flag="-it"

    # shellcheck disable=SC2086
    docker exec $tty_flag -w "$workdir" "$container" "$@"
}

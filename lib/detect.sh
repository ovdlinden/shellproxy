#!/bin/bash
# Auto-detection of containers and commands from docker-compose.yml
# shellcheck disable=SC2155

# Find docker-compose.yml in current directory, common subdirectories, or parent
find_compose_in_cwd() {
    local dir="${1:-$PWD}"

    # Check current directory first
    for f in "$dir/docker-compose.yml" "$dir/docker-compose.yaml" "$dir/compose.yml" "$dir/compose.yaml"; do
        [[ -f "$f" ]] && echo "$f" && return 0
    done

    # Check common subdirectories
    local subdirs=(dev docker .docker infra infrastructure)
    for subdir in "${subdirs[@]}"; do
        for f in "$dir/$subdir/docker-compose.yml" "$dir/$subdir/docker-compose.yaml" "$dir/$subdir/compose.yml" "$dir/$subdir/compose.yaml"; do
            [[ -f "$f" ]] && echo "$f" && return 0
        done
    done

    return 1
}

# Detect service names from docker-compose.yml
# Returns space-separated list of service names
detect_services() {
    local compose_file="$1"
    [[ ! -f "$compose_file" ]] && return 1

    # Use docker compose to reliably parse services
    docker compose -f "$compose_file" config --services 2>/dev/null | xargs
}

# Detect available commands in a container
# Returns space-separated list of common commands found
detect_commands() {
    local container="$1"
    local found=""

    # Common commands to check (ordered by popularity)
    local candidates=(php composer artisan node npm npx yarn pnpm python pip go cargo ruby gem)

    for cmd in "${candidates[@]}"; do
        if docker exec "$container" which "$cmd" &>/dev/null 2>&1; then
            found="$found $cmd"
        fi
    done

    echo "$found" | xargs
}

# Check if a container (by service name) is running
# Uses docker compose ps to find the actual container
service_running() {
    local compose_file="$1"
    local service="$2"

    docker compose -f "$compose_file" ps --status running --format '{{.Service}}' 2>/dev/null | grep -qx "$service"
}

# Get the container ID for a service
get_container_id() {
    local compose_file="$1"
    local service="$2"

    docker compose -f "$compose_file" ps -q "$service" 2>/dev/null | head -1
}

# Start a service
start_service() {
    local compose_file="$1"
    local service="$2"

    docker compose -f "$compose_file" up -d "$service" 2>/dev/null
}

# Wait for a service to be running (with timeout)
# Returns 0 if running, 1 if timeout
wait_for_service() {
    local compose_file="$1"
    local service="$2"
    local timeout="${3:-30}"
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        if service_running "$compose_file" "$service"; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    return 1
}

# Get recent logs for a service
get_service_logs() {
    local compose_file="$1"
    local service="$2"
    local lines="${3:-20}"

    docker compose -f "$compose_file" logs --tail="$lines" "$service" 2>/dev/null
}

# Get container state via Docker API
# Returns: running, exited, paused, restarting, dead, created, or "not_found"
get_container_state() {
    local container="$1"

    if [[ ! -S /var/run/docker.sock ]]; then
        # Fallback to docker inspect
        docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not_found"
        return
    fi

    local response
    response=$(curl -sf --unix-socket /var/run/docker.sock \
        "http://localhost/v1.43/containers/${container}/json" 2>/dev/null)

    if [[ -z "$response" ]]; then
        echo "not_found"
        return
    fi

    # Extract Status from JSON using grep (avoids jq dependency)
    echo "$response" | grep -oE '"Status"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}

# Get container exit code (useful when container failed)
get_container_exit_code() {
    local container="$1"

    if [[ -S /var/run/docker.sock ]]; then
        local response
        response=$(curl -sf --unix-socket /var/run/docker.sock \
            "http://localhost/v1.43/containers/${container}/json" 2>/dev/null)

        if [[ -n "$response" ]]; then
            echo "$response" | grep -oE '"ExitCode"\s*:\s*[0-9]+' | head -1 | grep -oE '[0-9]+$'
            return
        fi
    fi

    # Fallback to docker inspect
    docker inspect -f '{{.State.ExitCode}}' "$container" 2>/dev/null
}

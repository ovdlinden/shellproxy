#!/usr/bin/env bats
# Tests for lib/config.sh

setup() {
    # Use the development directory for testing
    export SHELLPROXY_DIR="${BATS_TEST_DIRNAME}/.."
    source "$SHELLPROXY_DIR/lib/config.sh"

    FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

@test "get_container returns container name from Taskfile" {
    result=$(get_container "$FIXTURES/docker-project/Taskfile")
    [ "$result" = "app" ]
}

@test "get_container returns empty for local project" {
    result=$(get_container "$FIXTURES/local-project/Taskfile")
    [ -z "$result" ]
}

@test "get_deps returns dependencies from Taskfile" {
    result=$(get_deps "$FIXTURES/monorepo/packages/app/Taskfile")
    [ "$result" = "dev" ]
}

@test "find_project_root finds Taskfile in current directory" {
    result=$(find_project_root "$FIXTURES/docker-project")
    [ "$result" = "$FIXTURES/docker-project" ]
}

@test "find_project_root finds Taskfile in parent directory" {
    mkdir -p "$FIXTURES/docker-project/src/deep/nested"
    result=$(find_project_root "$FIXTURES/docker-project/src/deep/nested")
    [ "$result" = "$FIXTURES/docker-project" ]
    rm -rf "$FIXTURES/docker-project/src"
}

@test "find_project_root returns empty outside project" {
    result=$(find_project_root "/tmp" || true)
    [ -z "$result" ]
}

@test "find_compose_file finds docker-compose.yml in project" {
    result=$(find_compose_file "$FIXTURES/docker-project" "$FIXTURES/docker-project/Taskfile")
    [ "$result" = "$FIXTURES/docker-project/docker-compose.yml" ]
}

@test "get_container_workdir calculates correct path" {
    result=$(get_container_workdir "/home/user/project" "/home/user/project/src/app")
    [ "$result" = "/var/www/html/src/app" ]
}

@test "get_container_workdir handles project root" {
    result=$(get_container_workdir "/home/user/project" "/home/user/project")
    [ "$result" = "/var/www/html" ]
}

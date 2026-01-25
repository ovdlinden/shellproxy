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

@test "get_commands returns command list from Taskfile" {
    result=$(get_commands "$FIXTURES/docker-project/Taskfile")
    [ "$result" = "php node npm composer echo" ]
}

@test "get_commands returns empty for project without commands" {
    result=$(get_commands "$FIXTURES/local-project/Taskfile")
    [ -z "$result" ]
}

@test "command_allowed returns true for listed command" {
    command_allowed "$FIXTURES/docker-project/Taskfile" "php"
}

@test "command_allowed returns false for unlisted command" {
    ! command_allowed "$FIXTURES/docker-project/Taskfile" "python"
}

@test "command_allowed returns false when no commands specified" {
    ! command_allowed "$FIXTURES/local-project/Taskfile" "php"
}

@test "get_config_file prefers Taskfile.local over Taskfile" {
    mkdir -p "$FIXTURES/local-override"
    echo 'TASKFILE_EXEC_CONTAINER="app"' > "$FIXTURES/local-override/Taskfile"
    echo 'TASKFILE_EXEC_CONTAINER="local"' > "$FIXTURES/local-override/Taskfile.local"

    result=$(get_config_file "$FIXTURES/local-override")
    [ "$result" = "$FIXTURES/local-override/Taskfile.local" ]

    rm -rf "$FIXTURES/local-override"
}

@test "get_config_file falls back to Taskfile" {
    result=$(get_config_file "$FIXTURES/docker-project")
    [ "$result" = "$FIXTURES/docker-project/Taskfile" ]
}

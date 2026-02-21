#!/usr/bin/env bats
# Integration tests for command routing

setup() {
    export SHELLPROXY_DIR="${BATS_TEST_DIRNAME}/.."
    source "$SHELLPROXY_DIR/lib/config.sh"
    source "$SHELLPROXY_DIR/lib/docker.sh"

    FIXTURES="${BATS_TEST_DIRNAME}/fixtures"

    # Ensure dispatch is executable
    chmod +x "$SHELLPROXY_DIR/dispatch"
}

@test "hook sets SHELLPROXY_PROJECT in docker project" {
    cd "$FIXTURES/docker-project"

    # Simulate what the hook does
    project_root=$(find_project_root "$PWD")
    export SHELLPROXY_PROJECT="$project_root"

    [ "$SHELLPROXY_PROJECT" = "$FIXTURES/docker-project" ]
}

@test "hook sets SHELLPROXY_PROJECT in local project" {
    cd "$FIXTURES/local-project"

    project_root=$(find_project_root "$PWD")
    export SHELLPROXY_PROJECT="$project_root"

    [ "$SHELLPROXY_PROJECT" = "$FIXTURES/local-project" ]
}

@test "hook unsets SHELLPROXY_PROJECT outside any project" {
    project_root=$(find_project_root "/tmp" || true)

    [ -z "$project_root" ]
}

@test "dispatch passes through to local when SHELLPROXY_DISABLE=1" {
    export SHELLPROXY_PROJECT="$FIXTURES/docker-project"
    export SHELLPROXY_DISABLE=1

    # Create a test shim
    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    # Should use local echo
    result=$("$SHELLPROXY_DIR/bin/echo" "hello")
    [ "$result" = "hello" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
    unset SHELLPROXY_DISABLE
}

@test "dispatch passes through to local without SHELLPROXY_PROJECT" {
    unset SHELLPROXY_PROJECT

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    result=$("$SHELLPROXY_DIR/bin/echo" "test")
    [ "$result" = "test" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
}

@test "dispatch passes through to local for project without container" {
    export SHELLPROXY_PROJECT="$FIXTURES/local-project"

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    result=$("$SHELLPROXY_DIR/bin/echo" "local mode")
    [ "$result" = "local mode" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
}

# Error case tests

@test "get_container handles double-quoted value" {
    taskfile="$FIXTURES/docker-project/Taskfile"
    container=$(get_container "$taskfile")
    [ "$container" = "app" ]
}

@test "get_container handles single-quoted value" {
    local tmp_taskfile=$(mktemp)
    echo "TASKFILE_EXEC_CONTAINER='myapp'" > "$tmp_taskfile"

    container=$(get_container "$tmp_taskfile")
    [ "$container" = "myapp" ]

    rm -f "$tmp_taskfile"
}

@test "get_container handles unquoted value" {
    local tmp_taskfile=$(mktemp)
    echo "TASKFILE_EXEC_CONTAINER=myapp" > "$tmp_taskfile"

    container=$(get_container "$tmp_taskfile")
    [ "$container" = "myapp" ]

    rm -f "$tmp_taskfile"
}

@test "get_container handles inline comments" {
    local tmp_taskfile=$(mktemp)
    echo 'TASKFILE_EXEC_CONTAINER="myapp" # this is the main container' > "$tmp_taskfile"

    container=$(get_container "$tmp_taskfile")
    [ "$container" = "myapp" ]

    rm -f "$tmp_taskfile"
}

@test "get_container_workdir returns base path when current_dir not under project" {
    result=$(get_container_workdir "/home/user/project" "/tmp/other" "/var/www/html")
    [ "$result" = "/var/www/html" ]
}

@test "get_container_workdir calculates correct subpath" {
    result=$(get_container_workdir "/home/user/project" "/home/user/project/src/app" "/var/www/html")
    [ "$result" = "/var/www/html/src/app" ]
}

@test "dispatch passes through to local when Taskfile missing" {
    export SHELLPROXY_PROJECT="/tmp/nonexistent-project-$$"
    mkdir -p "$SHELLPROXY_PROJECT"

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    result=$("$SHELLPROXY_DIR/bin/echo" "no taskfile")
    [ "$result" = "no taskfile" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
    rm -rf "$SHELLPROXY_PROJECT"
}

@test "dispatch passes through to local when container not configured" {
    export SHELLPROXY_PROJECT="$FIXTURES/local-project"

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    # local-project has no TASKFILE_EXEC_CONTAINER
    result=$("$SHELLPROXY_DIR/bin/echo" "no container")
    [ "$result" = "no container" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
}

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

@test "dispatch falls back to local when SHELLPROXY_DISABLE=1" {
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

@test "dispatch falls back to local without SHELLPROXY_PROJECT" {
    unset SHELLPROXY_PROJECT

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    result=$("$SHELLPROXY_DIR/bin/echo" "test")
    [ "$result" = "test" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
}

@test "dispatch falls back to local for project without container" {
    export SHELLPROXY_PROJECT="$FIXTURES/local-project"

    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/echo"

    result=$("$SHELLPROXY_DIR/bin/echo" "local mode")
    [ "$result" = "local mode" ]

    rm -f "$SHELLPROXY_DIR/bin/echo"
}

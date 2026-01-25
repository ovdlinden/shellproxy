#!/usr/bin/env bats
# Tests for shellproxy CLI

setup() {
    export SHELLPROXY_DIR="${BATS_TEST_DIRNAME}/.."
    chmod +x "$SHELLPROXY_DIR/shellproxy"

    FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

@test "shellproxy version shows version" {
    run "$SHELLPROXY_DIR/shellproxy" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^shellproxy\ v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "shellproxy help shows usage" {
    run "$SHELLPROXY_DIR/shellproxy" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "shellproxy status outside project shows not in project" {
    unset SHELLPROXY_PROJECT

    run "$SHELLPROXY_DIR/shellproxy" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Not in a Taskfile project" ]]
}

@test "shellproxy status in local project shows local mode" {
    export SHELLPROXY_PROJECT="$FIXTURES/local-project"

    run "$SHELLPROXY_DIR/shellproxy" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "local" ]]
}

@test "shellproxy status in docker project shows docker mode" {
    export SHELLPROXY_PROJECT="$FIXTURES/docker-project"

    run "$SHELLPROXY_DIR/shellproxy" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "docker" ]]
    [[ "$output" =~ "app" ]]
}

@test "shellproxy info shows documentation" {
    run "$SHELLPROXY_DIR/shellproxy" info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "How it works:" ]]
    [[ "$output" =~ "Environment variables:" ]]
}

@test "shellproxy link creates shim" {
    # Clean up first
    rm -f "$SHELLPROXY_DIR/bin/testcmd"

    run "$SHELLPROXY_DIR/shellproxy" link testcmd
    [ "$status" -eq 0 ]
    [ -L "$SHELLPROXY_DIR/bin/testcmd" ]

    # Clean up
    rm -f "$SHELLPROXY_DIR/bin/testcmd"
}

@test "shellproxy link fails for existing shim" {
    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/testcmd"

    run "$SHELLPROXY_DIR/shellproxy" link testcmd
    [ "$status" -eq 1 ]
    [[ "$output" =~ "already exists" ]]

    rm -f "$SHELLPROXY_DIR/bin/testcmd"
}

@test "shellproxy unlink removes shim" {
    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/testcmd"

    run "$SHELLPROXY_DIR/shellproxy" unlink testcmd
    [ "$status" -eq 0 ]
    [ ! -e "$SHELLPROXY_DIR/bin/testcmd" ]
}

@test "shellproxy list shows shims" {
    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/testcmd1"
    ln -sf "$SHELLPROXY_DIR/dispatch" "$SHELLPROXY_DIR/bin/testcmd2"

    run "$SHELLPROXY_DIR/shellproxy" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testcmd1" ]]
    [[ "$output" =~ "testcmd2" ]]

    rm -f "$SHELLPROXY_DIR/bin/testcmd1" "$SHELLPROXY_DIR/bin/testcmd2"
}

@test "shellproxy which shows command location" {
    run "$SHELLPROXY_DIR/shellproxy" which bash
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Local:" ]]
}

@test "unknown command shows error" {
    run "$SHELLPROXY_DIR/shellproxy" unknowncommand
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}

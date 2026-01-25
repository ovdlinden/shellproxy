#!/usr/bin/env bats
# Tests for install.sh

setup() {
    export SHELLPROXY_DIR="${BATS_TEST_DIRNAME}/.."
    export TEST_INSTALL_DIR="/tmp/shellproxy-test-$$"

    # Use fake HOME to avoid polluting real shell config
    export REAL_HOME="$HOME"
    export HOME="/tmp/shellproxy-home-$$"
    mkdir -p "$HOME"

    chmod +x "$SHELLPROXY_DIR/install.sh"
    chmod +x "$SHELLPROXY_DIR/uninstall.sh"
}

teardown() {
    rm -rf "$TEST_INSTALL_DIR"
    rm -rf "$HOME"
    export HOME="$REAL_HOME"
}

@test "install.sh --help shows usage" {
    run "$SHELLPROXY_DIR/install.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "install.sh --local installs from local directory" {
    cd "$SHELLPROXY_DIR"
    run ./install.sh --local --dir "$TEST_INSTALL_DIR" <<< "y"

    # Check core files exist
    [ -f "$TEST_INSTALL_DIR/dispatch" ]
    [ -f "$TEST_INSTALL_DIR/shellproxy" ]
    [ -f "$TEST_INSTALL_DIR/lib/config.sh" ]
    [ -f "$TEST_INSTALL_DIR/lib/docker.sh" ]
    [ -d "$TEST_INSTALL_DIR/hooks" ]
    [ -d "$TEST_INSTALL_DIR/bin" ]
}

@test "install.sh creates default shims" {
    cd "$SHELLPROXY_DIR"
    ./install.sh --local --dir "$TEST_INSTALL_DIR" <<< "y" || true

    # Check default shims
    [ -L "$TEST_INSTALL_DIR/bin/php" ]
    [ -L "$TEST_INSTALL_DIR/bin/node" ]
    [ -L "$TEST_INSTALL_DIR/bin/npm" ]
    [ -L "$TEST_INSTALL_DIR/bin/composer" ]
}

@test "install.sh makes scripts executable" {
    cd "$SHELLPROXY_DIR"
    ./install.sh --local --dir "$TEST_INSTALL_DIR" <<< "y" || true

    [ -x "$TEST_INSTALL_DIR/dispatch" ]
    [ -x "$TEST_INSTALL_DIR/shellproxy" ]
    [ -x "$TEST_INSTALL_DIR/lib/config.sh" ]
}

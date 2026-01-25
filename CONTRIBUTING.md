# Contributing to shellproxy

Thanks for your interest in contributing!

## Quick Start

```bash
git clone https://github.com/ovdlinden/shellproxy.git
cd shellproxy

# Install git hooks
lefthook install

# Run tests
bats test/*.bats

# Run linting
shellcheck dispatch shellproxy lib/*.sh hooks/*.{zsh,bash}
```

## Development Setup

1. Clone the repo
2. Make scripts executable: `chmod +x dispatch shellproxy install.sh lib/*.sh`
3. Install lefthook: `brew install lefthook` or `npm install -g lefthook`
4. Install bats: `brew install bats-core` or `sudo apt install bats`

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning and changelog generation.

**Format:** `<type>(<scope>): <description>`

**Types:**
- `feat` - New features (triggers minor release)
- `fix` - Bug fixes (triggers patch release)
- `docs` - Documentation changes
- `test` - Adding or updating tests
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `chore` - Maintenance tasks
- `ci` - CI/CD changes

**Examples:**
```
feat(cli): add shellproxy info command
fix(dispatch): handle missing docker socket
docs: update installation instructions
test: add monorepo routing tests
```

**Breaking changes:** Add `BREAKING CHANGE:` in commit body for major releases.

## Testing

Tests use [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

```bash
# Run all tests
bats test/*.bats

# Run specific test file
bats test/routing.bats

# Verbose output
bats --verbose-run test/*.bats
```

### Writing tests

```bash
@test "description of what you're testing" {
    # Given: setup
    export SHELLPROXY_PROJECT="$FIXTURES/docker-project"

    # When: action
    run "$SHELLPROXY_DIR/shellproxy" status

    # Then: assertion
    [ "$status" -eq 0 ]
    [[ "$output" =~ "docker" ]]
}
```

## Code Style

- Use [ShellCheck](https://www.shellcheck.net/) for linting
- Quote variables: `"$var"` not `$var`
- Use `[[` over `[` for conditionals
- Prefer `local` for function variables
- Add comments for non-obvious logic

## Project Structure

```
shellproxy/
├── dispatch            # Command router (thin orchestrator)
├── shellproxy          # CLI command
├── lib/
│   ├── config.sh       # Taskfile parsing
│   └── docker.sh       # Container health checks & exec
├── hooks/
│   ├── hook.zsh
│   ├── hook.bash
│   └── hook.fish
├── test/
│   ├── fixtures/       # Test projects
│   ├── config.bats     # Config parsing tests
│   ├── routing.bats    # Routing integration tests
│   └── cli.bats        # CLI tests
├── install.sh
└── uninstall.sh
```

## Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Ensure tests pass: `bats test/*.bats`
5. Ensure linting passes: `shellcheck dispatch shellproxy lib/*.sh`
6. Push and create a PR against `main`

## Release Process

Releases are automated via semantic-release:

1. Merge PR to `main`
2. CI runs tests
3. semantic-release analyzes commits
4. Version is bumped based on commit types
5. CHANGELOG.md is updated
6. GitHub release is created

## Getting Help

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Include reproduction steps for bugs

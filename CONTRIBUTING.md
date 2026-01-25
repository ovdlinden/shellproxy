# Contributing to shellproxy

## Quick Start

```bash
git clone https://github.com/ovdlinden/shellproxy.git
cd shellproxy

# Install git hooks (optional, requires lefthook)
lefthook install

# Run tests
bats test/*.bats

# Run linting
shellcheck dispatch shellproxy lib/*.sh hooks/*.bash
```

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

## Code Style

- Use [ShellCheck](https://www.shellcheck.net/) for linting
- Quote variables: `"$var"` not `$var`
- Use `[[` over `[` for conditionals
- Prefer `local` for function variables
- Add comments for non-obvious logic

## Architecture

```
dispatch (thin orchestrator)
    │
    ├── lib/logging.sh  (logging only)
    ├── lib/config.sh   (Taskfile parsing only)
    └── lib/docker.sh   (Docker operations only)
```

Each module has a single responsibility. Keep it that way.

## Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Ensure tests pass: `bats test/*.bats`
5. Ensure linting passes: `shellcheck dispatch shellproxy lib/*.sh`
6. Push and create a PR against `main`

## Questions?

Open an issue on GitHub.

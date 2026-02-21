# Contributing

## Setup

```bash
git clone https://github.com/ovdlinden/shellproxy.git
cd shellproxy
bats test/*.bats        # Run tests
shellcheck dispatch shellproxy lib/*.sh  # Lint
```

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new command
fix: handle edge case
docs: update readme
test: add integration test
```

## Code Style

- Quote variables: `"$var"`
- Use `[[` not `[`
- Use `local` in functions
- Run `shellcheck` before committing

## Pull Requests

1. Fork & create branch
2. Make changes
3. Run `bats test/*.bats`
4. Run `shellcheck dispatch shellproxy lib/*.sh`
5. Submit PR

## Architecture

```
dispatch          → Routes commands (pass-through or docker exec)
shellproxy        → CLI (status, init, link, __hook-update, etc.)
lib/config.sh     → Parses Taskfile configuration
lib/docker.sh     → Docker operations
lib/detect.sh     → Auto-detection for shellproxy init
hooks/hook.{zsh,bash,fish} → Thin wrappers calling shellproxy __hook-update
hooks/prompt.zsh  → Zsh prompt indicator
```

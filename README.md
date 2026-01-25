# shellproxy

[![CI](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml/badge.svg)](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Transparent Docker command routing for Taskfile-based projects.

## What it does

shellproxy automatically routes commands like `php`, `node`, and `npm` to your Docker container when you're in a project that uses one. When the container isn't running, commands gracefully fall back to your local installation.

```bash
cd ~/projects/my-app     # Has Taskfile with TASKFILE_EXEC_CONTAINER="app"
php artisan migrate      # → Runs in Docker container
docker compose stop      # Stop the container
php artisan migrate      # → Runs locally (graceful fallback)
```

## Installation

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/ovdlinden/shellproxy/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/ovdlinden/shellproxy.git ~/.shellproxy
~/.shellproxy/install.sh --local
```

Then restart your terminal or run:

```bash
source ~/.shellproxy/hooks/hook.zsh   # or hook.bash / hook.fish
```

## How it works

1. **Shell hook** detects when you `cd` into a directory with a `Taskfile`
2. **Command shims** (symlinks in `~/.shellproxy/bin/`) intercept commands
3. **Router** checks if a container is configured and running
4. Commands route to the container, or fall back to local execution

```
You type: php artisan migrate
    ↓
Shell hook sets: SHELLPROXY_PROJECT=/path/to/project
    ↓
Shim (~/.shellproxy/bin/php) intercepts
    ↓
Router reads: TASKFILE_EXEC_CONTAINER="app"
    ↓
Container running? → docker exec app php artisan migrate
Container stopped? → /usr/bin/php artisan migrate (local)
```

## Configuration

shellproxy reads configuration from your project's `Taskfile`:

```bash
#!/bin/bash
# Taskfile

# Container to route commands to
TASKFILE_EXEC_CONTAINER="app"

# For monorepos: where to find docker-compose.yml
# TASKFILE_DEPS: dev
```

That's it. No additional configuration needed.

## Usage

### Check status

```bash
shellproxy status
# Project: /Users/you/project
# Mode:    docker
# Container: app ● running
```

### Manage shims

```bash
# List active shims
shellproxy list

# Add a new shim
shellproxy link composer

# Remove a shim
shellproxy unlink composer
```

### Debug

```bash
# See where a command would run
shellproxy which php

# Run with debug output
shellproxy debug php -v

# Temporarily disable routing
shellproxy off
php -v  # Uses local PHP
shellproxy on
```

## Default shims

The installer creates shims for common commands:

- `php`
- `node`
- `npm`
- `npx`
- `yarn`
- `pnpm`
- `composer`
- `artisan`

Add more with `shellproxy link <command>`.

## Environment variables

| Variable | Description |
|----------|-------------|
| `SHELLPROXY_PROJECT` | Current project directory (set by hook) |
| `SHELLPROXY_CONTAINER` | Current container name (set by hook) |
| `SHELLPROXY_DISABLE` | Set to `1` to disable routing |
| `SHELLPROXY_DEBUG` | Set to `1` for debug output |
| `SHELLPROXY_VERBOSE` | Set to `1` for verbose warnings |

## Supported shells

- **zsh** (default on macOS)
- **bash**
- **fish**

## Uninstall

```bash
~/.shellproxy/uninstall.sh
```

Or manually:

```bash
rm -rf ~/.shellproxy
# Remove the source line from your shell config
```

## Philosophy

> "Make the change easy, then make the easy change." — Martin Fowler

shellproxy follows the Unix philosophy:
- Do one thing well (route commands)
- Be composable (works with any docker-compose setup)
- Fail gracefully (local fallback when container is down)

## License

MIT

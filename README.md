# shellproxy

[![CI](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml/badge.svg)](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Transparently route commands to Docker containers. When a project has a running container, commands like `php`, `node`, `npm` execute inside it automatically.

```bash
cd ~/my-project          # Has Taskfile configured
php artisan migrate      # Runs in container
npm run build            # Runs in container
```

If the container isn't running, shellproxy tells you:

```
[shellproxy] Container 'app' is not running.
  Start it:  docker compose up -d app
  Run local: SHELLPROXY_DISABLE=1 php artisan migrate
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ovdlinden/shellproxy/main/install.sh | bash
```

## Quick start

Run `shellproxy init` in any project with a `docker-compose.yml`:

```bash
cd ~/my-project
shellproxy init
```

This interactively detects your services, probes for available commands, and generates a `Taskfile.local`.

## Manual setup

Add to your project's `Taskfile`:

```bash
TASKFILE_EXEC_CONTAINER="app"
TASKFILE_EXEC_COMMANDS="php composer artisan node npm"
```

| Variable | Description |
|----------|-------------|
| `TASKFILE_EXEC_CONTAINER` | Docker Compose service name |
| `TASKFILE_EXEC_COMMANDS` | Space-separated commands to route |

### Personal config with Taskfile.local

For personal configuration without modifying the shared `Taskfile`, create a `Taskfile.local`:

```bash
# Taskfile.local (gitignored)
TASKFILE_EXEC_CONTAINER="app"
TASKFILE_EXEC_COMMANDS="php composer artisan"
```

shellproxy reads `Taskfile.local` first if it exists, otherwise falls back to `Taskfile`. This lets you use shellproxy before your team adopts it.

## Commands

```bash
shellproxy init            # Interactive project setup
shellproxy status          # Current project & container
shellproxy list            # Active shims
shellproxy link <cmd>      # Add shim
shellproxy unlink <cmd>    # Remove shim
shellproxy which <cmd>     # Show where a command would run
shellproxy on / off        # Enable/disable routing for this shell
```

## Prompt indicator (zsh)

Source the prompt hook to see a whale (🐳) when the command you're typing would route to Docker:

```bash
# ~/.zshrc (after the main hook)
source ~/.shellproxy/hooks/prompt.zsh
```

The indicator updates as you type — it appears when the first command in your input matches a routed command.

## Environment variables

| Variable | Description |
|----------|-------------|
| `SHELLPROXY_DISABLE=1` | Skip routing, run commands locally |
| `SHELLPROXY_DEBUG=1` | Debug output |
| `SHELLPROXY_PROJECT` | Current project directory (set by hook) |
| `SHELLPROXY_CONTAINER` | Current container name (set by hook) |
| `SHELLPROXY_MODE` | `docker` or `local` (set by hook) |
| `SHELLPROXY_COMMANDS` | Routed commands for current project (set by hook) |

## Uninstall

```bash
~/.shellproxy/uninstall.sh
```

## License

MIT

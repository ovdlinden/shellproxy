# shellproxy

[![CI](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml/badge.svg)](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Route commands to Docker containers automatically. Falls back to local when container is down.

```bash
cd ~/my-project          # Has Taskfile configured
php artisan migrate      # Runs in container
docker compose stop
php artisan migrate      # Falls back to local
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ovdlinden/shellproxy/main/install.sh | bash
```

## Setup

Add to your project's `Taskfile`:

```bash
TASKFILE_EXEC_CONTAINER="app"
TASKFILE_EXEC_COMMANDS="php composer artisan"
```

| Variable | Description |
|----------|-------------|
| `TASKFILE_EXEC_CONTAINER` | Docker container name |
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
shellproxy status          # Current project & container
shellproxy list            # Active shims
shellproxy link <cmd>      # Add shim
shellproxy unlink <cmd>    # Remove shim
```

## Options

```bash
SHELLPROXY_DISABLE=1 php -v   # Skip routing
SHELLPROXY_VERBOSE=1 php -v   # Show fallback messages
SHELLPROXY_DEBUG=1 php -v     # Debug output
```

## Uninstall

```bash
~/.shellproxy/uninstall.sh
```

## License

MIT

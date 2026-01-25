# shellproxy

[![CI](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml/badge.svg)](https://github.com/ovdlinden/shellproxy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Transparent Docker command routing for Taskfile-based projects.

```bash
cd ~/projects/my-app     # Has Taskfile with TASKFILE_EXEC_CONTAINER="app"
php artisan migrate      # → Runs in Docker container
docker compose stop
php artisan migrate      # → Falls back to local PHP
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ovdlinden/shellproxy/main/install.sh | bash
```

## Configure

Add to your project's `Taskfile`:

```bash
TASKFILE_EXEC_CONTAINER="app"
```

That's it.

## Usage

```bash
shellproxy status        # Show current project/container
shellproxy list          # List active shims
shellproxy link python   # Add a shim
shellproxy unlink python # Remove a shim
```

### Default shims

`php` `node` `npm` `npx` `yarn` `pnpm` `composer` `artisan`

## Environment variables

| Variable | Description |
|----------|-------------|
| `SHELLPROXY_DISABLE=1` | Disable routing |
| `SHELLPROXY_VERBOSE=1` | Show fallback warnings |
| `SHELLPROXY_DEBUG=1` | Debug output |
| `SHELLPROXY_LOG=1` | Log to `~/.shellproxy/shellproxy.log` |

## Uninstall

```bash
~/.shellproxy/uninstall.sh
```

## License

MIT

#!/usr/bin/env bash
set -euo pipefail

# Wire the mise-installed `docker-compose` v2 binary into Docker's CLI plugin
# directory so `docker compose ...` works as a subcommand.
#
# mise installs the binary as `docker-cli-plugin-docker-compose` under the
# tool's versioned install path. Docker CLI looks for plugins at
# ~/.docker/cli-plugins/docker-compose. We symlink one to the other.
#
# Safe to re-run after `mise upgrade` — the symlink refreshes to the active
# version.

PLUGIN_DIR="$HOME/.docker/cli-plugins"
TARGET="$PLUGIN_DIR/docker-compose"

if ! command -v mise >/dev/null 2>&1; then
  echo "mise not installed; skipping docker compose plugin link"
  exit 0
fi

COMPOSE_INSTALL="$(mise where docker-compose 2>/dev/null || true)"
if [[ -z "$COMPOSE_INSTALL" ]]; then
  echo "docker-compose is not installed via mise; skipping"
  exit 0
fi

SOURCE="$COMPOSE_INSTALL/docker-cli-plugin-docker-compose"
if [[ ! -x "$SOURCE" ]]; then
  echo "Expected binary not found at $SOURCE; skipping"
  exit 0
fi

mkdir -p "$PLUGIN_DIR"
ln -sf "$SOURCE" "$TARGET"
echo "Linked $TARGET → $SOURCE"

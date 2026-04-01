#!/usr/bin/env bash
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="$HOME/.local/bin:$HOME/.krew/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is not installed or not on PATH"
  exit 1
fi

prepend_mise_bin_paths() {
  local bin_path
  while IFS= read -r bin_path; do
    [[ -n "$bin_path" ]] && export PATH="$bin_path:$PATH"
  done < <(mise bin-paths)
}

prepend_mise_bin_paths

echo "==> Updating mise"
mise self-update

echo "==> Upgrading tools from $SETUP_DIR/mise.toml"
mise upgrade --yes

echo "==> Pruning unused mise installs"
mise prune --yes

prepend_mise_bin_paths

if command -v kubectl >/dev/null 2>&1 && command -v kubectl-krew >/dev/null 2>&1; then
  echo "==> Updating kubectl krew index"
  kubectl krew update

  echo "==> Upgrading kubectl krew plugins"
  kubectl krew upgrade
fi

echo "==> Update complete"

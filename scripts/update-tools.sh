#!/usr/bin/env bash
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1-}" == "--auto" ]]; then
  shift
fi

LOCK_DIR="${TMPDIR:-/tmp}/macbook-setup-update-tools.lock"

export PATH="$HOME/.local/bin:$HOME/.krew/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

run_started_at="$(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "[$run_started_at] update-tools.sh starting"
echo "[$run_started_at] update-tools.sh starting" >&2

cleanup() {
  [[ -d "$LOCK_DIR" ]] && rmdir "$LOCK_DIR"
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Another update-tools.sh run is already in progress; exiting."
  exit 0
fi
trap cleanup EXIT

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is not installed or not on PATH"
  exit 1
fi

log_step() {
  echo "==> $1"
}

run_with_prefix() {
  local prefix="$1"
  shift
  "$@" 2>&1 | sed "s/^/[$prefix] /"
  return "${PIPESTATUS[0]}"
}

sync_setup_repo() {
  local current_branch

  if [[ ! -d "$SETUP_DIR/.git" ]]; then
    echo "Setup repo is not a git checkout: $SETUP_DIR"
    exit 1
  fi

  current_branch="$(git -C "$SETUP_DIR" branch --show-current)"
  if [[ "$current_branch" != "main" ]]; then
    echo "Setup repo is on '$current_branch'; refusing to apply anything outside main"
    exit 1
  fi

  if [[ -n "$(git -C "$SETUP_DIR" status --porcelain)" ]]; then
    echo "Setup repo has local changes; refusing to pull or apply them"
    exit 1
  fi

  log_step "Fetching origin/main"
  run_with_prefix "git" git -C "$SETUP_DIR" fetch --prune origin main

  if ! git -C "$SETUP_DIR" merge-base --is-ancestor HEAD origin/main; then
    echo "Setup repo has local commits that are not in origin/main; refusing to apply them"
    exit 1
  fi

  log_step "Fast-forwarding setup repo to origin/main"
  run_with_prefix "git" git -C "$SETUP_DIR" merge --ff-only origin/main
}

prepend_mise_bin_paths() {
  local bin_path
  while IFS= read -r bin_path; do
    [[ -n "$bin_path" ]] && export PATH="$bin_path:$PATH"
  done < <(mise -C "$SETUP_DIR" bin-paths)
}

sync_setup_repo
prepend_mise_bin_paths

log_step "Installing pinned tools from $SETUP_DIR/mise.toml"
run_with_prefix "mise" mise -C "$SETUP_DIR" install --yes

log_step "Pruning unused mise installs"
run_with_prefix "mise" mise -C "$SETUP_DIR" prune --yes

log_step "Repairing Go toolchain"
run_with_prefix "go-tools" "$SETUP_DIR/scripts/repair-go-tools.sh"

log_step "Repairing codex binary"
run_with_prefix "codex" "$SETUP_DIR/scripts/repair-codex-binary.sh"

prepend_mise_bin_paths

log_step "Refreshing docker compose plugin link"
run_with_prefix "docker-compose" "$SETUP_DIR/scripts/link-docker-cli-plugins.sh"

log_step "Pinned tool apply complete"

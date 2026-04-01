#!/usr/bin/env bash
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="$HOME/.local/bin:$HOME/.krew/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

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

prepend_mise_bin_paths() {
  local bin_path
  while IFS= read -r bin_path; do
    [[ -n "$bin_path" ]] && export PATH="$bin_path:$PATH"
  done < <(mise bin-paths)
}

update_git_repo() {
  local repo_path="$1"
  local label="$2"
  if [[ -d "$repo_path/.git" ]]; then
    log_step "Updating $label"
    run_with_prefix "$label" git -C "$repo_path" pull --ff-only
  fi
}

prepend_mise_bin_paths

log_step "Updating mise"
run_with_prefix "mise" mise self-update

log_step "Upgrading tools from $SETUP_DIR/mise.toml"
run_with_prefix "mise" mise upgrade --yes

log_step "Pruning unused mise installs"
run_with_prefix "mise" mise prune --yes

prepend_mise_bin_paths

if command -v brew >/dev/null 2>&1; then
  log_step "Updating Homebrew metadata"
  run_with_prefix "brew" brew update

  log_step "Upgrading Homebrew packages"
  run_with_prefix "brew" brew upgrade
fi

if command -v kubectl >/dev/null 2>&1 && command -v kubectl-krew >/dev/null 2>&1; then
  log_step "Updating kubectl krew index"
  run_with_prefix "krew" kubectl krew update

  log_step "Upgrading kubectl krew plugins"
  run_with_prefix "krew" kubectl krew upgrade
fi

update_git_repo "$HOME/.antigen/bundles/romkatv/powerlevel10k" "powerlevel10k"
update_git_repo "$HOME/.antigen/bundles/robbyrussell/oh-my-zsh" "oh-my-zsh"
update_git_repo "$HOME/.antigen/bundles/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
update_git_repo "$HOME/.antigen/bundles/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"

log_step "Update complete"

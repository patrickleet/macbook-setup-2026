#!/usr/bin/env bash
set -euo pipefail

WEBWRIGHT_REPO_URL="${WEBWRIGHT_REPO_URL:-https://github.com/microsoft/Webwright.git}"
WEBWRIGHT_DIR="${WEBWRIGHT_DIR:-$HOME/dev/Webwright}"
CODEX_WEBWRIGHT_MARKETPLACE_DIR="${CODEX_WEBWRIGHT_MARKETPLACE_DIR:-$HOME/.local/share/webwright-codex-marketplace}"

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

log_step() {
  echo "==> $1"
}

done_msg() {
  echo "  OK $1"
}

prepend_mise_bin_paths() {
  local bin_path
  if ! command -v mise >/dev/null 2>&1; then
    return
  fi

  while IFS= read -r bin_path; do
    [[ -n "$bin_path" ]] && export PATH="$bin_path:$PATH"
  done < <(mise bin-paths 2>/dev/null || true)
}

ensure_webwright_checkout() {
  local parent_dir
  parent_dir="$(dirname "$WEBWRIGHT_DIR")"
  mkdir -p "$parent_dir"

  if [[ -d "$WEBWRIGHT_DIR/.git" ]]; then
    git -C "$WEBWRIGHT_DIR" pull --ff-only
    done_msg "Updated $WEBWRIGHT_DIR"
  elif [[ -e "$WEBWRIGHT_DIR" ]]; then
    echo "$WEBWRIGHT_DIR exists but is not a git checkout"
    exit 1
  else
    git clone "$WEBWRIGHT_REPO_URL" "$WEBWRIGHT_DIR"
    done_msg "Cloned to $WEBWRIGHT_DIR"
  fi
}

python_bin() {
  if command -v python >/dev/null 2>&1; then
    command -v python
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  else
    echo "python not found on PATH"
    exit 1
  fi
}

install_python_runtime() {
  local python_cmd
  python_cmd="$(python_bin)"

  "$python_cmd" -m pip install -e "$WEBWRIGHT_DIR"
  "$python_cmd" -m playwright install chromium firefox
  done_msg "Installed Webwright Python package and Playwright browsers"
}

codex_marketplace_configured() {
  local current_root
  current_root="$(codex_marketplace_root)"
  [[ "$current_root" == "$CODEX_WEBWRIGHT_MARKETPLACE_DIR" ]]
}

codex_plugin_installed() {
  codex plugin list 2>/dev/null | awk '$1 == "webwright@webwright" && $2 == "installed" {found = 1} END {exit !found}'
}

codex_marketplace_root() {
  codex plugin marketplace list 2>/dev/null | awk '$1 == "webwright" {print $2; exit}'
}

prepare_codex_marketplace() {
  local marketplace_json
  marketplace_json="$CODEX_WEBWRIGHT_MARKETPLACE_DIR/.agents/plugins/marketplace.json"

  mkdir -p "$CODEX_WEBWRIGHT_MARKETPLACE_DIR/.agents/plugins" "$CODEX_WEBWRIGHT_MARKETPLACE_DIR/plugins"
  ln -sfn "$WEBWRIGHT_DIR" "$CODEX_WEBWRIGHT_MARKETPLACE_DIR/plugins/webwright"

  cat > "$marketplace_json" <<'JSON'
{
  "name": "webwright",
  "interface": {
    "displayName": "Webwright"
  },
  "plugins": [
    {
      "name": "webwright",
      "source": {
        "source": "local",
        "path": "./plugins/webwright"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
JSON
}

install_codex_plugin() {
  if ! command -v codex >/dev/null 2>&1; then
    done_msg "Codex not found; skipped Codex Webwright plugin"
    return
  fi

  prepare_codex_marketplace

  if codex_marketplace_configured; then
    done_msg "Codex Webwright marketplace already configured"
  else
    if [[ -n "$(codex_marketplace_root)" ]]; then
      codex plugin marketplace remove webwright
    fi
    codex plugin marketplace add "$CODEX_WEBWRIGHT_MARKETPLACE_DIR"
    done_msg "Added Codex Webwright marketplace"
  fi

  if codex_plugin_installed; then
    done_msg "Codex Webwright plugin already installed"
  else
    codex plugin add webwright@webwright
    done_msg "Installed Codex Webwright plugin"
  fi
}

claude_marketplace_configured() {
  claude plugin marketplace list 2>/dev/null | grep -q "webwright"
}

claude_plugin_installed() {
  claude plugin list 2>/dev/null | grep -q "webwright@webwright"
}

install_claude_plugin() {
  if ! command -v claude >/dev/null 2>&1; then
    done_msg "Claude Code not found; skipped Claude Webwright plugin"
    return
  fi

  if claude_marketplace_configured; then
    done_msg "Claude Webwright marketplace already configured"
  else
    claude plugin marketplace add "$WEBWRIGHT_DIR"
    done_msg "Added Claude Webwright marketplace"
  fi

  if claude_plugin_installed; then
    done_msg "Claude Webwright plugin already installed"
  else
    claude plugin install webwright@webwright
    done_msg "Installed Claude Webwright plugin"
  fi
}

prepend_mise_bin_paths

log_step "Webwright checkout"
ensure_webwright_checkout

log_step "Webwright Python runtime"
install_python_runtime

log_step "Webwright Codex plugin"
install_codex_plugin

log_step "Webwright Claude Code plugin"
install_claude_plugin

#!/usr/bin/env bash
set -uo pipefail

# @openai/codex ships its real binary as a platform-specific optional dependency
# declared with npm alias syntax, e.g.
#   "@openai/codex-darwin-arm64": "npm:@openai/codex@<version>-darwin-arm64"
# npm intermittently skips alias-style optionalDependencies, leaving the codex
# wrapper to throw "Missing optional dependency ...". This installs the matching
# platform binary in place when it's absent so codex stays runnable.

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is not installed; skipping codex binary repair"
  exit 0
fi

INSTALL_DIR="$(mise where "npm:@openai/codex" 2>/dev/null || true)"
if [[ -z "$INSTALL_DIR" || ! -d "$INSTALL_DIR" ]]; then
  echo "codex is not installed via mise; skipping codex binary repair"
  exit 0
fi

PKG_DIR="$INSTALL_DIR/lib/node_modules/@openai/codex"
if [[ ! -f "$PKG_DIR/package.json" ]]; then
  echo "codex package.json not found at $PKG_DIR; skipping codex binary repair" >&2
  exit 0
fi

case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux)  os="linux" ;;
  *) echo "unsupported OS for codex binary repair: $(uname -s); skipping" >&2; exit 0 ;;
esac

case "$(uname -m)" in
  arm64|aarch64) arch="arm64" ;;
  x86_64|amd64)  arch="x64" ;;
  *) echo "unsupported arch for codex binary repair: $(uname -m); skipping" >&2; exit 0 ;;
esac

bin_pkg="@openai/codex-${os}-${arch}"

if [[ -d "$PKG_DIR/node_modules/$bin_pkg" ]]; then
  exit 0
fi

VERSION="$(mise exec -- node -p "require('$PKG_DIR/package.json').version" 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  echo "unable to read codex version from $PKG_DIR/package.json; skipping" >&2
  exit 0
fi

echo "Installing missing codex platform binary: $bin_pkg ($VERSION)"
if ! (cd "$PKG_DIR" && mise exec -- npm install "${bin_pkg}@npm:@openai/codex@${VERSION}-${os}-${arch}" --no-save >/dev/null 2>&1); then
  echo "failed to install codex platform binary $bin_pkg; run 'codex --version' to inspect" >&2
  exit 0
fi

if [[ ! -d "$PKG_DIR/node_modules/$bin_pkg" ]]; then
  echo "codex platform binary $bin_pkg still missing after install attempt" >&2
  exit 0
fi

echo "codex platform binary repaired: $bin_pkg"

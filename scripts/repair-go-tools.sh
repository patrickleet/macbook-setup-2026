#!/usr/bin/env bash
set -euo pipefail

if command -v mise >/dev/null 2>&1; then
  GO=(mise exec -- go)
elif command -v go >/dev/null 2>&1; then
  GO=(go)
else
  echo "go is not installed; skipping Go tool repair"
  exit 0
fi

GOROOT="$(${GO[@]} env GOROOT)"
GOTOOLDIR="$(${GO[@]} env GOTOOLDIR)"

if [[ -z "$GOROOT" || -z "$GOTOOLDIR" ]]; then
  echo "unable to resolve Go toolchain paths" >&2
  exit 1
fi

# Go's coverage path shells out to go tool covdata. Some Go archives include
# the source tree but omit the built internal tool binary, so build it in place.
for tool in covdata; do
  if [[ -x "$GOTOOLDIR/$tool" ]]; then
    continue
  fi

  src="$GOROOT/src/cmd/$tool"
  if [[ ! -d "$src" ]]; then
    echo "missing Go tool $tool and source directory not found: $src" >&2
    exit 1
  fi

  echo "Installing missing Go internal tool: $tool"
  (cd "$src" && "${GO[@]}" install .)

  if [[ ! -x "$GOTOOLDIR/$tool" ]]; then
    echo "failed to install Go tool $tool into $GOTOOLDIR" >&2
    exit 1
  fi
done

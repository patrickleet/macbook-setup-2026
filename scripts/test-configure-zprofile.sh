#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/macbook-setup-zprofile-test.XXXXXX")"
fixture_zdotdir="$fixture_root/zdot"

cleanup() {
  rm -rf "$fixture_root"
}
trap cleanup EXIT

mkdir -p "$fixture_zdotdir"
cat > "$fixture_zdotdir/.zprofile" <<'EOF'
# >>> dory cli >>>
DORY_CLI_BIN="$HOME/.dory/bin"
export PATH="$DORY_CLI_BIN:$PATH"
# <<< dory cli <<<
EOF

ZDOTDIR="$fixture_zdotdir" "$script_dir/configure-zprofile.sh"
first_hash="$(shasum -a 256 "$fixture_zdotdir/.zprofile" | awk '{print $1}')"
ZDOTDIR="$fixture_zdotdir" "$script_dir/configure-zprofile.sh"
second_hash="$(shasum -a 256 "$fixture_zdotdir/.zprofile" | awk '{print $1}')"

[[ "$first_hash" == "$second_hash" ]]
[[ "$(grep -Fxc '# >>> macbook-setup mise shims >>>' "$fixture_zdotdir/.zprofile")" -eq 1 ]]
[[ "$(grep -Fxc '# <<< macbook-setup mise shims <<<' "$fixture_zdotdir/.zprofile")" -eq 1 ]]
grep -Fq '# >>> dory cli >>>' "$fixture_zdotdir/.zprofile"
grep -Fq '# <<< dory cli <<<' "$fixture_zdotdir/.zprofile"

malformed_zdotdir="$fixture_root/malformed-zdot"
malformed_profile="$malformed_zdotdir/.zprofile"
mkdir -p "$malformed_zdotdir"
cat > "$malformed_profile" <<'EOF'
# <<< macbook-setup mise shims <<<
# >>> macbook-setup mise shims >>>
EOF
malformed_hash="$(shasum -a 256 "$malformed_profile" | awk '{print $1}')"
if ZDOTDIR="$malformed_zdotdir" "$script_dir/configure-zprofile.sh" >/dev/null 2>&1; then
  echo "malformed profile unexpectedly succeeded" >&2
  exit 1
fi
[[ "$malformed_hash" == "$(shasum -a 256 "$malformed_profile" | awk '{print $1}')" ]]

if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  echo "mise must be installed at ~/.local/bin/mise for login-shell validation" >&2
  exit 1
fi

pnpm_path="$(ZDOTDIR="$fixture_zdotdir" zsh -lc 'command -v pnpm')"
pnpm_version="$(ZDOTDIR="$fixture_zdotdir" zsh -lc 'pnpm --version')"

[[ "$pnpm_path" == "$HOME/.local/share/mise/shims/pnpm" ]]
[[ -n "$pnpm_version" ]]

echo "zprofile configuration is idempotent, rejects malformed blocks, and preserves Dory"
echo "login-shell pnpm: $pnpm_path ($pnpm_version)"

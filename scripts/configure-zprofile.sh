#!/usr/bin/env bash
set -euo pipefail

# Login and non-interactive zsh sessions do not read ~/.zshrc. Keep this
# narrowly owned block in .zprofile so mise tools are still available to Git
# hooks, IDEs, and automation without taking ownership of Dory's profile block
# or any other user configuration.
profile_path="${ZDOTDIR:-$HOME}/.zprofile"
profile_dir="$(dirname "$profile_path")"
block_start="# >>> macbook-setup mise shims >>>"
block_end="# <<< macbook-setup mise shims <<<"

print_managed_block() {
  cat <<'EOF'
# >>> macbook-setup mise shims >>>
# Login/non-interactive shells need shims; interactive shells use the full
# `mise activate zsh` integration from ~/.zshrc.
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi
# <<< macbook-setup mise shims <<<
EOF
}

mkdir -p "$profile_dir"
touch "$profile_path"

block_state=0
block_count=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "$block_start" ]]; then
    if [[ "$block_state" -ne 0 || "$block_count" -ne 0 ]]; then
      block_state=2
      break
    fi
    block_state=1
    block_count=1
  elif [[ "$line" == "$block_end" ]]; then
    if [[ "$block_state" -ne 1 ]]; then
      block_state=2
      break
    fi
    block_state=0
  fi
done < "$profile_path"

if [[ "$block_state" -ne 0 ]]; then
  echo "Refusing to modify $profile_path: malformed macbook-setup mise block" >&2
  exit 1
fi

if [[ "$block_count" -eq 0 ]]; then
  if [[ -s "$profile_path" ]]; then
    printf '\n' >> "$profile_path"
  fi
  print_managed_block >> "$profile_path"
else
  temp_file="$(mktemp "${TMPDIR:-/tmp}/macbook-setup-zprofile.XXXXXX")"
  cleanup() {
    rm -f "$temp_file"
  }
  trap cleanup EXIT

  in_managed_block=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$block_start" ]]; then
      print_managed_block
      in_managed_block=1
    elif [[ "$in_managed_block" -eq 1 && "$line" == "$block_end" ]]; then
      in_managed_block=0
    elif [[ "$in_managed_block" -eq 0 ]]; then
      printf '%s\n' "$line"
    fi
  done < "$profile_path" > "$temp_file"

  # Redirect through the profile path so an existing symlink remains intact.
  cat "$temp_file" > "$profile_path"
fi

echo "Configured mise shims in $profile_path"

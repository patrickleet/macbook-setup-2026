# macbook-setup

Bootstrap a new MacBook with one script.

This repo installs the base developer setup I actually use:

- Xcode Command Line Tools
- Git config + SSH key
- Homebrew for GUI apps and a small number of CLI formulas
- `mise` for runtimes and CLI tools
- `krew` plus the `ctx` and `ns` `kubectl` plugins
- Claude Code
- Zsh plugins + repo-managed `.zshrc`

## Quick start

Run this on a fresh machine:

```bash
curl -fsSL https://raw.githubusercontent.com/patrickleet/macbook-setup/main/init.sh | bash
```

The script will:

1. Install Xcode Command Line Tools
2. Prompt for your Git name and email
3. Install Homebrew if needed
4. Create an SSH key and copy the public key to your clipboard
5. Clone this repo into `~/dev/macbook-setup`
6. Install `mise` and all tools from [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml)
7. Install `krew` and the `ctx` / `ns` `kubectl` plugins
8. Install GUI apps from [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile)
9. Install Zsh plugins and symlink [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc) to `~/.zshrc`

## What gets installed

### CLI tools

Most CLI tools and runtimes are managed through [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml).

Current setup includes:

- Runtimes: Node.js, Python, Rust
- Direct binary tools via `http:`, including Upbound `up` and Crossplane CLI
- Infra tools: `kubectl`, `helm`, `kubefwd`, `lima`, `colima`, `docker-cli`, `docker-compose`, `aws-cli`, `gh`, `jq`, `yq`
- `krew` plus the `ctx` and `ns` `kubectl` plugins, installed by [`init.sh`](/Users/patrickleet/dev/macbook-setup/init.sh)
- Python CLI tools via `pipx`, including `gimme-aws-creds` and `git-filter-repo`
- GitHub release binaries via `github:`, including `glow` and `gitkb`
- Global npm packages including `typescript` and `@openai/codex`
- Standalone CLIs installed by [`init.sh`](/Users/patrickleet/dev/macbook-setup/init.sh), including Claude Code

Homebrew also manages a small number of CLI formulas that are not available through the current `mise` setup:

- `watch`

### Apps

GUI apps and a few Homebrew-managed CLI exceptions are managed through [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile).

Current casks include:

- Arc
- Zed
- Ghostty
- Zoom
- Slack
- Discord
- Spotify
- Superwhisper
- Adobe Creative Cloud
- CrossOver
- ProtonVPN

Current formula exceptions include:

- `watch`

### Shell setup

The repo-managed [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc) sets up:

- Powerlevel10k
- `oh-my-zsh` git plugin
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `mise` shell activation
- AWS CLI tab completion for `aws`
- `~/.krew/bin` on `PATH`
- A few personal aliases and helper functions

## Updating the setup

Edit the source files in this repo, then re-run the relevant install step:

```bash
mise install
./scripts/update-tools.sh
brew bundle --file=~/dev/macbook-setup/Brewfile
ln -sf ~/dev/macbook-setup/.zshrc ~/.zshrc
```

`init.sh` can also be re-run safely on an existing machine. It checks for existing installs and updates the cloned repo when possible.

`mise install` installs missing tools from [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml), but it does not continuously re-resolve `version = "latest"` entries after the first install. To refresh those to newer upstream releases, run:

```bash
~/dev/macbook-setup/scripts/update-tools.sh
```

That script runs `mise self-update`, `mise upgrade --yes`, `mise prune --yes`, `brew update`, `brew bundle --file=~/dev/macbook-setup/Brewfile`, `brew upgrade`, and also refreshes `krew` plugins plus the directly cloned Zsh plugin repos under `~/.antigen/bundles`.

To enable background updates on macOS login and every 24 hours, install the included LaunchAgent:

```bash
~/dev/macbook-setup/scripts/install-auto-updates.sh
```

It writes `~/Library/LaunchAgents/com.patrickleet.macbook-setup.mise-updates.plist` and logs to `~/Library/Logs/macbook-setup-mise-updates*.log`.

To remove that LaunchAgent later:

```bash
~/dev/macbook-setup/scripts/uninstall-auto-updates.sh
```

## Files

- [`init.sh`](/Users/patrickleet/dev/macbook-setup/init.sh): bootstrap script
- [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml): runtimes and CLI tools
- [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile): GUI apps
- [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc): shell config symlinked into the home directory

## Notes

- The SSH public key is copied to your clipboard during setup so you can add it to GitHub.
- The script expects this repo to live at `~/dev/macbook-setup`.
- Restart your terminal after setup so the shell changes take effect.

# macbook-setup

Bootstrap a new MacBook with one script.

This repo installs the base developer setup I actually use:

- Xcode Command Line Tools
- Git config + SSH key
- Homebrew for GUI apps
- `mise` for runtimes and CLI tools
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
7. Install GUI apps from [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile)
8. Install Zsh plugins and symlink [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc) to `~/.zshrc`

## What gets installed

### CLI tools

CLI tools and runtimes are managed through [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml).

Current setup includes:

- Runtimes: Node.js, Python, Rust
- Direct binary tools via `http:`, including Upbound `up` and Crossplane CLI
- Infra tools: `kubectl`, `lima`, `colima`, `docker-cli`, `docker-compose`, `aws-cli`, `gh`, `jq`, `yq`
- Python CLI tools via `pipx`, including `gimme-aws-creds` and `git-filter-repo`
- GitHub release binaries via `github:`, including `glow` and `gitkb`
- Global npm packages including `typescript` and `@openai/codex`
- Standalone CLIs installed by [`init.sh`](/Users/patrickleet/dev/macbook-setup/init.sh), including Claude Code

### Apps

GUI apps are managed through [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile).

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

### Shell setup

The repo-managed [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc) sets up:

- Powerlevel10k
- `oh-my-zsh` git plugin
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `mise` shell activation
- A few personal aliases and helper functions

## Updating the setup

Edit the source files in this repo, then re-run the relevant install step:

```bash
mise install
brew bundle --file=~/dev/macbook-setup/Brewfile
ln -sf ~/dev/macbook-setup/.zshrc ~/.zshrc
```

`init.sh` can also be re-run safely on an existing machine. It checks for existing installs and updates the cloned repo when possible.

## Files

- [`init.sh`](/Users/patrickleet/dev/macbook-setup/init.sh): bootstrap script
- [`mise.toml`](/Users/patrickleet/dev/macbook-setup/mise.toml): runtimes and CLI tools
- [`Brewfile`](/Users/patrickleet/dev/macbook-setup/Brewfile): GUI apps
- [`.zshrc`](/Users/patrickleet/dev/macbook-setup/.zshrc): shell config symlinked into the home directory

## Notes

- The SSH public key is copied to your clipboard during setup so you can add it to GitHub.
- The script expects this repo to live at `~/dev/macbook-setup`.
- Restart your terminal after setup so the shell changes take effect.

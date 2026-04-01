#!/usr/bin/env bash
set -e

# =============================================================================
# macbook-setup — One script to rule them all
# curl -fsSL https://raw.githubusercontent.com/patrickleet/macbook-setup/main/init.sh | bash
# =============================================================================

REPO_URL="https://github.com/patrickleet/macbook-setup.git"
SETUP_DIR="$HOME/dev/macbook-setup"

# --- Colors ---
bold=$(tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2)
blue=$(tput setaf 4)

step() { echo "${bold}${blue}==> $1${normal}"; }
done_msg() { echo "${bold}${green}  ✓ $1${normal}"; }

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
step "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  done_msg "Already installed"
else
  xcode-select --install
  echo "Waiting for Xcode CLI tools to finish installing..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  done_msg "Installed"
fi

# =============================================================================
# 2. Git identity
# =============================================================================
step "Git identity"
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)
GIT_NAME=$(git config --global user.name 2>/dev/null || true)

if [[ -n "$GIT_EMAIL" && -n "$GIT_NAME" ]]; then
  echo "  Current git identity: $GIT_NAME <$GIT_EMAIL>"
  read -r -p "  Keep this? [Y/n] " KEEP_IDENTITY
  if [[ "$KEEP_IDENTITY" =~ ^[Nn] ]]; then
    read -r -p "Git email: " GIT_EMAIL
    read -r -p "Git full name: " GIT_NAME
  fi
else
  read -r -p "Git email: " GIT_EMAIL
  read -r -p "Git full name: " GIT_NAME
fi

# =============================================================================
# 3. Homebrew (for GUI apps only)
# =============================================================================
step "Homebrew"
if command -v brew &>/dev/null; then
  done_msg "Already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this session
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  done_msg "Installed"
fi

# =============================================================================
# 4. Git (comes with Xcode CLI tools, configure it)
# =============================================================================
step "Git config"
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"
git config --global init.defaultBranch main
git config --global pull.rebase true
done_msg "Configured"

# =============================================================================
# 5. SSH key
# =============================================================================
step "SSH key"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  done_msg "Already exists"
else
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
  eval "$(ssh-agent -s)"
  cat > "$HOME/.ssh/config" <<SSHEOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
SSHEOF
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
  done_msg "Created — public key copied to clipboard"
  pbcopy < "$HOME/.ssh/id_ed25519.pub"
  echo ""
  echo "  ${bold}Add this key to GitHub before continuing:${normal}"
  echo "  https://github.com/settings/ssh/new"
  echo ""
  read -r -p "  Press Enter once you've added the key to GitHub..."
fi

# =============================================================================
# 6. Clone this repo (or pull latest)
# =============================================================================
step "Clone setup repo"
if [[ -d "$SETUP_DIR/.git" ]]; then
  git -C "$SETUP_DIR" pull --rebase
  done_msg "Updated"
elif [[ -d "$SETUP_DIR" ]]; then
  done_msg "Already exists (not yet a git repo, skipping clone)"
else
  mkdir -p "$HOME/dev"
  git clone "$REPO_URL" "$SETUP_DIR"
  done_msg "Cloned to $SETUP_DIR"
fi

# =============================================================================
# 7. mise — the dev tool manager
# =============================================================================
step "mise"
if command -v mise &>/dev/null; then
  done_msg "Already installed"
else
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
  done_msg "Installed"
fi

# Link global mise config
mkdir -p "$HOME/.config/mise"
ln -sf "$SETUP_DIR/mise.toml" "$HOME/.config/mise/config.toml"
done_msg "Linked mise.toml → ~/.config/mise/config.toml"

# Install all tools declared in mise.toml
step "Installing dev tools via mise"
mise install --yes
done_msg "All mise tools installed"

# =============================================================================
# 8. Krew + kubectl plugins
# =============================================================================
step "Krew"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
if command -v kubectl-krew &>/dev/null; then
  done_msg "Already installed"
else
  (
    set -e
    cd "$(mktemp -d)"
    OS="$(uname | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64|amd64)
        ARCH="amd64"
        ;;
      arm64|aarch64)
        ARCH="arm64"
        ;;
    esac
    KREW="krew-${OS}_${ARCH}"
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
    tar zxf "${KREW}.tar.gz"
    ./"${KREW}" install krew
  )
  done_msg "Installed"
fi

step "kubectl plugins via krew"
if kubectl krew list | grep -qx "ctx"; then
  done_msg "ctx already installed"
else
  kubectl krew install ctx
  done_msg "Installed ctx"
fi

if kubectl krew list | grep -qx "ns"; then
  done_msg "ns already installed"
else
  kubectl krew install ns
  done_msg "Installed ns"
fi

# =============================================================================
# 9. Claude Code (standalone installer)
# =============================================================================
step "Claude Code"
if command -v claude &>/dev/null; then
  done_msg "Already installed ($(claude --version 2>/dev/null))"
else
  curl -fsSL https://claude.ai/install.sh | sh
  done_msg "Installed"
fi

# =============================================================================
# 10. GUI apps via Homebrew casks
# =============================================================================
step "GUI apps (Homebrew casks)"
brew bundle --file="$SETUP_DIR/Brewfile"
done_msg "GUI apps installed"

# =============================================================================
# 11. Zsh plugins (direct source, no plugin manager)
# =============================================================================
step "Zsh plugins"
ANTIGEN_DIR="$HOME/.antigen/bundles"
mkdir -p "$ANTIGEN_DIR"

clone_if_missing() {
  local repo="$1"
  local dest="$ANTIGEN_DIR/$repo"
  if [[ -d "$dest" ]]; then
    done_msg "$repo (already cloned)"
  else
    git clone --depth 1 "https://github.com/$repo.git" "$dest"
    done_msg "$repo"
  fi
}

clone_if_missing "romkatv/powerlevel10k"
clone_if_missing "robbyrussell/oh-my-zsh"
clone_if_missing "zsh-users/zsh-autosuggestions"
clone_if_missing "zsh-users/zsh-syntax-highlighting"

# =============================================================================
# 12. Shell config
# =============================================================================
step "Shell config (.zshrc)"
ln -sf "$SETUP_DIR/.zshrc" "$HOME/.zshrc"
done_msg "Linked .zshrc → ~/.zshrc"

# =============================================================================
# 13. Optional auto-updates
# =============================================================================
step "auto-updates"
read -r -p "  Install background auto-updates for dev tools, Homebrew, and Zsh plugins? [Y/n] " INSTALL_MISE_AUTO_UPDATES
if [[ ! "$INSTALL_MISE_AUTO_UPDATES" =~ ^[Nn] ]]; then
  "$SETUP_DIR/scripts/install-mise-auto-updates.sh"
  done_msg "Installed LaunchAgent for auto-updates"
else
  done_msg "Skipped"
fi

# =============================================================================
# Done!
# =============================================================================
echo ""
echo "${bold}${green}Setup complete!${normal}"
echo ""
echo "  Your config lives in: ${bold}$SETUP_DIR${normal}"
echo "  Edit ${bold}mise.toml${normal} to add/remove dev tools"
echo "  Edit ${bold}Brewfile${normal} to add/remove GUI apps"
echo "  Install missing tools: ${bold}mise install${normal}"
echo "  Upgrade mise-managed tools: ${bold}$SETUP_DIR/scripts/update-tools.sh${normal}"
echo "  Manage auto-updates: ${bold}$SETUP_DIR/scripts/install-mise-auto-updates.sh${normal}"
echo "  Sync GUI apps: ${bold}brew bundle --file=$SETUP_DIR/Brewfile${normal}"
echo ""
echo "  ${bold}Restart your terminal to pick up all changes.${normal}"

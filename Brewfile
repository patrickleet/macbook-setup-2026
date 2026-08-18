# =============================================================================
# Brewfile — GUI apps plus Homebrew-managed exceptions
# mise handles most CLI tools; Homebrew covers GUI apps and formulas not in mise
# =============================================================================

# --- CLI tools ---
brew "watch"
brew "poppler"
brew "direnv"
# docker-buildx is a Docker CLI plugin (multi-arch image builds); brew puts it
# at the plugin path docker discovers automatically. mise can't manage CLI
# plugins, so it lives here.
brew "docker-buildx"
brew "helm-ls"
brew "tree"

# --- hops local: kiac backend (Apple silicon k8s via apple/container) ---
# https://github.com/saiyam1814/kiac — each node is a lightweight VM.
# hops: `hops local start --backend kiac` → cluster hops, context kiac-hops
#
# IMPORTANT: kiac 0.4.0 + apple/container 1.2.x fails node boot
# (sysctl ip_forward — https://github.com/saiyam1814/kiac/issues/14).
# Prefer container 1.1.0 from https://github.com/apple/container/releases
# until that is fixed. `brew install container` currently ships 1.2.x.
tap "saiyam1814/tap"
brew "saiyam1814/tap/kiac"
# brew "container"  # pin 1.1.0 manually for kiac until #14 is fixed

# --- Containers ---
tap "augani/dory"
cask "augani/dory/dory"

# --- Browsers ---
cask "arc"

# --- Development ---
cask "zed"
cask "ghostty"

# --- Communication ---
cask "zoom"
cask "slack"
cask "discord"

# --- Utilities ---
cask "spotify"
cask "superwhisper"
cask "adobe-creative-cloud"
cask "crossover"
cask "protonvpn"

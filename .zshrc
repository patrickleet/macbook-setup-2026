# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── PATH (consolidated, fast) ──────────────────────────────────────
typeset -U path  # deduplicate PATH entries
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.ubi/bin:$HOME/.cargo/bin:$PATH"
export PATH="$HOME/dev/flutter/bin:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/Users/patrickleet/.rd/bin:$PATH"
export PNPM_HOME="/Users/patrickleet/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="$ASDF_DATA_DIR/shims:$PATH"

# ── Exports ─────────────────────────────────────────────────────────
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# ── Docker Host ────────────────────────────────────────────────────
export DOCKER_HOST=unix:///Users/patrickleet/.colima/default/docker.sock

# ── Theme (direct source, no plugin manager) ───────────────────────
source ~/.antigen/bundles/romkatv/powerlevel10k/powerlevel10k.zsh-theme

# ── History ─────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt share_history

# Make / and - delimiters for Option+Delete
WORDCHARS=${WORDCHARS/\//}
WORDCHARS=${WORDCHARS//-/}

# ── Directory navigation ───────────────────────────────────────────
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# ── Completion (cached, only rebuild once per day) ─────────────────
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ── oh-my-zsh plugins (direct source, no framework overhead) ──────
source ~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git/git.plugin.zsh
source ~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh

# ── Aliases ─────────────────────────────────────────────────────────
alias k='kubectl'

# ── Functions ───────────────────────────────────────────────────────
istiocurl() {
  kubectl run --restart=Never -t -i --rm --image=solsson/curl istiocurl -- \
    --connect-to :80:istio-ingressgateway.istio-system.svc.cluster.local:80 "$@"
}

gac() {
  $(gimme-aws-creds -p "$@" | grep -v arn:aws:iam)
}

gacfile() {
  GIMME_AWS_CREDS_OUTPUT_FORMAT=json gimme-aws-creds -p "$@" | gimme-aws-creds --action-store-json-creds
}

yt() {
  fabric -y "$1" --transcript
}

# ── Cached kubectl completions ─────────────────────────────────────
# Regenerates only when kubectl binary changes
{
  local _kc_cache="$HOME/.zsh_kubectl_completion"
  local _kc_bin="$(command -v kubectl 2>/dev/null)"
  if [[ -n "$_kc_bin" ]]; then
    if [[ ! -f "$_kc_cache" || "$_kc_bin" -nt "$_kc_cache" ]]; then
      kubectl completion zsh >| "$_kc_cache" 2>/dev/null
    fi
    source "$_kc_cache"
  fi
}
compdef k=kubectl

# ── Lazy-load pyenv (only initializes on first use) ────────────────
if (( $+commands[pyenv] )); then
  pyenv() {
    unfunction pyenv 2>/dev/null
    eval "$(command pyenv init --path)"
    eval "$(command pyenv init -)"
    pyenv "$@"
  }
fi

# ── Cached fabric aliases (regenerates when patterns dir changes) ──
{
  local _fab_cache="$HOME/.zsh_fabric_aliases"
  local _fab_dir="$HOME/.config/fabric/patterns"
  if [[ -d "$_fab_dir" ]]; then
    if [[ ! -f "$_fab_cache" || "$_fab_dir" -nt "$_fab_cache" ]]; then
      print -l ${(f)"$(for f in "$_fab_dir"/*; do echo "alias ${f:t}='fabric --pattern ${f:t}'"; done)"} >| "$_fab_cache"
    fi
    source "$_fab_cache"
  fi
}

# ── Cached try init ────────────────────────────────────────────────
{
  local _try_cache="$HOME/.zsh_try_init"
  local _try_bin="$(command -v try 2>/dev/null)"
  if [[ -n "$_try_bin" ]]; then
    if [[ ! -f "$_try_cache" || "$_try_bin" -nt "$_try_cache" ]]; then
      command try init ~/src/tries >| "$_try_cache" 2>/dev/null
    fi
    source "$_try_cache"
  fi
}

# ── Plugins (direct source) ────────────────────────────────────────
source ~/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax-highlighting must be last
source ~/.antigen/bundles/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── p10k config ─────────────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# I can't stop typing code to open projects
alias code=zed

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/patrickleet/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

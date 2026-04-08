# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── PATH ────────────────────────────────────────────────────────────
typeset -U path  # deduplicate PATH entries
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.krew/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

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

# ── Key bindings ───────────────────────────────────────────────────
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Make /, -, and . delimiters for Option+Delete
WORDCHARS=${WORDCHARS/\//}
WORDCHARS=${WORDCHARS//-/}
WORDCHARS=${WORDCHARS//./}

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
autoload -Uz bashcompinit
bashcompinit

# ── oh-my-zsh plugins (direct source, no framework overhead) ──────
source ~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git/git.plugin.zsh
source ~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh

# ── Aliases ─────────────────────────────────────────────────────────
alias k='kubectl'

# ── Functions ───────────────────────────────────────────────────────
gac() {
  $(gimme-aws-creds -p "$@" | grep -v arn:aws:iam)
}

gacfile() {
  GIMME_AWS_CREDS_OUTPUT_FORMAT=json gimme-aws-creds -p "$@" | gimme-aws-creds --action-store-json-creds
}

update_mac_deps() {
  launchctl kickstart -k "gui/$(id -u)/com.patrickleet.macbook-setup.mise-updates"
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
    if (( $+functions[_kubectl] )); then
      compdef _kubectl k
    fi
  fi
}

# ── Cached Helm completions ────────────────────────────────────────
# Regenerates only when helm binary changes
{
  local _helm_cache="$HOME/.zsh_helm_completion"
  local _helm_bin="$(command -v helm 2>/dev/null)"
  if [[ -n "$_helm_bin" ]]; then
    if [[ ! -f "$_helm_cache" || "$_helm_bin" -nt "$_helm_cache" ]]; then
      helm completion zsh >| "$_helm_cache" 2>/dev/null
    fi
    source "$_helm_cache"
  fi
}

# ── AWS CLI completions ────────────────────────────────────────────
if command -v aws_completer &>/dev/null; then
  complete -C "$(command -v aws_completer)" aws
fi

# ── Plugins (direct source) ────────────────────────────────────────
source ~/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax-highlighting must be last
source ~/.antigen/bundles/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── mise (dev tool manager) ────────────────────────────────────────
eval "$(~/.local/bin/mise activate zsh)"

# ── p10k config ─────────────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# I can't stop typing code to open projects
alias code=zed

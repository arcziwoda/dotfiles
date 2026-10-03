# Interactive zsh. Environment/PATH lives in .zprofile.

BREW_PREFIX=/opt/homebrew

# ── History ────────────────────────────────────────────────────────────
HISTFILE="$XDG_STATE_HOME/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p ${HISTFILE:h}
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # record timestamps
setopt SHARE_HISTORY           # sync history across running shells
setopt HIST_IGNORE_ALL_DUPS    # keep only the newest copy of a duplicate
setopt HIST_IGNORE_SPACE       # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY             # expand !! and friends before running

# ── Shell options ──────────────────────────────────────────────────────
setopt AUTO_CD                 # `dotfiles` == `cd dotfiles`
setopt AUTO_PUSHD              # every cd pushes to the dir stack
setopt PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS    # allow # comments when pasting commands
setopt NO_BEEP

# ── Completion ─────────────────────────────────────────────────────────
# Some oh-my-zsh plugins loaded via antidote (docker) generate completions into
# $ZSH_CACHE_DIR/completions — a framework variable that has to exist here.
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"
fpath=("$ZSH_CACHE_DIR/completions" $fpath)

_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump"
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}
autoload -Uz compinit
# Full rebuild at most once a day; -C skips the security scan otherwise.
if [[ -n $_zcompdump(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
# fzf-tab replaces zsh's own menu; leaving it enabled breaks the popup.
zstyle ':completion:*' menu no

# ── Plugins ────────────────────────────────────────────────────────────
# Initialise zsh-vi-mode while sourcing so later keybindings survive.
ZVM_INIT_MODE=sourcing

source $BREW_PREFIX/opt/antidote/share/antidote/antidote.zsh
antidote load

# fzf-tab: preview the thing under the cursor, and let it inherit fzf's theme.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z|ls|eza|__zoxide_z):*' fzf-preview \
  'eza -1 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:(bat|cat|nvim|vim|rm|cp|mv):*' fzf-preview \
  '[[ -d $realpath ]] && eza -1 --color=always $realpath || bat -n --color=always $realpath'

# ── Prompt ─────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Tools ──────────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

# fzf: key bindings only (Ctrl-R history, Ctrl-T files, Alt-C cd).
# completion.zsh is deliberately NOT sourced — it binds Tab and would fight
# fzf-tab, which does the same job better.
source $BREW_PREFIX/opt/fzf/shell/key-bindings.zsh

export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/fzf/fzfrc"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range=:200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"

# ── Environment ────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim
export BAT_THEME="Catppuccin Macchiato"
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"   # eza ignores its theme without this on macOS
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# zsh-autosuggestions: suggest from history, dim grey (Catppuccin overlay0)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6e738d'

# ── Aliases and functions ──────────────────────────────────────────────
source $XDG_CONFIG_HOME/zsh/aliases.zsh

# ── herdr Spaces panel: uncommitted changes per workspace ──────────────
source $XDG_CONFIG_HOME/zsh/herdr-space.zsh

# ── tmux sessions (sesh) ───────────────────────────────────────────────
# Must stay last: it ends with an `exec` when starting outside tmux.
source $XDG_CONFIG_HOME/zsh/sesh.zsh

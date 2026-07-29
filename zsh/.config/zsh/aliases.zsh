# ── Navigation ─────────────────────────────────────────────────────────
alias cd='z'                   # zoxide; still accepts plain paths and `cd -`
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Listing (eza) ──────────────────────────────────────────────────────
alias ls='eza --icons=always --group-directories-first'
alias ll='eza --icons=always --group-directories-first --long --header --git'
alias la='eza --icons=always --group-directories-first --long --header --git --all'
alias lt='eza --icons=always --tree --level=2'
alias tree='eza --tree --git-ignore'

# ── Viewing and diffing ────────────────────────────────────────────────
alias cat='bat'
alias diff='difft'             # structural diff; `git diff` uses delta instead

# ── Git ────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status --short --branch'
alias lg='lazygit'

# ── Python ─────────────────────────────────────────────────────────────
alias venv='python3 -m venv .venv && source .venv/bin/activate'

# ── Docker (OrbStack) ──────────────────────────────────────────────────
alias dcu='docker context use'

# ── Network ────────────────────────────────────────────────────────────
# Was aliased over `ifconfig` itself, which made the real command unusable.
alias ips="ifconfig | grep 'inet ' -B4"

# ── Editing this setup ─────────────────────────────────────────────────
alias ezsh='nvim ~/.zshrc'
alias szsh='exec zsh'          # a fresh shell; re-sourcing .zshrc double-loads plugins
alias ealias='nvim $XDG_CONFIG_HOME/zsh/aliases.zsh'
alias etmux='nvim $XDG_CONFIG_HOME/tmux/tmux.conf'
alias stmux='tmux source-file $XDG_CONFIG_HOME/tmux/tmux.conf'
alias dot='cd ~/dotfiles'

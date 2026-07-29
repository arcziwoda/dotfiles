# Login shells: environment and PATH only. Interactive setup lives in .zshrc.

# ── Homebrew ───────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── XDG base directories ───────────────────────────────────────────────
# Set explicitly: several tools (eza, bat, fzf) only find their config when
# these are defined, and macOS does not set them.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ── PATH ───────────────────────────────────────────────────────────────
path=("$HOME/.local/bin" $path)
export PATH

# ── OrbStack (docker CLI, orb) ──────────────────────────────────────────
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

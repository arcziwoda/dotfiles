#!/usr/bin/env bash
# Steps that stow cannot do: fetch things that are data rather than config.
# Idempotent — safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_PLUGINS="$HOME/.local/share/tmux/plugins"
CATPPUCCIN_TMUX_TAG="v2.3.0"

echo "==> Homebrew packages"
brew bundle --file="$DOTFILES/Brewfile"

echo "==> Stow packages"
cd "$DOTFILES"
stow claude ghostty zsh starship fzf bat eza tmux sesh nvim mise

echo "==> bat theme cache"
bat cache --build >/dev/null

echo "==> catppuccin/tmux $CATPPUCCIN_TMUX_TAG"
# Installed by hand rather than through tpack: upstream recommends it, and
# tpack's hashed directory names would break the `run` path in tmux.conf.
if [[ -d "$TMUX_PLUGINS/catppuccin" ]]; then
  git -C "$TMUX_PLUGINS/catppuccin" fetch --tags --quiet
  git -C "$TMUX_PLUGINS/catppuccin" checkout --quiet "$CATPPUCCIN_TMUX_TAG"
else
  mkdir -p "$TMUX_PLUGINS"
  git clone --quiet --depth 1 --branch "$CATPPUCCIN_TMUX_TAG" \
    https://github.com/catppuccin/tmux.git "$TMUX_PLUGINS/catppuccin"
fi

echo "==> tmux plugins"
tpack install

echo
echo "Done. Remaining manual steps:"
echo "  - open a new terminal (Ghostty) to pick up the shell config"
echo "  - run ./macos/defaults.sh if you want the system tweaks"

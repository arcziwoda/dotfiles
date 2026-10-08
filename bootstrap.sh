#!/usr/bin/env bash
# Steps that stow cannot do: fetch things that are data rather than config.
# Idempotent — safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_PLUGINS="$HOME/.local/share/tmux/plugins"
CATPPUCCIN_TMUX_TAG="v2.3.0"
REVIEWR_TAG="v0.39.0"
NAVIGATOR_TAG="v0.3.6"
NAVIGATOR_DIR="$HOME/.local/share/herdr/local-plugins/herdr-navigator"

echo "==> Homebrew packages"
brew bundle --file="$DOTFILES/Brewfile"

echo "==> Stow packages"
cd "$DOTFILES"
stow claude ghostty zsh starship fzf bat eza tmux sesh herdr nvim mise git bin

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

echo "==> herdr Claude Code integration"
# settings.json (in the repo) already calls the hook; this writes the script it
# calls, ~/.claude/hooks/herdr-agent-state.sh. The script is managed by herdr
# and rewritten on updates, so it stays out of the repo. No-op when current.
herdr integration install claude >/dev/null

echo "==> herdr plugins"
# Plugins are global herdr data (outside the repo); their configs are stowed
# from herdr/.config/herdr/plugins/config/. Bump the tags here to upgrade.
if ! herdr plugin list | grep -qF "github:persiyanov/herdr-reviewr@$REVIEWR_TAG"; then
  # Its build step downloads a checksummed prebuilt binary; no Rust needed.
  herdr plugin install persiyanov/herdr-reviewr --ref "$REVIEWR_TAG" --yes >/dev/null
fi
# herdr-navigator's manifest builds with cargo. Rather than pulling in a Rust
# toolchain, unpack the prebuilt release, put the binary where the manifest
# expects it and link the directory — `plugin link` skips the build step.
if ! grep -qF "version = \"${NAVIGATOR_TAG#v}\"" "$NAVIGATOR_DIR/herdr-plugin.toml" 2>/dev/null; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/thanhdat77/herdr-navigator/releases/download/$NAVIGATOR_TAG/herdr-navigator-macos-aarch64.tar.gz" |
    tar xz -C "$tmp"
  herdr plugin unlink herdr-navigator >/dev/null 2>&1 || true
  rm -rf "$NAVIGATOR_DIR"
  mkdir -p "$(dirname "$NAVIGATOR_DIR")"
  mv "$tmp/herdr-navigator" "$NAVIGATOR_DIR"
  rmdir "$tmp"
  mkdir -p "$NAVIGATOR_DIR/target/release"
  mv "$NAVIGATOR_DIR/herdr-navigator" "$NAVIGATOR_DIR/target/release/"
  herdr plugin link "$NAVIGATOR_DIR" >/dev/null
fi
# Our own plugins, versioned in the herdr package and stowed first.
for plugin in space-status; do
  if ! herdr plugin list | grep -qF "dotfiles.$plugin"; then
    herdr plugin link "$HOME/.config/herdr/local-plugins/$plugin" >/dev/null
  fi
done

echo
echo "Done. Remaining manual steps:"
echo "  - open a new terminal (Ghostty) to pick up the shell config"
echo "  - run ./macos/defaults.sh if you want the system tweaks"
	echo "  - create ~/.config/git/config-work (work identity; see git/.gitconfig)"

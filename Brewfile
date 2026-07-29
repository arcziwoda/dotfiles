# Install with: brew bundle --file=~/dotfiles/Brewfile
# Regenerate with care: `brew bundle dump --describe --force` overwrites this file
# and captures whatever is installed, cruft included.

# ── Core ───────────────────────────────────────────────────────────────
brew "git"
brew "gh"                          # GitHub CLI
brew "stow"                        # dotfiles symlink manager

# ── Terminal ───────────────────────────────────────────────────────────
cask "ghostty"                     # terminal emulator
cask "font-jetbrains-mono-nerd-font"

# ── Shell ──────────────────────────────────────────────────────────────
brew "antidote"                    # zsh plugin manager (replaces oh-my-zsh)
brew "starship"                    # prompt
brew "mise"                        # runtime versions: python, node, java

# ── CLI tools ──────────────────────────────────────────────────────────
brew "fzf"
brew "zoxide"                      # `z` — frecency-based cd
brew "eza"                         # ls
brew "bat"                         # cat
brew "fd"                          # find
brew "ripgrep"                     # rg (NOT aliased over grep — different semantics)
brew "difftastic"                  # structural diff, via `diff` and `git dft`
brew "git-delta"                   # git pager
brew "lazygit"

# ── Containers ─────────────────────────────────────────────────────────
cask "orbstack"                    # Docker/Linux VMs, lighter than Docker Desktop

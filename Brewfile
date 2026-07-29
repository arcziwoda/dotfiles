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

# ── Editor ─────────────────────────────────────────────────────────────
brew "neovim"                      # 0.12.x
brew "tree-sitter-cli"             # required by nvim-treesitter's main branch.
                                   # NOT the `tree-sitter` formula — that is the
                                   # library only and ships no binary.
brew "luajit"

# ── Containers ─────────────────────────────────────────────────────────
cask "orbstack"                    # Docker/Linux VMs, lighter than Docker Desktop

# ── tmux ───────────────────────────────────────────────────────────────
brew "tmux"                        # 3.7b: native floating panes
brew "tpack"                       # maintained TPM replacement
brew "sesh"                        # session manager (replaces tmux_session_manager)
brew "tmux-fingers"                # hint-based copy (prefix+F)

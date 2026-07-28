# Dotfiles

Konfiguracja środowiska macOS, zarządzana przez [GNU Stow](https://www.gnu.org/software/stow/).

## Instalacja od zera

```zsh
# 1. Homebrew (jeśli brak)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Repo
git clone git@github.com:arcziwoda/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Pakiety
brew bundle

# 4. Symlinki do $HOME
stow .
```

## Struktura

Katalogi odzwierciedlają strukturę `$HOME` — `stow .` tworzy symlinki. Pliki meta (README, docs/, Brewfile, CLAUDE.md) są wykluczone przez `.stow-local-ignore`.

Decyzje i research dot. wyboru narzędzi: [docs/research-2026.md](docs/research-2026.md). Opis poprzedniego setupu: [docs/old-setup.md](docs/old-setup.md).

# Dotfiles

Konfiguracja środowiska macOS, zarządzana przez [GNU Stow](https://www.gnu.org/software/stow/).

Ghostty · zsh + antidote · starship · tmux + sesh · Neovim (LazyVim) · Catppuccin Macchiato

## Instalacja od zera

```zsh
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Repo
git clone git@github.com:arcziwoda/dotfiles.git ~/dotfiles

# 3. Wszystko pozostałe: pakiety, symlinki, motywy, pluginy tmuxa
~/dotfiles/bootstrap.sh

# 4. Opcjonalnie: ustawienia systemowe
~/dotfiles/macos/defaults.sh
```

Przy pierwszym uruchomieniu Neovima lazy.nvim dociąga pluginy, a mason serwery LSP.

## Struktura

Każdy katalog najwyższego poziomu to **pakiet Stow**, którego wnętrze odzwierciedla strukturę `$HOME`:

| Pakiet | Zawartość |
|---|---|
| `ghostty/` | config terminala |
| `zsh/` | `.zprofile` (env, PATH, XDG), `.zshrc`, `.zsh_plugins.txt`, aliasy, picker sesji |
| `starship/` | `starship.toml` z paletą Catppuccin |
| `tmux/` | `tmux.conf` |
| `sesh/` | `sesh.toml` — deklaracje projektów dla pickera sesji |
| `nvim/` | LazyVim + `lazy-lock.json` |
| `git/` | `.gitconfig`, globalny `ignore`, tożsamość firmowa, motyw delty |
| `mise/` | globalne wersje runtime |
| `fzf/`, `bat/`, `eza/` | motywy Catppuccin |
| `claude/` | konfiguracja Claude Code |

Pliki w rootcie (`README.md`, `CLAUDE.md`, `docs/`, `Brewfile`, `bootstrap.sh`, `macos/`) nie są pakietami, więc Stow ich nie dotyka.

## Codzienna praca

```zsh
stow <pakiet>      # zainstaluj/odśwież symlinki (opcje w .stowrc)
stow -R <pakiet>   # przestow po dodaniu nowych plików
stow -D <pakiet>   # usuń symlinki
brew bundle        # doinstaluj brakujące pakiety z Brewfile
```

Configi edytuj **w repo** — symlinki w `$HOME` wskazują tutaj. Po dodaniu *nowego* pliku do pakietu trzeba zrobić `stow -R <pakiet>`, bo `.stowrc` używa `--no-folding` (linkowane są pliki, nie katalogi).

## Skróty warte pamiętania

| Skrót | Działanie |
|---|---|
| terminal start | picker sesji tmuxa; detach zamyka okno |
| `Alt-s` | picker sesji z wnętrza shella |
| `prefix` = `C-a`, `prefix s` | picker sesji w popupie |
| `prefix g` | lazygit w popupie |
| `prefix F` | kopiowanie po podpowiedziach (tmux-fingers) |
| `C-h/j/k/l` | ruch między panelami tmuxa i splitami nvima |
| `Ctrl-R` / `Ctrl-T` / `Alt-C` | historia / pliki / katalogi przez fzf |
| `NO_AUTO_TMUX=1` | shell bez automatycznego wejścia w tmuxa |

## Dokumentacja

- [docs/research-2026.md](docs/research-2026.md) — dlaczego te narzędzia, co odrzucone, co obserwować
- [docs/old-setup.md](docs/old-setup.md) — poprzedni setup (2025) jako punkt odniesienia

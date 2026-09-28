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
| `herdr/` | `config.toml` — alternatywa dla tmuxa ze stanem agentów (keymap jak w tmuxie) |
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
| terminal start | picker sesji; detach zamyka okno, Esc daje zwykły shell |
| `Alt-s` | ten sam picker z wnętrza shella |
| `prefix` = `C-a`, `prefix s` | ten sam picker w popupie |
| `prefix g` | lazygit w popupie |
| `prefix F` | kopiowanie po podpowiedziach (tmux-fingers) |
| `Alt-h/j/k/l` | ruch między panelami tmuxa i splitami nvima |
| `Alt-Shift-j/k` | przesuwanie linii w nvimie (domyślnie w LazyVim `Alt-j/k`) |
| `Ctrl-L` | clear — celowo nieprzejęty przez nawigację |
| `Ctrl-R` / `Ctrl-T` / `Alt-C` | historia / pliki / katalogi przez fzf |
| `NO_AUTO_TMUX=1` | shell bez automatycznego wejścia w tmuxa |
| `mux herdr` / `mux tmux` | w czym startują nowe okna terminala (domyślnie tmux) |

Picker sesji jest jednym skryptem — `bin/.local/bin/tmux-sessions` — używanym przez wszystkie trzy wejścia, więc zachowują się identycznie: lista zawiera tylko żywe sesje tmuxa, a wpisanie nieistniejącej nazwy tworzy sesję. Poza tmuxem skrypt podłącza się do sesji, wewnątrz przełącza klienta.

### herdr

`mux herdr` przełącza start nowych okien na herdra, `mux tmux` wraca. Żywe sesje obu nie są ruszane. Mapowanie: sesja tmuxa = workspace (sidebar „spaces”), okno = tab, panel = panel. Keymap odwzorowuje tmux.conf:

| Skrót | Działanie |
|---|---|
| `prefix` = `C-a` (dwa razy = literalne `C-a`) | jak w tmuxie |
| `prefix c` / `n` / `p` / `1..9` / `,` | nowy tab / następny / poprzedni / skok / zmiana nazwy |
| `prefix \|` `%` / `-` `"` | split w bok / w dół |
| `prefix x` / `z` / `;` | zamknij panel / zoom / poprzedni panel |
| `Alt-h/j/k/l` | ruch między panelami (bez integracji z nvimem) |
| `prefix s`, `Alt-s` | picker workspace'ów |
| `prefix w` | nawigator (workspace'y, taby, agenci) |
| `prefix S-n` / `$` / `S-d` / `S-1..9` / `(` `)` | nowy / zmiana nazwy / zamknij / skok / poprzedni-następny workspace |
| `prefix a` | następny agent |
| `prefix g` | lazygit w popupie |
| `prefix d` / `q` | detach |
| `prefix R` / `S` / `?` | reload configu / ustawienia / lista bindingów |

Po restarcie maszyny herdr odtwarza layout i wznawia rozmowy Claude Code (`claude --resume`) dzięki hookowi `SessionStart` w `settings.json`.

## Dokumentacja

- [docs/research-2026.md](docs/research-2026.md) — dlaczego te narzędzia, co odrzucone, co obserwować
- [docs/old-setup.md](docs/old-setup.md) — poprzedni setup (2025) jako punkt odniesienia

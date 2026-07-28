# Dotfiles — Artur

Repozytorium konfiguracji środowiska na macOS. Zarządzane przez **GNU Stow**: pliki w tym repo są symlinkowane do `$HOME` (`stow .` z katalogu repo). Struktura katalogów odzwierciedla 1:1 strukturę względem `$HOME` (np. `.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`).

## Zasady pracy w tym repo

- **Nie edytuj plików w `$HOME` bezpośrednio** — edytuj je tutaj (symlinki i tak wskazują na repo, ale nowe pliki twórz zawsze w repo, potem `stow .`).
- Pliki meta (README, CLAUDE.md, docs/, Brewfile itp.) muszą być wpisane do `.stow-local-ignore`, żeby nie trafiały jako symlinki do `$HOME`.
- Nowe oprogramowanie instaluj przez Homebrew i dopisuj do `Brewfile`.
- Komunikacja z użytkownikiem po polsku; komentarze/commity po angielsku.
- Commituj małymi krokami z sensownymi opisami; nie pushuj bez wyraźnej prośby.

## Kontekst

- Poprzedni setup (repo `arcziwoda/zsh-dotfiles`, stan ~2025) jest opisany w `docs/old-setup.md`.
- Research i decyzje dot. nowego setupu: `docs/research-2026.md` (co wybraliśmy i dlaczego).
- Preferencje użytkownika: theme **Catppuccin** (macchiato), vi-mode w shellu, workflow oparty o fzf/zoxide, tmux jako podstawa pracy, Python (pyenv/venv) + Docker.

## Layout

```
~/dotfiles/
├── CLAUDE.md            # ten plik
├── README.md            # instrukcja instalacji od zera
├── .stow-local-ignore   # co NIE jest symlinkowane do $HOME
├── Brewfile             # pakiety Homebrew
├── docs/                # research, decyzje, notatki (nie stowowane)
├── .config/             # configi XDG (tmux, nvim, terminal, starship itd.)
└── .zshrc / inne dotfiles top-level
```

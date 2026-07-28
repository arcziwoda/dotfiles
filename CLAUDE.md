# Dotfiles — Artur

Repozytorium konfiguracji środowiska na macOS. Zarządzane przez **GNU Stow** w układzie **per-pakiet**: każdy katalog najwyższego poziomu (np. `zsh/`, `tmux/`, `claude/`) to pakiet, którego zawartość odzwierciedla strukturę względem `$HOME` (np. `tmux/.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`). Instalacja: `stow <pakiet>` (opcje w `.stowrc`: target `$HOME`, `--no-folding`).

## Zasady pracy w tym repo

- **Nie edytuj plików w `$HOME` bezpośrednio** — edytuj je tutaj; nowe pliki twórz zawsze w pakiecie w repo, potem `stow <pakiet>`.
- Pliki meta (README, CLAUDE.md, docs/, Brewfile) leżą w root repo — Stow ich nie dotyka, bo nie są pakietem. Nie twórz pakietu o nazwie kolidującej z meta-plikami.
- W pakiecie `claude/` trzymamy TYLKO config Claude Code (`settings.json`, `CLAUDE.md`, `output-styles/`, ew. `agents/`, `skills/`, `keybindings.json`). Nigdy nie dodawaj do repo stanu sesji z `~/.claude` (projects/, history.jsonl, sessions/, cache, shell-snapshots, backups, `.credentials*`) ani `~/.claude.json`.
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

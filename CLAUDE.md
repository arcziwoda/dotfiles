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
- Preferencje użytkownika: theme **Catppuccin macchiato** wszędzie, vi-mode w shellu, workflow oparty o fzf/zoxide, tmux jako podstawa pracy, Python + Docker (OrbStack).

## Layout

```
~/dotfiles/
├── CLAUDE.md  README.md  Brewfile  bootstrap.sh  .stowrc   # nie pakiety
├── docs/                  # research i decyzje
├── macos/defaults.sh      # ustawienia systemowe (uruchamiane, nie stowowane)
├── claude-mods/           # mody Claude Code (function hooks), nie stowowane
└── <pakiet>/…             # ghostty zsh starship tmux sesh nvim git mise
                           # fzf bat eza claude herdr
```

## Pułapki, o których trzeba pamiętać

- `.stowrc` używa `--no-folding` → linkowane są **pliki**, nie katalogi. Skutek: po dodaniu nowego pliku do pakietu konieczne jest `stow -R <pakiet>`, a pliki tworzone przez aplikacje lądują w `$HOME`, nie w repo. Jeśli taki plik ma być wersjonowany (jak `nvim/.config/nvim/lazy-lock.json`), trzeba go świadomie przenieść do repo i przestow­ować.
- Pluginy tmuxa żyją w `~/.local/share/tmux/plugins` (poza repo) — to dane, nie config. `catppuccin/tmux` jest klonowany ręcznie i przypięty do taga w `bootstrap.sh`, bo tpack używa hashowanych nazw katalogów i zepsułby ścieżkę w `run`.
- W nvimie `:colorscheme` wymaga nazwy `catppuccin-nvim`; goły `catppuccin` to inny, wbudowany w Neovima motyw. Przez LazyVim ustawiamy `colorscheme = "catppuccin"` i to jest poprawne.
- tmux-fingers nie parsuje kolorów hex — tylko nazwy ANSI.
- Brewfile potrzebuje `tree-sitter-cli`, nie `tree-sitter` (ta druga formuła to sama biblioteka, bez binarki).
- `zsh/.config/zsh/sesh.zsh` kończy się `exec` przy starcie poza tmuxem — musi być sourcowany **na końcu** `.zshrc`.
- **Nigdy nie uruchamiaj `tmux kill-server`** ani nie usuwaj `~/.local/share/tmux/resurrect` — to zabija żywe sesje użytkownika i jego zapisany stan. Config testuj na osobnym sockecie (`tmux -L test new-session -d`), a zmiany wprowadzaj przez `tmux source-file ~/.config/tmux/tmux.conf` albo `prefix R`.
- Nawigacja panelami jest na **Alt**+hjkl, nie Ctrl — vim-tmux-navigator domyślnie zabiera `C-l` w root-table i psuje clear w shellu. Przesuwanie linii w nvimie przeniesione z `A-j/A-k` na `A-J/A-K`.
- Remote pushuje przez alias SSH `github-arcziwoda` (klucz `~/.ssh/arcziwoda-gh`); goły `github.com` uwierzytelnia się kluczem drugiego konta. Przy operacjach `gh api` sprawdź aktywne konto: `gh auth switch --user arcziwoda`.
- `~/.config/git/config-work` (tożsamość dla `~/work/`) jest celowo POZA repo — repo jest publiczne. Na nowej maszynie utwórz go ręcznie (instrukcja w komentarzu w `git/.gitconfig`).
- `claude/.claude/settings.json` przechodzi przez filtr `clean` (`.gitattributes` + `[filter "strip-claude-state"]` w `git/.gitconfig`), który wycina klucz `autoMode` — Claude Code sam dopisuje tam snapshot środowiska ze ścieżkami domowymi. W `$HOME` klucz zostaje, do repo nie trafia; nie ma `smudge`, więc po `git checkout` znika z pliku roboczego do następnego setupu auto-mode. Filtr wymaga `jq` i zadziała dopiero po `stow git` — bez niego git po cichu przepuszcza plik w całości.
- Nie dodawaj do starshipa modułów wersji (`$java`/`$nodejs`/`$version` w `[python]`) — odpalają binarkę przy KAŻDYM prompcie (`java -version` = 32 ms). Profilowanie: `starship timings` w danym katalogu; pełny cykl w żywym shellu: `source ~/.config/zsh/prompt-bench.zsh`.
- Interaktywny zsh testuj przez `NO_AUTO_TMUX=1 script -q /dev/null zsh -lic '…'` — bez `NO_AUTO_TMUX=1` shell natychmiast robi exec w picker sesji.
- Mody Claude Code (pluginy function hooks, np. `claude-mods/secret-vault`) leżą w `claude-mods/` poza pakietami i ładuje je `CLAUDE_CODE_PLUGIN_DIRS` w `env` w `claude/.claude/settings.json`, wskazując wprost na repo. Nie przenoś ich do pakietu `claude/`: Stow z `--no-folding` linkuje pliki, a Claude Code odrzuca moduł, który przez symlink wskazuje poza folder pluginu (`path-traversal`). Claude Code zapisuje przy ładowaniu `.claude-plugin/types/` i `tsconfig.json` w folderze moda — są w `.gitignore`. Sprawdzanie: `claude plugin validate <mod>`, `claude plugin test <mod>`. Wbudowany `cc-plugin-sec-default` pomija pluginy użytkownika na `prompt.compose` i zdarzeniach `classic.*` (w `--debug-file`: `bypassed by cc-plugin-sec-default`), więc mod nie dopisze się do system promptu ani nie użyje `classic.SessionEnd`.
- **herdr + Claude Code: mapa całej integracji, przepływ danych, ograniczenia i checklista aktualizacji herdra są w `docs/herdr/README.md` — przeczytaj przed zmianą czegokolwiek w sidebarze, hookach czy pluginach.** Zmiany wyglądu sprawdzaj harnessem `docs/herdr/harness/harness.sh` (render do PNG).
- herdr jest w trialu obok tmuxa: `mux herdr|tmux` zapisuje wybór w `~/.local/state/multiplexer` (poza repo), a `sesh.zsh` startuje według niego. Guard `-z $HERDR_ENV` w `sesh.zsh` jest obowiązkowy — bez niego każdy panel herdra odpala tmuxa i herdr widzi `tmux` zamiast agenta. Wbudowany motyw `catppuccin` w herdrze to mocha; macchiato jest zrobione nadpisaniem wszystkich tokenów w `[theme.custom]`. Config testuj harnessem (`docs/herdr/harness/harness.sh`), nie ręcznie z `HERDR_CONFIG_PATH` wskazującym na plik w repo — herdr zapisuje swój stan (np. `release-notes.json`) obok tego pliku, czyli do repo.
- `herdr integration install claude` dopisuje hook `SessionStart` do `settings.json` **przez symlink**, czyli do pliku w repo, z absolutną ścieżką do `~/.claude/hooks/herdr-agent-state.sh`. Nie zamieniaj jej na `$HOME` — herdr rozpoznaje swój wpis po dokładnym stringu i przy reinstalacji dopisałby duplikat. Sam skrypt jest zarządzany przez herdra i zostaje poza repo; tworzy go `bootstrap.sh`.
- Pluginy herdra to dane poza repo (`herdr plugin list`); w repo są tylko ich configi (`herdr/.config/herdr/plugins/config/<id>/`) i przypięte tagi w `bootstrap.sh`. `herdr-navigator` buduje się przez `cargo`, a Rusta nie ma — dlatego jest rozpakowany z prebuilt release do `~/.local/share/herdr/local-plugins/` i podpięty przez `herdr plugin link` (link pomija build); jego wbudowany updater (`check_updates`) jest wyłączony, bo przeszedłby przez cargo. `levi-qiao/herdr-agent-usage` celowo odrzucony: zapisuje `settings.json` przez tmp+rename, co zrywa symlink Stow, i podmienia `statusLine` na własny wrapper — jego funkcję robi `statusline.sh` (pola `$task/$task2/$model/$ctx`) + `hooks/herdr-status.sh` (etykiety stanów `--state-label` + druga linia jako `$status2w`/`$status2b`, które przełącza nasz plugin `herdr/.config/herdr/local-plugins/claude-status` na `pane.agent_status_changed` — zwykłe pole nie może zależeć od stanu: herdr sam wybiera etykietę wg stanu wykrytego z ekranu, dlatego po akceptacji zgody `⚠` przechodzi w `⚙` bez nowego zdarzenia; synchroniczny na każdym wywołaniu narzędzia, więc ma zostać tani — jeden `jq`, jeden `herdr`) + `claude-quota.sh`.
- Claude Code uruchomiony w panelu herdra dziedziczy `HERDR_*`; każdy testowy tmux/herdr odpalany z takiej sesji trzeba startować z `env -u HERDR_ENV -u HERDR_SOCKET_PATH …` (inaczej „nested herdr is disabled”, a komendy `herdr` trafiają do żywej sesji użytkownika).
- Wygląd sidebaru herdra sprawdzaj renderem, nie na oko w tekście: sesja testowa w `tmux -L … -f <minimalny conf z RGB>`, fałszywy agent to skompilowany program o nazwie `claude` (wariant wypisujący prompt „Do you want to proceed?” + „Bash command” daje stan `blocked`) (skopiowany `/bin/sleep` macOS zabija), pola przez prawdziwy `statusline.sh` z przykładowym JSON-em, zrzut `capture-pane -e` → PNG (PIL + JetBrains Mono). Glify spoza JetBrains Mono Nerd Font (`◐◑↻▰`) Ghostty bierze z fontu zastępczego — w polach używaj tylko znaków, które font ma.

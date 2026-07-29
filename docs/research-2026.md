# Research i decyzje: setup 2026

Stan na 2026-07-29. Synteza deep researchu (agenci weryfikowali wersje/daty przez GitHub API i web, nie z pamięci modelu). Punkt odniesienia: stary setup opisany w [old-setup.md](old-setup.md).

## Decyzje — TL;DR

Wszystko poniżej jest **wdrożone** (2026-07-29).

| Obszar | Było (2025) | Jest (2026) |
|---|---|---|
| Zarządzanie dotfiles | GNU Stow, płaskie `stow .` | GNU Stow, **per-pakiet** (`stow zsh tmux ...`) + `.stowrc` |
| Terminal | iTerm2 | **Ghostty 1.3.1**, przezroczystość 0.9 + blur 20 |
| Shell | zsh + oh-my-zsh (vendored) | **zsh + antidote** (start ~110 ms) |
| Prompt | omz theme "apple" + `prompt_docker_host` | **starship** + paleta Catppuccin, `docker_context`, `»` |
| Multiplekser | tmux + TPM | **tmux 3.7b + tpack** |
| Session manager | własny `tmux_session_manager` (zsh+fzf) | **sesh** jako źródło listy + zachowane `exec` i `--print-query` |
| Theme tmux | catppuccin/tmux v1.0.2 | **catppuccin/tmux v2.3.0**, instalacja ręczna, pin na tag |
| Neovim | LazyVim (colorscheme vscode) | **LazyVim v16** (catppuccin macchiato, przezroczyste tło) |
| Wersje runtime | pyenv + `JAVA_HOME` na sztywno | **mise**: python 3.13, node lts, java temurin-25 |
| Diff | difftastic | **delta** (pager) + difftastic (`git dft`) |
| Git | brak configu | tożsamość rozdzielona przez `includeIf gitdir:~/work/` |
| macOS | ręcznie | `macos/defaults.sh` (klawiatura + Finder) |

---

## 1. Zarządzanie dotfiles: GNU Stow zostaje

- chezmoi/Nix/yadm rozwiązują problemy wielu maszyn, templatingu i sekretów — nie mamy ich na jednym MacBooku. Stow 2.4.1 jest utrzymywany i wystarczający.
- **Zmiana: układ per-pakiet zamiast `stow .`** — Stow dotyka tylko wskazanych pakietów, więc README/CLAUDE.md/docs/Brewfile strukturalnie nie trafiają do `$HOME` (bez regexów w ignore).
- `.stowrc`: `--dir=$HOME/dotfiles --target=$HOME --no-folding --verbose=1`. `--no-folding` jest istotne: linkuje pliki, nie katalogi — dzięki temu np. w `~/.claude/` i `~/.config/tmux/` może obok configu żyć stan runtime'owy nie należący do repo.
- Brewfile w root repo (nie stowowany), `brew bundle --file=~/dotfiles/Brewfile`; `Brewfile.lock.json` w `.gitignore`.
- Ustawienia systemowe macOS: idempotentny skrypt `macos/defaults.sh` z `defaults write`, uruchamiany ręcznie (nie stowowany). Odkrywanie kluczy: `defaults read` przed/po zmianie w System Settings + diff.

Źródła: [manual Stow](https://www.gnu.org/software/stow/manual/stow.html), [porównanie chezmoi](https://www.chezmoi.io/comparison-table/), [Brew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile).

## 2. Terminal: Ghostty (zamiast iTerm2; lepszy niż Alacritty)

Ranking dla naszego profilu (tmux-centric, Catppuccin, config w repo):

1. **Ghostty 1.3.1** — najlepszy macOS-native feel, config plain-text idealny pod Stow, **Catppuccin wbudowany** (`theme = Catppuccin Macchiato`, auto light/dark: `theme = dark:Catppuccin Macchiato,light:Catppuccin Latte`), ligatury, Metal. Problemy z terminfo po SSH rozwiązane od 1.2 (`shell-integration-features = ssh-env,ssh-terminfo`). Projekt przenosi się z GitHuba (kwestia issue-trackera, nie zdrowia projektu).
2. Kitty — techniczne #1 w feature'ach (graphics protocol → obrazki w nvim), ale najsłabszy macOS feel.
3. Alacritty — OK dla tmux-usera, ale **brak ligatur na zawsze** (issue #50 otwarte od 2017) i wolne tempo rozwoju. Pytanie z briefu "config w Alacritty?" — odpowiedź: Ghostty daje ten sam model configu-w-repo plus ligatury i natywność.
4. WezTerm — świetny config (Lua), ale bez release od 2024-02 (tylko nightly) → odpada.
5. iTerm2 — utrzymywany, ale config to binarny plist — nie da się go sensownie trzymać w dotfiles.

Kluczowe opcje startowe: `font-family = JetBrainsMono Nerd Font`, `font-thicken = true`, `macos-option-as-alt = left` (lewy Option = Alt dla tmux/nvim, prawy zostaje do polskich znaków), `window-save-state = never` (sesje trzyma tmux), `confirm-close-surface = false`.
W tmux.conf: `set -ga terminal-overrides ",xterm-ghostty:RGB"`.

Źródła: [docs config](https://ghostty.org/docs/config), [themes](https://ghostty.org/docs/features/theme), [alacritty #50](https://github.com/alacritty/alacritty/issues/50), [wezterm changelog](https://wezterm.org/changelog.html).

## 3. Shell: zsh zostaje, oh-my-zsh wylatuje

- **oh-my-zsh → antidote** (v2.2.1, 2026-07): lekki plugin manager, deklaratywny plik `.zsh_plugins.txt`, statyczne ładowanie (szybki start). Alternatywy zinit (aktywny, ale przekombinowany) i zim — antidote wygrywa prostotą.
- **Prompt: starship** (v1.26) + [paleta Catppuccin](https://github.com/catppuccin/starship). powerlevel10k jest oficjalnie w trybie "VERY LIMITED SUPPORT / MOST BUGS WILL GO UNFIXED" → nie zaczynać na nim nowego setupu.
- **fish 4.8** — realna alternatywa (autosuggestions/highlighting/catppuccin wbudowane), ale koszt: brak POSIX (skrypty, `source .venv/bin/activate`, snippety z internetu wymagają tłumaczenia). Nie warto przy dobrze skonfigurowanym zsh.
- **nushell** — odpada jako daily driver: startup ~200-300 ms vs ~5 ms zsh, tarcie z nvim/pluginami, PATH-trap jako login shell.

Zamienniki starych pluginów (wszystkie zweryfikowane jako żywe, 2026):

| Stare (omz) | Nowe | Uwagi |
|---|---|---|
| zsh-autosuggestions | zsh-users/zsh-autosuggestions | bez zmian, przez antidote |
| zsh-syntax-highlighting | zsh-users/zsh-syntax-highlighting | bez zmian; [port catppuccin](https://github.com/catppuccin/zsh-syntax-highlighting) (source przed pluginem) |
| zsh-vi-mode | jeffreytse/zsh-vi-mode | bez zmian (v0.12) |
| zsh-autocomplete (custom) | **Aloxaf/fzf-tab** (v1.3) | menu completion przez fzf — spójne z resztą workflow |
| you-should-use | MichaelAquilina/zsh-you-should-use | bez zmian |
| autoswitch_virtualenv | MichaelAquilina/zsh-autoswitch-virtualenv | bez zmian (push 2026-02) |
| plugin git/docker (omz) | aliasy własne + completions | omz nie jest potrzebny dla samych aliasów |
| plugin zoxide (omz) | `eval "$(zoxide init zsh)"` | natywna integracja |
| plugin tmux (omz) | sesh (patrz §5) | |

Historia: na jedną maszynę **fzf Ctrl-R wystarcza** — atuin ma sens głównie przy sync między maszynami (opcja na później; przy dodawaniu: `ATUIN_NOBIND` + ręczne bindkey, bo konflikt Ctrl-R z fzf).

**Python: rozważyć mise zamiast pyenv** (v2026.7, następca asdf; zarządza też node/java, ma env-y per projekt). Do decyzji przy konfiguracji zsh — pyenv nadal działa, mise to jedno narzędzie zamiast trzech.

## 4. Neovim: LazyVim zostaje — świadomie

- **LazyVim v16** nadal najlepszy dla profilu "działa out of the box, nie utrzymuję 2000 linii Lua". Ale uczciwie: projekt zwolnił — 0 commitów w lipcu 2026, folke pivotował do AI toolingu; lazy.nvim bez commita maintainera od ~8 mies. To config, nie serwis — zamrożony dalej działa, a pluginy pod spodem (blink.cmp, mason, treesitter, snacks) są zdrowe.
- Plan awaryjny: **AstroNvim v6** (najlepiej utrzymywane distro, day-1 wsparcie nvim 0.12). Migracja tania — `lua/plugins/*.lua` w większości przenośne. Trigger: LazyVim dalej bez commitów pod koniec 2026 + psuje się na nvim 0.13.
- NIE: LunarVim (martwy), NvChad (rdzeń stoi na 0.11), kickstart/własny config na vim.pack (ekosystem pluginów jeszcze nie dokumentuje vim.pack — za wcześnie).
- Neovim **0.12.4** z brew (LazyVim wymaga tylko 0.11.2, ale 0.12 daje natywne LSP i treesitter main bez pinowania). Wymagany CLI `tree-sitter` w Brewfile.
- Zmiany domyślne v16 vs nasza pamięć: snacks.picker zamiast telescope, blink.cmp zamiast nvim-cmp, snacks.explorer zamiast neo-tree — **najpierw spróbować domyślnych**, extras `editor.telescope`/`editor.neo-tree` tylko jeśli będą braki.
- Extras: `lang.python` (+ `vim.g.lazyvim_python_lsp = "basedpyright"`, `ruff`; venv-selector gra z pyenv/venv), `lang.java`, `lang.haskell`, `test.core`, `dap.core`.
- Colorscheme: catppuccin jest **w core LazyVim** — `{ "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } }` + plugin z `flavour = "macchiato"`, `transparent_background = true`. **Pułapka**: przy ręcznym `:colorscheme` nazwa to `catppuccin-nvim` (od v2.0.0; goły `catppuccin` to inny, wbudowany w nvim theme). Stary config miał vscode — zmieniamy na catppuccin dla spójności całego stacku.
- `lazy-lock.json` commitować (lockfile).

Źródła: [dyskusja "is LazyVim maintained?"](https://github.com/LazyVim/LazyVim/discussions/7024), [catppuccin naming](https://github.com/LazyVim/LazyVim/discussions/7085), [vim.pack guide](https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack).

## 5. tmux: zostaje; największy refactor configu

Alternatywy odpadły: Zellij (ładny, ale resurrection buggy + [problem pamięci na macOS #5056](https://github.com/zellij-org/zellij/issues/5056)), WezTerm mux (release stall), Ghostty (świadomie bez muxa). Obserwować: `zmx` (persistence bez okien, młode).

Zmiany vs stary config:

| Było | Jest | Powód |
|---|---|---|
| TPM | **tpack** (`brew install tpack`; `run 'tpack init'`) | TPM ledwo żywy; tpack drop-in, ta sama składnia `@plugin` |
| tmux-sensible | ~10 linii inline | martwy od 2022 |
| b0o/tmux-autoreload | `bind R source-file ...` | repo ZARCHIWIZOWANE |
| tmux-fzf-session-switch + `tmux_session_manager` | **sesh** (`brew install sesh`) | superset: fzf/TUI picker + zoxide + aliasy + startup_command per projekt + `sesh last` |
| tmux-yank | `set -g set-clipboard on` + copy-pipe `pbcopy` | wystarcza lokalnie na macOS |
| catppuccin v1.0.2 (TPM) | **v2.3.0, manual clone** do `~/.local/share/tmux/plugins/catppuccin` | v2 = breaking (status-line przez `#{E:@catppuccin_status_*}` PO linii `run`); manual install oficjalnie rekomendowany; bonus: auto latte/macchiato za systemem przez hooki `client-light/dark-theme` (tmux 3.6+) |
| tmux-fingers | zostaje (brew, aktywny) | domyślny klawisz teraz `F` |
| resurrect + continuum | zostają **warunkowo** | nieutrzymywane od 2023/24, otwarte bugi utraty danych; mitygacja: interval 15 min; następca (lazy-tmux) za młody |
| — | **christoomey/vim-tmux-navigator** | C-hjkl między panelami nvim↔tmux |

Ważne techniczne:
- `set -g detach-on-destroy off` (wymagane przez sesh), `set -g escape-time 10` (nvim), `focus-events on`, `renumber-windows on`, `default-terminal "tmux-256color"`.
- **`TMUX_PLUGIN_MANAGER_PATH` = `~/.local/share/tmux/plugins`** — pluginy poza stow tree, żeby nie lądowały w repo.
- Bind `s` → `display-popup -E "sesh picker -i"`; bind `g` → lazygit w popupie.
- W zshrc: auto `sesh connect default` poza tmuxem (odtwarza zachowanie starego managera).
- Nie budować tmux z HEAD na Apple Silicon (crash [#5385](https://github.com/tmux/tmux/issues/5385)) — brew 3.7b jest OK. tmux 3.7 ma natywne floating panes; `display-popup -E` ma datę ważności ([#5135](https://github.com/tmux/tmux/issues/5135)) — do obserwacji.

Źródła: [migracja catppuccin v2 #487](https://github.com/catppuccin/tmux/issues/487), [sesh](https://github.com/joshmedeski/sesh), [tpack migration](https://tmuxpack.github.io/tpack/getting-started/migrating-from-tpm/).

## 6. Narzędzia CLI

- **Bez obaw**: ripgrep 15.x, fd, fzf 0.74 (Ctrl-T/Ctrl-R/Alt-C + `FZF_DEFAULT_OPTS_FILE` z [portem catppuccin](https://github.com/catppuccin/fzf)), zoxide 0.10, bat (BAT_THEME="Catppuccin Macchiato" po `bat cache --build`), lazygit, yazi (rozważyć — wygrał kategorię TUI file manager, zastąpiłby alias `f`).
- **eza — watch**: najsłabsze ogniwo stacku (bus factor ~1, 9-mies. przerwy w release); zostaje, fallback `lsd`. Theme na macOS wymaga `EZA_CONFIG_DIR` (bug [#1224](https://github.com/eza-community/eza/issues/1224)).
- **Diff**: delta jako `core.pager` w gitconfig (+ [catppuccin.gitconfig](https://github.com/catppuccin/delta)) i difftastic pod aliasem `git dft` — komplementarne (delta: syntax/word-diff na co dzień; difftastic: diff strukturalny). difftastic nie ma themingu (tylko `DFT_BACKGROUND=dark`).
- **Nowe warte uwagi**: `jj` (Jujutsu — git-compatible VCS, mocno mainstreamuje; do wypróbowania osobno, nie w bootstrapie), `uv` (Python), `mise`, `ast-grep`.
- Pomijamy: atuin (na razie), television, diffsitter, neofetch (martwy — ew. fastfetch).

## 7. Spójny theming Catppuccin Macchiato

Ghostty (wbudowany) → tmux (port v2.3.0) → nvim (port v2.0.0, w core LazyVim) → starship (paleta) → fzf (`.rc` → `FZF_DEFAULT_OPTS_FILE`) → bat (tmTheme) → eza (eza-themes) → delta (gitconfig) → lazygit (port) → zsh-syntax-highlighting (port, stale ale działa).

Top 3 pułapki: (1) nazwa `catppuccin-nvim` vs `catppuccin`, (2) nazwy themes Ghostty z wielkich liter od 1.2.0, (3) eza theme.yml na macOS.

## 8. Plan wdrożenia (kolejność)

1. **Brewfile** + `brew bundle`: `stow tmux tpack sesh fzf zoxide tmux-fingers neovim tree-sitter ripgrep fd bat eza git-delta difftastic lazygit starship antidote zsh-autosuggestions? (nie — pluginy przez antidote)` + cask `ghostty`, font `font-jetbrains-mono-nerd-font`.
2. Pakiet `ghostty/` — config jak w §2.
3. Pakiet `zsh/` — `.zshrc` (antidote, starship, fzf, zoxide, aliasy z old-setup, sesh auto-connect), `.zsh_plugins.txt`.
4. Pakiet `tmux/` — nowy `tmux.conf` (§5) + bootstrap clone catppuccin; pakiet `sesh/` — `sesh.toml`.
5. Pakiet `nvim/` — LazyVim starter + extras + catppuccin (§4).
6. Pakiet `git/` — `.gitconfig` z delta + `dft` alias; pakiet `starship/` — `starship.toml` z paletą.
7. `macos/defaults.sh` — na końcu, przyrostowo.

## Rozstrzygnięte decyzje

- Terminal: **Ghostty** (ligatury, natywność macOS, wbudowany catppuccin).
- Font: **JetBrainsMono Nerd Font**, 14 pt.
- Motyw: **stały Macchiato** (bez auto light/dark — mniej ruchomych części w tmux i nvim).
- Wersje runtime: **mise** zamiast pyenv.
- Historia: **fzf Ctrl-R**; atuin dopiero gdyby pojawiła się druga maszyna.
- Aliasy: `grep→rg` oraz `python→python3`/`pip→pip3` **odrzucone** (patrz §6 i old-setup).
- Picker/explorer w nvimie: **domyślne snacks**, nie telescope/neo-tree.
- Języki w nvimie: Python, Java, TypeScript/JS, Docker/YAML/JSON. **Haskell pominięty.**
- Przezroczystość: **tak, w terminalu i w nvimie.**
- resurrect/continuum: **zostają** (świadomie, mimo braku opieki) — bo tylko one odtwarzają stan po reboocie; sesh sam tego nie robi.
- yazi, jj, fastfetch: **nie teraz** (jedna linijka w Brewfile, gdy będą potrzebne).

## Do obserwacji

- LazyVim — czy wróci aktywność jesienią 2026; jeśli nie i zacznie się psuć na nvim 0.13 → AstroNvim v6.
- resurrect/continuum — otwarte bugi (nadpisanie zapisu pustym plikiem, zacięcie serwera). Zapis co 15 min ogranicza ryzyko.
- eza — bus factor ~1; fallback `lsd`.
- `display-popup -E` w tmuxie — maintainer zapowiada ograniczenie tej funkcji; następcą są natywne floating panes z 3.7.
- Adres e-mail w `git/.gitconfig` to noreply GitHuba — do podmiany, jeśli wolisz prywatny adres. Ścieżka `~/work/` dla tożsamości firmowej musi istnieć, by `includeIf` zadziałał.

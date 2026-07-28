# Stary setup (repo `arcziwoda/zsh-dotfiles`, stan ~kwiecień 2025)

Analiza starego repo — punkt odniesienia przy odtwarzaniu/ulepszaniu konfiguracji.

## Zarządzanie dotfiles

- **GNU Stow**, repo w `~/dotfiles`, instalacja przez `stow .` (symlinki do `$HOME`).
- Wymagane pakiety wg README: `git stow neovim bat eza ripgrep difft fzf neofetch zoxide`.

## Shell: zsh + oh-my-zsh

- oh-my-zsh **zvendorowany w całości do repo** (ciężkie, do porzucenia).
- Theme promptu: `apple`, plus customowy `$(prompt_docker_host)»` w PROMPT.
- Pluginy: `git`, `autoswitch_virtualenv` (auto-aktywacja venv Pythona), `you-should-use` (przypomina o aliasach), `docker`, `zoxide`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `tmux`, `macos`, `nmap`, `zsh-vi-mode`; custom: `zsh-autocomplete`.
- PATH: homebrew, openvpn, mysql, pyenv (`pyenv init`), JAVA_HOME (openjdk 22), console-ninja.
- `zstyle ':completion:*' menu select`.

## Aliasy (`aliases.zsh`)

```zsh
alias python=python3
alias pip=pip3
alias cd="z"                 # zoxide
alias cat='bat'
alias ls='eza --icons=always'
alias ll='ls -lh'
alias grep='rg'
alias diff="difft"
alias ..='cd ..'
alias venv="python3 -m venv .venv && source .venv/bin/activate"
alias f='cd $(fd --type directory --hidden | fzf)'
alias ezsh / szsh / ealias / etmux / stmux   # edycja+reload configów
alias tree="tree --gitignore"
alias dcu="docker context use"
alias clang="clang++"
alias ifconfig="ifconfig | grep 'inet ' -B4"
```

## tmux (`.config/tmux/tmux.conf`)

- Prefix: `C-a` (zamiast `C-b`), `mouse on`, `base-index 1`, clipboard, truecolor override.
- Nowe okna/splity dziedziczą bieżący katalog.
- TPM + pluginy: `tmux-sensible`, `tmux-resurrect`, `tmux-continuum` (auto-restore on), `b0o/tmux-autoreload`, `tmux-yank`, `Morantron/tmux-fingers` (hint-copy, klawisz Space, hinty czerwone/niebieskie), `brokenricefilms/tmux-fzf-session-switch` (bind `prefix+s`, okno 70x20).
- Theme: **catppuccin/tmux v1.0.2**, flavor **macchiato**, `window_status_style: rounded`, teksty okien ` #W`.

## Custom: `tmux_session_manager` (funkcja zsh)

fzf-owy picker sesji tmux uruchamiany poza tmuxem:
- listuje istniejące sesje (sesja `default` zawsze pierwsza),
- wybór istniejącej → `exec tmux attach`,
- wpisanie nowej nazwy → `exec tmux new-session -s <nazwa>`,
- pusty wybór → sesja `default`.

## Neovim: LazyVim

- Bootstrap lazy.nvim + `LazyVim/LazyVim` z importem pluginów.
- Colorscheme: `vscode` (Mofiqul/vscode.nvim), zainstalowany też gruvbox; plugin `transparent` (przezroczyste tło).
- Custom pluginy: telescope, neo-tree, neotest, neoscroll, dashboard, friendly-snippets.
- Języki: Python, Java, Haskell (+ syntax dla prologa i smalltalka).

## Terminal

- iTerm2 (config nie był w repo).

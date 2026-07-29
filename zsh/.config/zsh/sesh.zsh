# tmux session management. The picker itself lives in ~/.local/bin/tmux-sessions
# so that this file, the Alt-s widget and tmux's `prefix s` all run exactly the
# same code. See that script for what it does.

# Alt-s: picker from inside a running shell. No exec — this should return you to
# where you were if you escape it.
function sesh-sessions() {
  exec </dev/tty
  exec <&1
  tmux-sessions
  zle reset-prompt >/dev/null 2>&1 || true
}
zle -N sesh-sessions
bindkey -M viins '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions

# Terminal start: straight into the picker. NO_AUTO_TMUX=1 gives a plain shell.
if [[ -o interactive && -z $TMUX && -z $NVIM && -z $VSCODE_INJECTION \
      && -z $INSIDE_EMACS && -z $NO_AUTO_TMUX ]]; then
  # The script execs into tmux, so control only comes back here once you detach
  # — at which point exit closes the window, as the old `exec tmux` setup did.
  # A non-zero status means the picker was escaped, so keep the plain shell.
  if tmux-sessions; then
    exit
  fi
fi

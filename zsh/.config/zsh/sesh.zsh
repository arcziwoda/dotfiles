# tmux session management. Successor to the old tmux_session_manager: same
# flow (fzf list, type a name that does not exist to create it, `exec` so that
# detaching closes the terminal), but the candidate list comes from sesh, so it
# also contains projects declared in sesh.toml — including ones not currently
# running, which is what makes it useful right after a reboot — and directories
# from zoxide history.

function tmux_session_manager() {
  local choice name
  choice=$(
    sesh list --icons | fzf \
      --print-query \
      --accept-nth '2..' \
      --height 60% --reverse --border --border-label ' sessions ' \
      --prompt '⚡ ' \
      --preview 'sesh preview {2..}' \
      --preview-window 'right:55%,border-left' \
      --bind 'tab:down,btab:up'
  )

  # --print-query prints the typed text first and the accepted match, if any,
  # on the following line — so the last line is the choice either way.
  # --accept-nth drops the icon column, so what lands here is a bare name.
  # Unlike the old script this does not strip whitespace, so names containing
  # spaces survive.
  name=${choice##*$'\n'}

  # Esc with an empty filter: fall back to the default session rather than
  # leaving the terminal with nothing.
  [[ -z $name ]] && name=default

  # Both branches `exec`, so this shell is replaced: detaching from tmux ends
  # the process and the terminal window closes.
  #
  # sesh only connects to what it already knows — live sessions, sesh.toml
  # entries, zoxide directories. A name typed from scratch, which is the whole
  # point of --print-query, it rejects outright, so create that directly the
  # way the old script did.
  if sesh list | grep -qxF -- "$name"; then
    exec sesh connect "$name"
  else
    exec tmux new-session -s "$name"
  fi
}

# Alt-s: switch sessions from inside a shell. No exec here — this one should
# return you to where you were.
function sesh-sessions() {
  exec </dev/tty
  exec <&1
  sesh picker -i
  zle reset-prompt >/dev/null 2>&1 || true
}
zle -N sesh-sessions
bindkey -M viins '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions

# Terminal start: straight into the picker. Set NO_AUTO_TMUX=1 to get a plain
# shell instead.
if [[ -o interactive && -z $TMUX && -z $NVIM && -z $VSCODE_INJECTION \
      && -z $INSIDE_EMACS && -z $NO_AUTO_TMUX ]]; then
  tmux_session_manager
fi

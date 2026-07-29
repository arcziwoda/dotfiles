# tmux session management. Successor to the old tmux_session_manager: same flow
# (fzf list, type a name that does not exist to create it, `exec` so detaching
# closes the terminal), with tmux-resurrect/continuum providing persistence.
#
# The list contains live tmux sessions only — no predeclared projects, no
# zoxide directory history.

function tmux_session_manager() {
  # After a reboot no server is running, so there would be nothing to list.
  # Starting one sources tmux.conf, and that is what makes tmux-continuum
  # restore the last saved state. The restore runs in the background, so wait
  # for it — but only when there is actually a save file to restore from.
  if ! tmux list-sessions >/dev/null 2>&1; then
    tmux start-server 2>/dev/null
    if [[ -e ${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last ]]; then
      local i
      for i in {1..24}; do
        tmux list-sessions >/dev/null 2>&1 && break
        sleep 0.25
      done
    fi
  fi

  local choice name
  choice=$(
    sesh list -t --icons | fzf \
      --ansi \
      --print-query \
      --accept-nth '2..' \
      --height 60% --reverse --border --border-label ' sessions ' \
      --prompt '⚡ ' \
      --preview 'sesh preview {2..}' \
      --preview-window 'right:55%,border-left' \
      --bind 'tab:down,btab:up'
  )

  # --print-query prints the typed text first and the accepted match, if any,
  # on the following line, so the last line is the choice either way.
  # --accept-nth drops the icon column; --ansi makes fzf interpret sesh's
  # colour codes instead of printing them as text.
  name=${choice##*$'\n'}

  # Nothing typed and nothing picked: stay in a plain shell rather than
  # inventing a session name.
  [[ -z $name ]] && return

  # Exact match against the session list. `tmux has-session -t=NAME` is not
  # usable here: it still matches prefixes, so a new session named "api" would
  # silently attach to an existing "api-gateway".
  #
  # Both branches `exec`, so this shell is replaced: detaching from tmux ends
  # the process and the terminal window closes.
  if tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -qxF -- "$name"; then
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

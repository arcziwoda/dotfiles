# Inside herdr: after every command, refresh the uncommitted-changes count of
# this pane's workspace in herdr's Spaces panel (dotfiles.space-status plugin).
# Runs in the background and detached, so the prompt never waits for it.
[[ -n $HERDR_ENV && -n $HERDR_PANE_ID ]] || return 0

typeset -g __herdr_space_refresh=$XDG_CONFIG_HOME/herdr/local-plugins/space-status/refresh.sh
[[ -r $__herdr_space_refresh ]] || return 0

__herdr_space_precmd() {
  bash $__herdr_space_refresh shell $HERDR_PANE_ID $HERDR_WORKSPACE_ID &>/dev/null &!
}
precmd_functions+=(__herdr_space_precmd)

#!/usr/bin/env bash
# pane.agent_status_changed hook: show the Claude status continuation that
# matches the pane's new state. ~/.claude/hooks/herdr-status.sh stores both
# tails as $tailw / $tailb; this copies the right one into $status2w (activity
# colour) or $status2b (warning colour) and empties the other. Panes without
# those tokens (other agents, plain shells) are left alone.
set -uo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
event=${HERDR_PLUGIN_EVENT_JSON:-}
[[ -n $event ]] || exit 0

{
	IFS= read -r pane
	IFS= read -r status
} < <(jq -r '(.data.pane_id // .pane_id // ""), (.data.agent_status // .agent_status // "")' <<<"$event")
[[ -n $pane && -n $status ]] || exit 0

{
	IFS= read -r has_tails
	IFS= read -r tailw
	IFS= read -r tailb
} < <("$herdr" pane get "$pane" 2>/dev/null | jq -r '
	.result.pane.tokens // {} | (has("tailw") or has("tailb")), (.tailw // ""), (.tailb // "")')
[[ $has_tails == true ]] || exit 0

if [[ $status == blocked ]]; then
	showw='' showb=$tailb
else
	showw=$tailw showb=''
fi
"$herdr" pane report-metadata "$pane" --source dotfiles:claude-hooks \
	--token "status2w=$showw" --token "status2b=$showb" >/dev/null 2>&1
exit 0

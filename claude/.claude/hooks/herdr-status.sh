#!/usr/bin/env bash
# Claude Code hook: publish what the session is doing to herdr's sidebar.
#
#   <warn> Bash        waiting for you (permission, question, plan)
#   <cog>  Edit        working: the tool it is running now, or "thinking"
#   <chk>  14:32       turn finished at that time
#
# Only the tool name, never its arguments: the status is one sidebar row,
# followed by herdr's " · " separator and the $model token from statusline.sh.
# herdr cannot align a token right, so the label is padded here to push the
# model to the row's right end; its width comes from the per-pane file
# statusline.sh leaves next to the token.
#
# The text is reported as herdr state labels — one per agent state — rather
# than a plain token. herdr shows the label of the state it currently detects
# on screen, so the moment a permission prompt is answered and Claude runs the
# tool, the row flips from the <warn> label to the <cog> one without waiting
# for another hook event (there is none for "permission granted").
#
# Outside herdr this is a no-op. Runs synchronously on every tool call, so it
# stays cheap: one jq, one herdr call over a local socket.
set -uo pipefail

[[ ${HERDR_ENV:-} == 1 && -n ${HERDR_PANE_ID:-} ]] || exit 0
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

LC_ALL=en_US.UTF-8 # ${#} must count characters, not bytes

# Nerd Font icons (U+F071, U+F013, U+F00C). Bash 3.2 (macOS /bin/bash) has no
# \u escapes in $'...', so they are written as UTF-8 bytes.
WARN=$'\xef\x81\xb1' COG=$'\xef\x80\x93' CHECK=$'\xef\x80\x8c'

# Event and tool name; mcp__server__tool -> tool.
{
	IFS= read -r event
	IFS= read -r tool
} < <(jq -r '.hook_event_name // "", (.tool_name // "" | sub("^mcp__.*__"; ""))')

# Same width as herdr's title rows: 30 columns, 29 with the list scrollbar.
WIDTH=29
model=''
model_file="${XDG_CACHE_HOME:-$HOME/.cache}/claude/herdr-model/${HERDR_PANE_ID//\//_}"
[[ -r $model_file ]] && IFS= read -r model <"$model_file"

# row TEXT: TEXT padded so that it, the " · " separator and the model name
# fill WIDTH columns; cut with an ellipsis when they do not fit. herdr trims
# trailing whitespace, so the padding ends in a zero-width space (U+200B),
# which it keeps but does not draw. Sets $row (no subshell: this runs on every
# tool call).
row() {
	row=$1
	[[ -n $model ]] || return 0
	local room=$((WIDTH - ${#model} - 3))
	((${#row} > room)) && row="${row:0:room-1}"$'\xe2\x80\xa6'
	printf -v row '%s%*s\xe2\x80\x8b' "$row" $((room - ${#row})) ''
}

send() {
	"${HERDR_BIN_PATH:-herdr}" pane report-metadata "$HERDR_PANE_ID" \
		--source dotfiles:claude-hooks "$@" >/dev/null 2>&1
}

# report TEXT [BLOCKED_TEXT]: TEXT (with the cog) for every state herdr may
# show, BLOCKED_TEXT (with the warning sign) for "blocked"; it defaults to TEXT.
report() {
	row "$COG $1"
	local working=$row
	row "$WARN ${2:-$1}"
	local blocked=$row
	send --state-label "working=$working" --state-label "unknown=$working" \
		--state-label "idle=$working" --state-label "done=$working" \
		--state-label "blocked=$blocked"
}

case $event in
	UserPromptSubmit) report thinking 'needs input' ;;
	PreToolUse)
		case $tool in
			# Waiting on you while the tool itself runs; PostToolUse resets it.
			AskUserQuestion) report thinking question ;;
			ExitPlanMode) report thinking plan ;;
			*) report "$tool" ;;
		esac
		;;
	PermissionRequest) report "$tool" ;;
	PostToolUse) report thinking 'needs input' ;; # only AskUserQuestion, ExitPlanMode
	Stop)
		row "$CHECK $(date +%H:%M)"
		done_label=$row
		row "$COG thinking"
		working_label=$row
		row "$WARN needs input"
		send --state-label "idle=$done_label" --state-label "done=$done_label" \
			--state-label "unknown=$done_label" --state-label "working=$working_label" \
			--state-label "blocked=$row"
		;;
	SessionStart | SessionEnd) send --clear-state-labels ;;
esac
exit 0

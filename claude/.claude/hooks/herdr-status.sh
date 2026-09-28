#!/usr/bin/env bash
# Claude Code hook: publish what the session is doing to herdr's sidebar.
#
#   <warn> Bash: rm -rf build     waiting for you (permission, question, plan)
#   <cog>  Edit forecast.py        working: the tool it is running now
#   <chk>  14:32                   turn finished at that time
#
# The text is reported as herdr state labels — one per agent state — rather
# than a plain token. herdr shows the label of the state it currently detects
# on screen, so the moment a permission prompt is answered and Claude runs the
# tool, the row flips from the <warn> label to the <cog> one without waiting
# for another hook event (there is none for "permission granted").
#
# Sidebar rows are single lines, so the text is wrapped at a word boundary:
# the first line goes into the labels, the rest into the $status2 token. Every
# label set in one call carries the same text behind a one-column icon, so the
# continuation is right whichever state herdr shows.
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
# Same width as herdr's title rows: 30 columns, 29 with the list scrollbar.
WIDTH=29

# event, tool, and a short description of the tool call on one line each.
{
	IFS= read -r event
	IFS= read -r tool
	IFS= read -r what
} < <(jq -r '
	def base: split("/") | last;
	.hook_event_name // "",
	.tool_name // "",
	(.tool_input // {} | (
		.description // .file_path // .notebook_path // .pattern // .query
		// (.url // "" | sub("^https?://"; "") | split("/") | first)
		// .command // .questions[0].question // .prompt // ""
	) | tostring | gsub("[\n\r\t]+"; " ")
	  | if test("^/") then base else . end)
')

# mcp__server__tool -> "server tool"
[[ $tool == mcp__* ]] && tool=$(sed -E 's/^mcp__([^_]+)__/\1 /' <<<"$tool")
label=$tool
[[ -n $what ]] && label="$tool: $what"

# Split "$1" into $line1 (at most WIDTH columns, breaking between words; a
# single longer word stays whole and herdr truncates it) and $line2.
wrap() {
	local word
	line1='' line2=''
	read -r -a words <<<"$1"
	for word in ${words[@]+"${words[@]}"}; do
		if [[ -z $line2 ]] && ((${#line1} + ${#word} + 1 <= WIDTH || ${#line1} == 0)); then
			line1+="${line1:+ }$word"
		else
			line2+="${line2:+ }$word"
		fi
	done
}

# report TEXT [BLOCKED_TEXT]: TEXT (with the cog) for every state herdr may
# show, BLOCKED_TEXT (with the warning sign) for "blocked"; it defaults to
# TEXT, and then both wrap identically since the icons are the same width.
# The continuation is taken from BLOCKED_TEXT: when the two differ (a question
# or a plan), the blocked state is the one on screen until PostToolUse.
report() {
	local text=$1 blocked=${2:-$1}
	wrap "$COG $text"
	local working=$line1
	wrap "$WARN $blocked"
	send --state-label "working=$working" --state-label "unknown=$working" \
		--state-label "idle=$working" --state-label "done=$working" \
		--state-label "blocked=$line1" --token "status2=$line2"
}

send() {
	"${HERDR_BIN_PATH:-herdr}" pane report-metadata "$HERDR_PANE_ID" \
		--source dotfiles:claude-hooks "$@" >/dev/null 2>&1
}

case $event in
	UserPromptSubmit) report thinking 'needs input' ;;
	PreToolUse)
		case $tool in
			# Waiting on you while the tool itself runs; PostToolUse resets it.
			AskUserQuestion) report thinking "question: $what" ;;
			ExitPlanMode) report thinking 'plan ready for review' ;;
			*) report "$label" ;;
		esac
		;;
	PermissionRequest) report "$label" ;;
	PostToolUse) report thinking 'needs input' ;; # only AskUserQuestion, ExitPlanMode
	Stop)
		done_label="$CHECK $(date +%H:%M)"
		send --state-label "idle=$done_label" --state-label "done=$done_label" \
			--state-label "unknown=$done_label" --state-label "working=$COG thinking" \
			--state-label "blocked=$WARN needs input" --token "status2="
		;;
	SessionStart | SessionEnd) send --clear-state-labels --token "status2=" ;;
esac
exit 0

#!/usr/bin/env bash
# Claude Code hook: publish what the session is doing as herdr pane metadata
# ($status token, shown in the Claude rows of herdr's sidebar).
#
#   <warn> Bash: rm -rf build     waiting for you (permission, question, plan)
#   <cog>  Edit forecast.py        working: the tool it is running now
#   <chk>  14:32                   turn finished at that time
#
# The three states share one token so the sidebar row keeps a fixed height.
# The leading glyph (Nerd Font icon) is what herdr's colour rules match on.
# Outside herdr this is a no-op. Runs synchronously on every tool call, so it
# stays cheap: one jq, one herdr call over a local socket.
set -uo pipefail

[[ ${HERDR_ENV:-} == 1 && -n ${HERDR_PANE_ID:-} ]] || exit 0
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

WARN=$'' COG=$'' CHECK=$''
# Bash 3.2 (macOS /bin/bash) has no \u escapes in $'...'; fall back to bytes.
[[ $WARN == '' ]] && WARN=$'\xef\x81\xb1' COG=$'\xef\x80\x93' CHECK=$'\xef\x80\x8c'

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

case $event in
	UserPromptSubmit) status="$COG thinking" ;;
	PreToolUse)
		case $tool in
			AskUserQuestion) status="$WARN question: $what" ;;
			ExitPlanMode) status="$WARN plan ready for review" ;;
			*) status="$COG $label" ;;
		esac
		;;
	PermissionRequest) status="$WARN $label" ;;
	Stop) status="$CHECK $(date +%H:%M)" ;;
	SessionStart | SessionEnd) status='' ;;
	*) exit 0 ;;
esac

"${HERDR_BIN_PATH:-herdr}" pane report-metadata "$HERDR_PANE_ID" \
	--source dotfiles:claude-hooks \
	--token "status=$status" \
	>/dev/null 2>&1
exit 0

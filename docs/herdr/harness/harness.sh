#!/usr/bin/env bash
# Visual test harness for the herdr sidebar (Claude rows, status, quota).
# Runs the repo's herdr config in an isolated herdr session inside a private
# tmux server, populates it with fake `claude` agents whose metadata comes from
# the real statusline.sh and herdr-status.sh, and renders the screen to PNG so
# the result can be looked at instead of guessed from plain text.
#
#   harness.sh start [ROWS]   fresh session (default 40 rows; use ~24 to make
#                             the agent list overflow and show its scrollbar)
#   harness.sh populate       three agents: finished, waiting on a permission
#                             prompt (really `blocked` to herdr), working
#   harness.sh approve        clear the permission prompt, as approving does
#   harness.sh render [OUT]   sidebar PNG (default $WORK/sidebar.png)
#   harness.sh stop           tear everything down
#
# Safe to run from a Claude Code session inside herdr: every herdr and tmux
# call drops the inherited HERDR_* variables, so nothing reaches the live
# session. Needs cc, jq, python3 with Pillow, and JetBrains Mono Nerd Font.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
WORK=${HARNESS_DIR:-${TMPDIR:-/tmp}/herdr-harness}
SESSION=harness
SOCK=$HOME/.config/herdr/sessions/$SESSION/herdr.sock
CLEAN_ENV=(env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH -u HERDR_TAB_ID
	-u HERDR_WORKSPACE_ID -u HERDR_BIN_PATH)

tm() { "${CLEAN_ENV[@]}" tmux -L herdr-harness -f "$HERE/tmux.conf" "$@"; }
h() { "${CLEAN_ENV[@]}" HERDR_SESSION=$SESSION herdr "$@"; }

build_fakes() {
	mkdir -p "$WORK/bin" "$WORK/bin-prompt"
	cc -o "$WORK/bin/claude" "$HERE/fake-claude.c"
	cc -o "$WORK/bin-prompt/claude" "$HERE/fake-claude-prompt.c"
}

stop() {
	tm kill-server 2>/dev/null || true
	h session stop "$SESSION" >/dev/null 2>&1 || true
	h session delete "$SESSION" >/dev/null 2>&1 || true
}

start() {
	stop
	build_fakes
	tm new-session -d -x 160 -y "${1:-40}" -s t
	tm set-option -t t remain-on-exit on
	# A copy, not the repo file: herdr writes its own state (release-notes.json
	# and the like) next to HERDR_CONFIG_PATH, which would land in the repo.
	mkdir -p "$WORK/config"
	cp "$REPO/herdr/.config/herdr/config.toml" "$WORK/config/config.toml"
	tm respawn-pane -k -t t "cd '$REPO' && COLORTERM=truecolor NO_AUTO_TMUX=1 \
HERDR_CONFIG_PATH='$WORK/config/config.toml' herdr --session $SESSION; \
echo EXIT=\$?; sleep 3600"
	for _ in $(seq 1 20); do
		[[ -S $SOCK ]] && h pane list >/dev/null 2>&1 && return 0
		sleep 0.5
	done
	echo "herdr did not start; see: tmux -L herdr-harness attach" >&2
	return 1
}

# statusline PANE MODEL CTX% TITLE CWD — feed a status line payload.
statusline() {
	jq -n --arg m "$2" --argjson c "$3" --arg t "$4" --arg d "$5" '{
		workspace: {current_dir: $d}, model: {display_name: $m},
		context_window: {used_percentage: $c}, session_name: $t,
		rate_limits: {
			five_hour: {used_percentage: 29, resets_at: (now + 3600 | floor)},
			seven_day: {used_percentage: 8, resets_at: (now + 86400 | floor)}}}' |
		HERDR_ENV=1 HERDR_PANE_ID=$1 HERDR_SOCKET_PATH=$SOCK HERDR_BIN_PATH=herdr \
		XDG_CACHE_HOME=$WORK/cache \
			bash "$REPO/claude/.claude/statusline.sh" >/dev/null
}

# hook PANE JSON — fire a Claude Code hook event.
hook() {
	HERDR_ENV=1 HERDR_PANE_ID=$1 HERDR_SOCKET_PATH=$SOCK HERDR_BIN_PATH=herdr \
		XDG_CACHE_HOME=$WORK/cache \
		bash "$REPO/claude/.claude/hooks/herdr-status.sh" <<<"$2"
}

populate() {
	local p1 p2 p3
	p1=$(h pane list | jq -r '.result.panes[0].pane_id')
	p2=$(h workspace create --cwd "$HOME" --label waiting --no-focus | jq -r '.result.root_pane.pane_id')
	p3=$(h workspace create --cwd "$HOME" --label working --no-focus | jq -r '.result.root_pane.pane_id')
	h pane run "$p1" "$WORK/bin/claude" >/dev/null
	h pane run "$p2" "$WORK/bin-prompt/claude" >/dev/null
	h pane run "$p3" "$WORK/bin/claude" >/dev/null
	sleep 2 # let herdr detect the agents
	statusline "$p1" "Opus 5.5 (1M context)" 26 "Analiza testów w repozytoriach" "$REPO"
	statusline "$p2" "Sonnet 4.6" 100 "Refactor forecast ingestion pipeline and retry policy" "$HOME"
	statusline "$p3" "Fable 5.1" 85 "Fix flaky settlement tests" "$HOME"
	hook "$p1" '{"hook_event_name":"Stop"}'
	hook "$p2" '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"npm run migrate","description":"Check comment-back on source PR before merging"}}'
	hook "$p3" '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"x","description":"Find state label handling in herdr sidebar source"}}'
	# herdr needs about a second to classify the prompt as blocked.
	local status
	for _ in $(seq 1 20); do
		status=$(h agent list | jq -r --arg p "$p2" '.result.agents[] | select(.pane_id == $p) | .agent_status')
		[[ $status == blocked ]] && break
		sleep 0.5
	done
	[[ $status == blocked ]] || echo "warning: prompt pane is '$status', not blocked" >&2
	sleep 0.5 # let the plugin swap the status row
}

render() {
	local out=${1:-$WORK/sidebar.png}
	tm capture-pane -e -p -t t >"$WORK/capture.txt"
	python3 "$HERE/render.py" "$out" 44 <"$WORK/capture.txt"
	echo "$out"
}

case ${1:-} in
	start) start "${2:-40}" ;;
	populate) populate ;;
	approve) pkill -USR1 -f "$WORK/bin-prompt/claude"; sleep 2 ;;
	render) render "${2:-}" ;;
	stop) stop ;;
	*) sed -n '2,17p' "$0" >&2; exit 2 ;;
esac

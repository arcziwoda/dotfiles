#!/usr/bin/env bash
# Custom tokens for herdr's Spaces panel, next to the built-in branch and
# ahead/behind counts:
#
#   $dirty  uncommitted work in the workspace's repo, in starship's notation:
#           +staged !modified ?untracked, e.g. "!3 ?1"
#   $pr     pull request of the checked-out branch: CI icon, number, review
#           state, e.g. "<check> #88 approved"; none on the default branch
#
# herdr computes no custom workspace tokens, so they are pushed with
# `herdr workspace report-metadata`, on events rather than by polling:
#
#   startup          plugin [[startup]]: forget the cache, refresh everything
#   focus            workspace.focused: $dirty of every workspace, $pr of those
#                    not looked up in the last PR_TTL seconds
#   agent            pane.agent_status_changed: $dirty of the pane's workspace
#                    once its agent stops working
#   shell PANE_ID WS zsh precmd (~/.config/zsh/herdr-space.zsh): $dirty of the
#                    pane's workspace after every command
#
# A workspace's repo is its herdr worktree checkout, otherwise the working
# directory of the first pane in its active tab. Values are cached per
# workspace and reported only when they change, because herdr handles
# report-metadata on its UI thread.
set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
LC_ALL=en_US.UTF-8

herdr=${HERDR_BIN_PATH:-herdr}
STATE_ROOT=${XDG_STATE_HOME:-$HOME/.local/state}/herdr-space-status
# Workspace ids repeat across herdr sessions, so the cache is per server.
STATE=$STATE_ROOT/$(cksum <<<"${HERDR_SOCKET_PATH:-default}" | cut -d' ' -f1)
PR_TTL=120 # seconds between pull request lookups per workspace
SOURCE=dotfiles:space-status

# Nerd Font icons as UTF-8 bytes (bash 3.2 has no \u): U+F00C check, U+F00D
# times, U+F017 clock, U+F071 warning, U+F407 pull request, U+F419 merge.
CHECK=$'\xef\x80\x8c' TIMES=$'\xef\x80\x8d' CLOCK=$'\xef\x80\x97'
WARN=$'\xef\x81\xb1' PR=$'\xef\x90\x87' MERGE=$'\xef\x90\x99'

mode=${1:-}
mkdir -p "$STATE"

# report WS NAME VALUE: set (or clear, when empty) a token if it changed.
report() {
	local cache="$STATE/$1.$2" old=''
	[[ -f $cache ]] && old=$(<"$cache")
	[[ $3 == "$old" && -f $cache ]] && return 0
	if [[ -n $3 ]]; then
		"$herdr" workspace report-metadata "$1" --source "$SOURCE" --token "$2=$3" >/dev/null 2>&1
	else
		"$herdr" workspace report-metadata "$1" --source "$SOURCE" --clear-token "$2" >/dev/null 2>&1
	fi && printf '%s' "$3" >"$cache"
}

# dirty DIR: "+staged !modified ?untracked", only the non-zero parts.
dirty() {
	[[ -n $1 ]] || return 0 # git -C '' would use the plugin's own directory
	git -C "$1" --no-optional-locks status --porcelain 2>/dev/null | awk '
		/^\?\?/ { u++; next }
		{ if (substr($0, 1, 1) != " ") s++; if (substr($0, 2, 1) != " ") m++ }
		END {
			out = ""
			if (s) out = out " +" s
			if (m) out = out " !" m
			if (u) out = out " ?" u
			print substr(out, 2)
		}'
}

# lookup_pr ACCOUNT...: as each account in turn, look up the PR of $branch in
# $repo; on success remember the account in $acache and leave the PR in $json
# (empty when the branch has none). Fails when no account can read the repo.
lookup_pr() {
	local account token
	for account in "$@"; do
		token=$(gh auth token --user "$account" 2>/dev/null) || continue
		if json=$(GH_TOKEN=$token gh pr view "$branch" -R "$repo" \
			--json number,state,isDraft,reviewDecision,statusCheckRollup 2>&1); then
			printf '%s' "$account" >"$acache"
			return 0
		fi
		if [[ $json == *"no pull requests found"* ]]; then
			json=''
			printf '%s' "$account" >"$acache"
			return 0
		fi
	done
	json=''
	return 1
}

# pr DIR: the pull request line for the branch checked out in DIR, if any.
pr() {
	local dir=$1 branch url repo base accounts json acache
	[[ -n $dir ]] || return 0
	branch=$(git -C "$dir" branch --show-current 2>/dev/null)
	[[ -n $branch ]] || return 0
	base=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
	base=${base#origin/}
	case $branch in "${base:-main}" | main | master) return 0 ;; esac

	# owner/repo from the origin URL; the host may be an SSH alias
	# (git@github-work:owner/repo.git), so it is not passed to gh.
	url=$(git -C "$dir" remote get-url origin 2>/dev/null) || return 0
	[[ $url == *github* ]] || return 0
	repo=${url%.git}
	repo=${repo#*github*[:/]}
	[[ $repo == */* ]] || return 0

	# gh uses the active account; with several logged in, the repo may need
	# another one. Try the one that worked last time; list all accounts only
	# when that fails (`gh auth status` checks every token over the network).
	local acache="$STATE_ROOT/account.${repo//\//_}"
	accounts=$(cat "$acache" 2>/dev/null)
	if ! lookup_pr $accounts; then
		accounts=$(gh auth status --json hosts 2>/dev/null | jq -r '.hosts["github.com"][]?.login')
		lookup_pr $accounts || return 0
	fi
	[[ -n $json ]] || return 0

	jq -r --arg check "$CHECK" --arg times "$TIMES" --arg clock "$CLOCK" \
		--arg warn "$WARN" --arg pr "$PR" --arg merge "$MERGE" '
		([.statusCheckRollup[]? |
			if .__typename == "StatusContext" then .state
			elif .status != "COMPLETED" then "PENDING"
			else .conclusion end]) as $checks
		| (if any($checks[]; IN("FAILURE", "ERROR", "CANCELLED", "TIMED_OUT",
				"ACTION_REQUIRED", "STARTUP_FAILURE")) then "fail"
			elif any($checks[]; IN("PENDING", "EXPECTED")) then "pending"
			elif ($checks | length) > 0 then "pass"
			else "none" end) as $ci
		| "#\(.number)" as $n
		| if .state == "MERGED" then "\($merge) \($n) merged"
		  elif .state == "CLOSED" then "\($pr) \($n) closed"
		  else
			(if $ci == "fail" then $times
			 elif .reviewDecision == "CHANGES_REQUESTED" then $warn
			 elif $ci == "pending" then $clock
			 elif $ci == "pass" then $check
			 else $pr end) as $icon
			| (if .isDraft then "draft"
			   elif .reviewDecision == "APPROVED" then "approved"
			   elif .reviewDecision == "CHANGES_REQUESTED" then "changes"
			   elif .reviewDecision == "REVIEW_REQUIRED" then "review"
			   else "" end) as $word
			| "\($icon) \($n) \($word)" | rtrimstr(" ")
		  end' <<<"$json"
}

# Lines "WORKSPACE_ID<TAB>DIR", or only the workspace of pane $1 when given.
workspaces() {
	jq -rn --arg pane "${1:-}" \
		--argjson ws "$("$herdr" workspace list 2>/dev/null || echo '{}')" \
		--argjson panes "$("$herdr" pane list 2>/dev/null || echo '{}')" '
		($panes.result.panes // []) as $p
		| ($p | map(select(.pane_id == $pane)) | first.workspace_id) as $only
		| $ws.result.workspaces[]?
		| select($pane == "" or .workspace_id == $only)
		| .active_tab_id as $tab
		| [.workspace_id, (.worktree.checkout_path
			// ($p | map(select(.tab_id == $tab)) | first | .foreground_cwd // .cwd)
			// "")]
		| @tsv'
}

refresh_dirty() { report "$1" dirty "$(dirty "$2")"; }

# refresh_dirty_of PANE_ID [WORKSPACE_ID]: $dirty of the pane's workspace. The
# workspace's repo comes from the last full pass when known, which keeps this
# path (run after every shell command) free of herdr calls unless the value
# changed.
refresh_dirty_of() {
	local ws=${2:-} dir
	if [[ -n $ws && -f $STATE/$ws.dir ]]; then
		refresh_dirty "$ws" "$(<"$STATE/$ws.dir")"
		return
	fi
	while IFS=$'\t' read -r ws dir; do refresh_dirty "$ws" "$dir"; done < <(workspaces "$1")
}

# pr_due WS: true when the workspace's PR was last looked up PR_TTL seconds
# ago or more; stamps it as looked up now.
pr_due() {
	local stamp="$STATE/$1.prstamp" last=0
	[[ -f $stamp ]] && last=$(<"$stamp")
	((now - last >= PR_TTL)) || return 1
	printf '%s' "$now" >"$stamp"
}

# One full pass at a time; focus events arrive in bursts while switching.
lock() {
	local dir="$STATE/lock"
	find "$dir" -maxdepth 0 -mmin +1 -exec rmdir {} \; 2>/dev/null
	mkdir "$dir" 2>/dev/null || exit 0
	trap 'rmdir "$STATE/lock" 2>/dev/null' EXIT
}

case $mode in
	startup | focus)
		lock
		[[ $mode == startup ]] && rm -f "$STATE"/*.*
		live=' ' now=$(date +%s)
		while IFS=$'\t' read -r ws dir; do
			live+="$ws "
			printf '%s' "$dir" >"$STATE/$ws.dir"
			# Side by side: git status costs 10-100 ms per repo and PR
			# lookups go over the network.
			{
				refresh_dirty "$ws" "$dir"
				pr_due "$ws" && report "$ws" pr "$(pr "$dir")"
			} &
		done < <(workspaces)
		wait
		# Forget closed workspaces, so a reused id starts clean.
		for f in "$STATE"/*.dir "$STATE"/*.dirty "$STATE"/*.pr "$STATE"/*.prstamp; do
			[[ -e $f ]] || continue
			ws=${f##*/}
			[[ $live == *" ${ws%.*} "* ]] || rm -f "$f"
		done
		;;
	agent)
		[[ -n ${HERDR_PLUGIN_EVENT_JSON:-} ]] || exit 0
		{
			IFS= read -r pane
			IFS= read -r ws
			IFS= read -r status
		} < <(jq -r '.data // . | (.pane_id // ""), (.workspace_id // ""), (.agent_status // "")' \
			<<<"$HERDR_PLUGIN_EVENT_JSON")
		[[ -n $pane && $status != working ]] || exit 0
		refresh_dirty_of "$pane" "$ws"
		;;
	shell)
		[[ -n ${2:-} ]] || exit 0
		refresh_dirty_of "$2" "${3:-}"
		;;
	*)
		echo "usage: refresh.sh startup|focus|agent|shell PANE_ID [WORKSPACE_ID]" >&2
		exit 2
		;;
esac
exit 0

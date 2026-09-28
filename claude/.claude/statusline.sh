#!/usr/bin/env bash
# Claude Code status line, styled to match the starship prompt.
#
# Renders:  <path>   <branch> <flags>   <model>   ctx <n>%   5h <n>%
#
# Claude Code passes a JSON object on stdin; see
# https://docs.claude.com/en/docs/claude-code/statusline
# Git state is not part of that payload, so it is read here directly.
set -uo pipefail

# The status line runs with whatever PATH Claude Code inherited, which is not
# guaranteed to include Homebrew.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

input=$(cat)

# ── Catppuccin Macchiato ───────────────────────────────────────────────
lavender=$'\033[1;38;2;183;189;248m'
mauve=$'\033[1;38;2;198;160;246m'
red=$'\033[38;2;237;135;150m'
peach=$'\033[38;2;245;169;127m'
yellow=$'\033[38;2;238;212;159m'
green=$'\033[38;2;166;218;149m'
blue=$'\033[38;2;138;173;244m'
dim=$'\033[38;2;110;115;141m'
reset=$'\033[0m'

# Colour a percentage by how alarming it is.
pct_colour() {
	local p=${1%%.*}
	if ((p >= 90)); then printf '%s' "$red"
	elif ((p >= 75)); then printf '%s' "$peach"
	elif ((p >= 50)); then printf '%s' "$yellow"
	else printf '%s' "$green"
	fi
}

# Full path, with everything past five components collapsed into "…/" — the
# same rule as the directory module in starship.toml.
prettify_path() {
	local p=$1
	[[ -z $p ]] && return
	[[ $p == "$HOME" ]] && { printf '~'; return; }
	p=${p/#$HOME/\~}
	local -a parts
	IFS='/' read -r -a parts <<<"$p"
	if ((${#parts[@]} > 5)); then
		printf '…/%s' "$(IFS=/; printf '%s' "${parts[*]: -5}")"
	else
		printf '%s' "$p"
	fi
}

# Branch plus a compact dirty indicator: + staged, ! modified, ? untracked.
# --no-optional-locks keeps a status line that runs on every message from
# fighting a real git command for the index lock.
git_segment() {
	local dir=$1 branch status flags=''
	git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
	branch=$(git -C "$dir" --no-optional-locks symbolic-ref --quiet --short HEAD 2>/dev/null) ||
		branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null) || return

	status=$(git -C "$dir" --no-optional-locks status --porcelain=v1 2>/dev/null)
	if [[ -n $status ]]; then
		grep -q '^[MADRC]' <<<"$status" && flags+='+'
		grep -q '^.[MD]' <<<"$status" && flags+='!'
		grep -q '^??' <<<"$status" && flags+='?'
	fi

	printf ' %s %s%s' "$mauve" "$branch" "$reset"
	[[ -n $flags ]] && printf ' %s[%s]%s' "$red" "$flags" "$reset"
}

# ── Read the payload ───────────────────────────────────────────────────
# Missing or null values become -1 so they can be skipped rather than shown as
# 0%: rate_limits is absent for non-subscribers, and the context figures are
# null until the first API call of a session.
#
# One value per line, not @tsv: tab counts as IFS whitespace, so `read` would
# collapse consecutive tabs and shift every field left when a value is empty.
{
	IFS= read -r cwd
	IFS= read -r model
	IFS= read -r ctx
	IFS= read -r five
	IFS= read -r five_reset
	IFS= read -r seven
	IFS= read -r seven_reset
	IFS= read -r session_name
	IFS= read -r added
	IFS= read -r removed
} < <(
	jq -r '
		(.workspace.current_dir // .cwd // ""),
		(.model.display_name // ""),
		(.context_window.used_percentage // -1),
		(.rate_limits.five_hour.used_percentage // -1),
		(.rate_limits.five_hour.resets_at // -1),
		(.rate_limits.seven_day.used_percentage // -1),
		(.rate_limits.seven_day.resets_at // -1),
		(.session_name // "" | gsub("[\n\r]"; " ")),
		(.cost.total_lines_added // 0),
		(.cost.total_lines_removed // 0)
	' <<<"$input"
)

# Percentages arrive as numbers or null; reduce to a plain integer, or -1 when
# there is nothing usable to show.
as_int() {
	local v=${1%%.*}
	if [[ $v =~ ^-?[0-9]+$ ]]; then printf '%s' "$v"; else printf '%s' -1; fi
}
ctx=$(as_int "${ctx:-}")
five=$(as_int "${five:-}")
five_reset=$(as_int "${five_reset:-}")
seven=$(as_int "${seven:-}")
seven_reset=$(as_int "${seven_reset:-}")
added=$(as_int "${added:-}")
removed=$(as_int "${removed:-}")

# ── Account quota cache ────────────────────────────────────────────────
# Rate limits are per account, not per session, so they are written once for
# whatever wants them outside Claude Code (herdr's tab bar reads this through
# ~/.config/herdr/claude-quota.sh). Written via rename so a reader never sees
# a half-written file.
if ((five >= 0 || seven >= 0)); then
	quota_file="${XDG_CACHE_HOME:-$HOME/.cache}/claude/rate-limits"
	mkdir -p "${quota_file%/*}" 2>/dev/null &&
		printf '%s %s %s %s\n' "$five" "$five_reset" "$seven" "$seven_reset" >"$quota_file.$$" &&
		mv -f "$quota_file.$$" "$quota_file"
fi

# ── herdr sidebar ──────────────────────────────────────────────────────
# Inside a herdr pane, publish per-session values as pane metadata; the
# sidebar layout in herdr's config.toml decides where and how they show.
# An empty value clears its token.
if [[ ${HERDR_ENV:-} == 1 && -n ${HERDR_PANE_ID:-} ]]; then
	# The leading glyph encodes the level so herdr's starts_with colour rules
	# can match on it (they cannot compare a number followed by text).
	ctx_token=''
	if ((ctx >= 0)); then
		if ((ctx >= 90)); then glyph='●'
		elif ((ctx >= 75)); then glyph='◕'
		elif ((ctx >= 50)); then glyph='◑'
		elif ((ctx >= 25)); then glyph='◔'
		else glyph='○'
		fi
		ctx_token="$glyph ctx ${ctx}%"
	fi
	diff_token=''
	((added > 0 || removed > 0)) && diff_token="+${added} −${removed}"

	"${HERDR_BIN_PATH:-herdr}" pane report-metadata "$HERDR_PANE_ID" \
		--source dotfiles:claude-statusline \
		--token "task=$session_name" \
		--token "model=${model%% (*}" \
		--token "ctx=$ctx_token" \
		--token "diff=$diff_token" \
		>/dev/null 2>&1
fi

# ── Compose ────────────────────────────────────────────────────────────
out="${lavender}$(prettify_path "$cwd")${reset}"

[[ -n $cwd ]] && out+="$(git_segment "$cwd")"

[[ -n $model ]] && out+="  ${blue}${model}${reset}"

((ctx >= 0)) && out+="  ${dim}ctx ${reset}$(pct_colour "$ctx")${ctx}%${reset}"
((five >= 0)) && out+="  ${dim}5h ${reset}$(pct_colour "$five")${five}%${reset}"

printf '%s\n' "$out"

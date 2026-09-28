#!/bin/sh
# herdr tab bar status entry: Claude account quota, e.g. "5h 23%  14:30 · 7d 41%".
#
# Claude Code's status line (~/.claude/statusline.sh) caches the rate limits
# it receives; this only reads that cache. A window whose reset time has passed
# is skipped, because its percentage no longer means anything. Prints nothing
# when there is no usable data, which hides the entry.
cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude/rate-limits"
[ -r "$cache" ] || exit 0
read -r five five_reset seven seven_reset <"$cache" || exit 0
now=$(date +%s)

out=''
if [ "${five:--1}" -ge 0 ] 2>/dev/null && [ "${five_reset:-0}" -gt "$now" ] 2>/dev/null; then
	out="5h ${five}%  $(date -r "$five_reset" +%H:%M)"  # U+F017 Nerd Font clock
fi
if [ "${seven:--1}" -ge 0 ] 2>/dev/null && [ "${seven_reset:-0}" -gt "$now" ] 2>/dev/null; then
	out="${out:+$out · }7d ${seven}%"
fi
[ -n "$out" ] && printf '%s\n' "$out"
exit 0

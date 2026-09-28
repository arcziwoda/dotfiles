#!/usr/bin/env bash
# Claude Code SessionStart hook: when the session starts inside a linked git
# worktree (e.g. one created by herdr with prefix G), tell Claude so. Stdout of
# a SessionStart hook becomes session context; everywhere else — the main
# checkout, a non-git directory — this prints nothing, so it adds nothing.
#
# Worktrees Claude Code creates itself (.claude/worktrees/, via --worktree or
# EnterWorktree) are skipped: Claude already knows about those and enforces
# isolation for them.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[[ -n $cwd ]] || cwd=$PWD

# One git call answers "is this a linked worktree": there the per-worktree git
# dir differs from the shared one. Needs git 2.31+ for --path-format.
{
	IFS= read -r git_dir
	IFS= read -r common_dir
	IFS= read -r top
} < <(git -C "$cwd" rev-parse --path-format=absolute --git-dir --git-common-dir --show-toplevel 2>/dev/null)
[[ -n ${git_dir:-} && -n ${common_dir:-} && $git_dir != "$common_dir" ]] || exit 0
[[ $top == */.claude/worktrees/* ]] && exit 0

# The main checkout is the first entry of `git worktree list`.
main=$(git -C "$top" worktree list --porcelain | sed -n '1s/^worktree //p')
branch=$(git -C "$top" symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=''

# Default branch, for "branched from". origin/HEAD when the remote has one,
# otherwise whichever of main/master exists locally.
default=$(git -C "$top" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
if [[ -z $default ]]; then
	for candidate in main master; do
		git -C "$top" show-ref --verify --quiet "refs/heads/$candidate" && default=$candidate && break
	done
fi
ahead=''
[[ -n $default ]] && ahead=$(git -C "$top" rev-list --count "$default..HEAD" 2>/dev/null)

# Gitignored top-level entries the main checkout has and this one lacks —
# typically .env files, virtualenvs and node_modules. Top level only, so this
# stays fast even in large repositories.
missing=()
while IFS= read -r -d '' path; do
	name=${path##*/}
	[[ -e "$top/$name" ]] && continue
	git -C "$main" check-ignore --quiet -- "$name" 2>/dev/null && missing+=("$name")
done < <(find "$main" -mindepth 1 -maxdepth 1 ! -name .git -print0 2>/dev/null)

echo "This session runs in a linked git worktree, not the main checkout."
echo "- Worktree: $top"
if [[ -n $branch ]]; then
	echo "- Branch: $branch${default:+ (branched from $default${ahead:+, $ahead commit(s) ahead})}. Commit here; do not check out other branches in this worktree."
else
	echo "- HEAD is detached; create a branch before committing work you want to keep."
fi
echo "- Main checkout: $main — another session may be working there. Do not edit files in it, cd into it, or point git at it (git -C, --git-dir)."
if ((${#missing[@]})); then
	echo "- Gitignored files from the main checkout are not present here: ${missing[*]}. Ask before copying secrets such as .env; recreate environments (e.g. uv sync, npm install) instead of symlinking them."
fi

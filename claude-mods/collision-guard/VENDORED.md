# collision-guard (vendored)

Source: https://github.com/nateherkai/claude-code-mods, folder `collision-guard/`,
commit `33a936f2ec6bbfea5a30a1a4d71d992487a5c769` (2026-10-02). MIT, see `LICENSE`.
Copied unchanged. Update only by re-auditing a newer commit and replacing the files.

Audit (2026-11-03, static review):

- Hooks: `session.start`, `session.end`, `prompt.submit`, `tool.call` (Edit, Write,
  NotebookEdit), `command.run` (`/guard`). None is bypassed by `cc-plugin-sec-default`.
- Writes only `~/.claude/mods-data/collision-guard/<sessionId>.json`: session id, cwd,
  absolute paths of edited files with timestamps, and the first 80 characters of the
  first prompt as the chat title. Ledgers are never deleted, only emptied on session end.
- Runs one process: `git -C <cwd> ls-files --error-unmatch -- <file>` (argv, no shell).
- No network, telemetry, dynamic import or self-update. No dependencies or build step.
- Most of `coach.mjs` and all of `pricing.mjs` are dead code; only `normPath` and
  `chatName` are used.

Known limits:

- Edits made through Bash (sed, heredocs) are neither recorded nor checked.
- Paths are compared as strings without realpath, so `~/.zshrc` and
  `~/dotfiles/zsh/.zshrc` (Stow symlink) count as different files.
- An edit is recorded before the permission prompt, so a denied edit still shows up as a
  collision for other sessions.
- When it refuses an edit, the other chat's title is shown to this chat's model.

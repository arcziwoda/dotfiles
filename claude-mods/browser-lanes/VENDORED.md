# browser-lanes (vendored)

Source: https://github.com/hamzafer/claude-code-mods, folder `mods/browser-lanes/` (v0.1.3),
repo commit `5cef0d32daad002b7936920e47a317fd2fd066f0` (2026-11-01; the folder last changed
in `e839261`, 2026-10-15). MIT, see `LICENSE`. Copied unchanged.
Update only by re-auditing a newer commit and replacing the files.

Pairs with `PLAYWRIGHT_MCP_ISOLATED=true` in the `env` of `claude/.claude/settings.json`:
every session's Playwright MCP then runs an in-memory profile, which removes the
"Browser is already in use" conflict on the shared profile (logins do not persist
between sessions). The mod itself never changes MCP config; it shows who holds which
browser (band above the prompt, `/browser`), queues subagents for the browser and
prefixes screenshot names with the session label.

Audit (2026-11-03, static review):

- Hooks: `session.start`, `session.end`, `command.run`, `agent.spawn`, `tool.call`,
  `turn.complete`, `ui.render` (AbovePrompt). Only `agent.spawn` is bypassed by
  `cc-plugin-sec-default` on this account, so subagents are labelled `agent-<id6>`
  instead of their task name.
- Processes: `ps -axo`, `lsof -d cwd` on other Claude pids, and SIGTERM to Chrome
  processes whose parent is a playwright-mcp node server. It kills without asking only
  this session's own Chrome at session end (also on `/clear`); `/browser clean` asks
  first, and its "Close all" can also close Playwright browsers started by other tools.
- Files: reads `~/.claude/claude-code-mods/bands.json`; writes nothing. State in `$.store`.
- No network, telemetry, eval or self-update. No dependencies or build step.
- The band reports "Not isolated" even with the env var set, because detection reads
  only the MCP's argv. Cosmetic.

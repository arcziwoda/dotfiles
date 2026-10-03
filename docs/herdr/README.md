# herdr + Claude Code integration

[herdr](https://herdr.dev) is on trial next to tmux (`mux herdr` / `mux tmux`
picks what new terminal windows start in). This page is the map of everything
built around it: what each piece does, how data flows into herdr's sidebar,
the constraints that shaped the design, how to test visual changes, and what
to check when herdr is upgraded. Short gotchas live in the root `CLAUDE.md`;
the key map is in the root `README.md`.

Written against herdr 0.9.1–0.9.3 and Claude Code v2.1.2xx.

## What the sidebar shows

For every Claude Code pane, the agent list renders (herdr `config.toml`,
`[ui.sidebar.agents.rows_by_agent].claude`):

```
◐ dotfiles · 2                       state icon, workspace, tab
  Refactor forecast ingestion        $task   session title, wrapped
  pipeline and retry policy          $task2  at a word boundary
   Bash: Check comment-back on      state_text  waiting / working / done
  source PR before merging           $status2b or $status2w (continuation)
  Sonnet 4.6 · ━━━━━━━─ 85%          $model + $ctx (8-cell context bar)
```

The right end of the tab bar shows the account quota: `5h 29%  14:50 · 7d 8%`.

Each workspace in the Spaces panel (`[ui.sidebar.spaces]`) gets a third row
from the `dotfiles.space-status` plugin:

```
◐ vpp                                state icon, workspace
  feat/forecast · ↑2                 branch, ahead/behind (herdr built-ins)
  !3 ?1 ·  #88 approved             $dirty (+staged !modified ?untracked), $pr
```

## Pieces

| File | Role |
|---|---|
| `herdr/.config/herdr/config.toml` | Keymap (tmux-like), Macchiato theme overrides, sidebar row layout and colour rules, tab-bar quota entry, plugin key bindings |
| `claude/.claude/statusline.sh` | Claude Code status line. Inside herdr also publishes `$task`, `$task2`, `$model`, `$ctx` and writes the quota cache |
| `claude/.claude/hooks/herdr-status.sh` | Claude Code hook (see below). Publishes the status as herdr **state labels** plus `$status2w`/`$status2b`/`$tailw`/`$tailb` |
| `herdr/.config/herdr/local-plugins/claude-status/` | Our herdr plugin (`dotfiles.claude-status`). On `pane.agent_status_changed` copies the right tail into `$status2w` or `$status2b` |
| `herdr/.config/herdr/local-plugins/space-status/` | Our herdr plugin (`dotfiles.space-status`). Reports `$dirty` and `$pr` per workspace on startup, `workspace.focused` and `pane.agent_status_changed`; see the header of `refresh.sh` |
| `zsh/.config/zsh/herdr-space.zsh` | `precmd` inside herdr: refreshes `$dirty` of the pane's workspace after every command, in the background |
| `herdr/.config/herdr/claude-quota.sh` | Tab-bar `command` entry. Reads `~/.cache/claude/rate-limits` (written by `statusline.sh`) |
| `claude/.claude/hooks/worktree-context.sh` | `SessionStart` hook: in a linked git worktree (e.g. herdr `prefix G`), tells Claude its branch, the main checkout to leave alone, and which gitignored files are missing. Silent elsewhere |
| `~/.claude/hooks/herdr-agent-state.sh` | **herdr's** Claude integration (`herdr integration install claude`, run by `bootstrap.sh`, not in the repo). Reports the session id so herdr resumes the conversation after a server restart |
| `claude/.claude/skills/herdr/SKILL.md` | Output of `herdr --skill`: lets Claude drive herdr panes. Regenerate after upgrades |
| `herdr/.config/herdr/plugins/config/<id>/config.toml` | Configs of third-party plugins (`herdr-navigator`, `persiyanov.reviewr`) |
| `bin/.local/bin/mux`, `zsh/.config/zsh/sesh.zsh` | Multiplexer switch and terminal-start logic |

Hooks registered in `claude/.claude/settings.json`:

| Event | Matcher | Script |
|---|---|---|
| `SessionStart` | `startup\|resume\|clear\|compact\|fork` | herdr's `herdr-agent-state.sh` (exact string herdr matches on reinstall; do not edit) |
| `SessionStart` | all | `herdr-status.sh` (clears labels) |
| `SessionStart` | `startup\|resume\|clear\|compact` | `worktree-context.sh` |
| `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Stop`, `SessionEnd` | all | `herdr-status.sh` |
| `PostToolUse` | `AskUserQuestion\|ExitPlanMode` | `herdr-status.sh` (reset after the question or plan is answered) |

## Data flow

```
Claude Code ──status line JSON──▶ statusline.sh ──report-metadata──▶ $task $task2 $model $ctx
     │                                   └──▶ ~/.cache/claude/rate-limits ──▶ claude-quota.sh ──▶ tab bar
     └──hook JSON──▶ herdr-status.sh ──report-metadata──▶ state labels (per state)
                                                   └──▶ $tailw $tailb, $status2w | $status2b
herdr screen detection ──pane.agent_status_changed──▶ claude-status plugin ──▶ $status2w | $status2b
```

All reports use `herdr pane report-metadata $HERDR_PANE_ID`, with source
`dotfiles:claude-statusline` (status line) or `dotfiles:claude-hooks` (hook and
plugin). Everything is a no-op unless `HERDR_ENV=1`, so the same scripts run
harmlessly under tmux.

### Why state labels

The status (`<warn> waiting`, `<cog> working`, `<check> 14:32`) is not a
plain token. The hook sets a label for **every** herdr state in one call:
warning text for `blocked`, activity text for the rest. herdr shows the label
of the state it currently detects from the screen, so when a permission prompt
is answered the row flips from warning to activity immediately. Claude Code has
no "permission granted" hook event, so a plain token would stay on the warning
until the next event. The `state_text` rules in `config.toml` hide herdr's
default `idle`/`working`/`done` words shown before the first hook event.

### Why two continuation tokens and a plugin

A long status wraps into a second row. Plain tokens cannot depend on the
state, so that row exists twice: `$status2w` (activity colour) and `$status2b`
(warning colour), only one non-empty. The hook stores both tails (`$tailw`,
`$tailb`, not rendered) and shows the one matching the state its event implies;
the plugin swaps them on each state change herdr detects.

### Spaces panel tokens

herdr has no per-workspace equivalent of the status line, and plugin startup
hooks are one-shot, not daemons, so `$dirty` and `$pr` are pushed on events
instead of polled:

| Trigger | Refreshes | Cost (measured with 16 workspaces) |
|---|---|---|
| zsh `precmd` in a herdr pane | `$dirty` of that workspace | +1.9 ms per prompt (the background fork); ~10 ms in the background; no herdr call unless the value changed |
| `workspace.focused` | `$dirty` of all workspaces, `$pr` of those not looked up in the last 2 min | ~65 ms in the background, ~2 ms herdr server CPU |
| `pane.agent_status_changed` (not to `working`) | `$dirty` of that workspace | as `precmd` |
| plugin startup | everything, cache cleared | one focus pass |

A workspace's repo is its herdr worktree checkout, else the cwd of the first
pane in its active tab. Values are cached per herdr server under
`~/.local/state/herdr-space-status/` and reported only on change.

`$pr` skips the default branch. It calls `gh pr view <branch> -R owner/repo`
(SSH host aliases in `origin` are not passed to gh) with each logged-in gh
account in turn and remembers the one that can read the repo; a lookup takes
~0.85 s with the account known, ~3 s the first time (`gh auth status` checks
every token).

To switch it off: `herdr plugin disable dotfiles.space-status`. To remove it:
revert its commit, `herdr plugin unlink dotfiles.space-status`,
`stow -R herdr zsh`, `herdr server reload-config`, and delete
`~/.local/state/herdr-space-status`.

## Constraints that shaped the layout

- **Widths.** The sidebar is 34 columns (`ui.sidebar_width`). After the row
  indent that leaves 30 columns, and 29 once the agent list overflows and herdr
  takes a column for its scrollbar. Titles and statuses wrap at 29; model (10)
  + separator (3) + bar (8) + `100%` (4) = 25 fits.
- **Character counting.** Scripts set `LC_ALL=en_US.UTF-8` so `${#var}` counts
  characters; Polish letters would otherwise count double. macOS runs these
  under `/bin/bash` 3.2: no `\u` escapes in `$'...'` (use UTF-8 bytes), no
  `EPOCHREALTIME`.
- **Glyphs.** Only characters JetBrains Mono Nerd Font has; anything else
  (`◐◑↻▰⚙`) is drawn by Ghostty from a fallback font. Status icons are Nerd
  Font PUA: U+F071 warning, U+F013 cog, U+F00C check; U+F017 clock in the tab
  bar.
- **Zero-width spaces (U+200B).** herdr trims whitespace from token values but
  keeps U+200B and does not draw it. Used twice: to end the padded `$model`
  (otherwise trailing spaces vanish and the bar shifts), and as a 1–4 character
  prefix on `$ctx` encoding the colour level, because `starts_with` rules are
  the only way to colour by value (50/80/90% do not fall on whole cells of an
  8-cell bar).
- **Colours are per token.** A token has one colour; rules match only the
  token's own text. The tab-bar status entry has no style option at all, so
  the quota is made readable by raising the theme's `overlay1` (herdr's colour
  for that entry) to Macchiato subtext1.
- **Cost.** `herdr-status.sh` runs synchronously before every tool call. Keep
  it to one `jq` and one `herdr` call (about 8 ms).
- **No self-written settings.** Tools that rewrite `settings.json` by
  temp-file + rename break the Stow symlink. herdr's own integration writes
  through the symlink; `levi-qiao/herdr-agent-usage` does not, which is why it
  was rejected and replaced by the pieces above.

## Testing visual changes

Look at a render, not at plain text: `docs/herdr/harness/harness.sh` runs the
repo config in an isolated herdr session inside a private tmux server, with
three fake `claude` agents (finished, waiting on a real-looking permission
prompt that herdr classifies as `blocked`, working) fed by the real
`statusline.sh` and `herdr-status.sh`, and renders the screen to PNG with the
real font and palette.

```sh
docs/herdr/harness/harness.sh start        # or: start 24  (forces the scrollbar)
docs/herdr/harness/harness.sh populate
docs/herdr/harness/harness.sh render       # prints the PNG path
docs/herdr/harness/harness.sh approve      # prompt disappears; status must flip
docs/herdr/harness/harness.sh render
docs/herdr/harness/harness.sh stop
```

It is safe from a Claude Code session running inside herdr: all calls drop
the inherited `HERDR_*` variables, so nothing touches the live session. When
testing by hand, do the same (`env -u HERDR_ENV -u HERDR_SOCKET_PATH …`).

## Upgrading herdr

`brew upgrade herdr` replaces the client; a running server keeps the old
version until it restarts, and a restart ends pane processes (layout and
Claude conversations are restored). After upgrading:

1. Read the release notes for changes to agent detection, sidebar tokens and
   rules, `report-metadata`, state labels, plugin events and key names.
2. `herdr integration status`; reinstall `claude` if outdated (it rewrites its
   `SessionStart` entry in `settings.json` through the symlink; commit that).
3. `herdr --skill > claude/.claude/skills/herdr/SKILL.md`.
4. Check the pinned plugin tags in `bootstrap.sh` (`REVIEWR_TAG`,
   `NAVIGATOR_TAG`) against new releases.
5. Run the harness and look at the render.

Known upgrade notes: 0.9.2 broke Escape-prefixed keys (Alt/Option chords such
as our `alt+h/j/k/l`, `alt+s`); 0.9.3 fixed it, so skip 0.9.2. 0.9.2 also sets
`TERM_PROGRAM=herdr` in new panes (previously inherited `ghostty`) and fixes
false "done" notifications on startup and restored sessions.

## Known limitations

- Model names longer than 10 columns shift the context bar by the excess.
- A denied permission shows the activity text of the denied tool until the
  next event.
- Two-row limit: text beyond the second row is truncated by herdr.
- The worktree hook informs Claude but does not enforce isolation; Claude
  Code's own checks apply only to worktrees it creates (`claude -w`).

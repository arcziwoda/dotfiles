# cc-askpass (vendored, patched)

Source: https://github.com/GoneTone/cc-askpass, release v0.2.0, commit
`fd45ff26147274afadf82304adbabeea797cbb4e` (2026-10-12). MIT, see `LICENSE`.
Copied without `win/`, `docs/` and the translated READMEs. Update only by re-auditing a
newer commit, replacing the files and re-applying the patch below.

## Local patch: remote mode is opt-in per host

Upstream wraps ssh to every host not in `excludeHosts`: it opens its own ControlMaster,
writes askpass/ssh/sudo wrappers into a remote `~/.cache/cc-askpass-<token>` and runs a
base64 `eval` blob there. That must never happen on work servers, and a deny-list misses
any host nobody listed. The patch adds an allow-list:

- `hooks/register.tsx`: option `includeHosts` (declared in `.claude-plugin/plugin.json`),
  default `arcziweb`, `arcziweb.com`, `arcziweb-*`, `kali-lab`, `orb` (the user's own
  machines; Kali runs on OrbStack as `kali@orb`). Exported to Bash as `CC_ASKPASS_INCLUDE`
  and unset with the other variables.
- `bin/shim/ssh`: `should_wrap` also requires `is_included`. An empty list includes no
  host. The variable does not reach the remote shim, so a second hop from an included
  host always runs unwrapped.
- Tests: `hooks/lifecycle.test.ts` and `tests/ssh.sh` cover the new option; the upstream
  'second hop' e2e test is skipped because it no longer applies.

## Audit (2026-11-03, static review)

- The typed password lives only in a module variable, goes to the helper over stdin into a
  FIFO in a 0700 directory (`/tmp/cc-askpass-<uid>/<sid>-<pid>`), and never reaches disk,
  env, argv, logs, the transcript or the plugin store.
- Sets `SUDO_ASKPASS`, `SSH_ASKPASS`, `SSH_ASKPASS_REQUIRE=force`, `CC_ASKPASS_DIR`,
  `CC_ASKPASS_INCLUDE`/`EXCLUDE`, `CC_ASKPASS_WRAP` and `DISPLAY=:0` (if unset) for every
  Bash call, and puts `bin/shim/ssh` first on PATH. Local sudo is not rewritten: with no
  tty, sudo uses the askpass by itself.
- Hooks: `session.start`, `session.end`, `prompt.compose`, `tool.call` (record only),
  `command.run` (`/askpass`), `ui.close`, `ui.render`. `prompt.compose` is bypassed by
  `cc-plugin-sec-default` on this account, so the mod's note telling the model not to use
  `sudo -n`/`-S` is in the global CLAUDE.md instead.
- No network code, no dependencies, no build step on macOS.
- Same-user weakness: the model's own commands run as the same user, so a command can call
  `$SUDO_ASKPASS` itself or race for the FIFO. The pane names who asks (`Asked by:`,
  `Claude ran:`). Answer only a pane whose heading is sudo, ssh or git and whose command
  you recognise.

// Publishes the session's live subagents to herdr's sidebar as pane metadata
// tokens ($agents, $agents_waiting), which herdr cannot see from outside the
// process. Lifecycle and status stay with herdr's own integration and
// claude/.claude/hooks/herdr-status.sh; see docs/herdr/README.md.
//
// Derived from the herdr mod in https://github.com/bendrucker/claude
// (plugins/herdr/mod/register.ts, commit 1ce8d9a), MIT, Copyright (c) 2025
// Ben Drucker; see LICENSE. Kept: counting through $.agent.list() on
// turn.start/turn.complete plus a poll while agents live. Dropped: the
// mod-events dependency, the git branch token and the classic.* hooks, which
// cc-plugin-sec-default bypasses for user plugins on a Team account.
import type { AgentInfo, EngineInterface, Register } from 'claude-code'

const SOURCE = 'dotfiles:claude-agents'
// Nerd Font U+F0C0 (users): JetBrains Mono Nerd Font has it, unlike ↳ or ⇄.
const AGENTS_GLYPH = ''
const ACTIVE = new Set(['pending', 'running', 'waiting', 'idle'])
// turn.start/turn.complete fire for subagent loops too; the poll covers an
// agent that finishes while no turn event follows.
const POLL_MS = 10_000
// session.end shares a short budget across every hook.
const END_TIMEOUT_MS = 1000
// A herdr binary that cannot start would otherwise be retried on every event.
const SUSPEND_AFTER = 3

export type Tokens = { agents: string; agents_waiting: string }
const TOKEN_NAMES: (keyof Tokens)[] = ['agents', 'agents_waiting']

export function tokensOf(agents: readonly Pick<AgentInfo, 'status'>[]): Tokens {
  const active = agents.filter(agent => ACTIVE.has(agent.status))
  const waiting = active.filter(agent => agent.status === 'waiting').length
  return {
    agents: active.length ? `${AGENTS_GLYPH} ${active.length}` : '',
    agents_waiting: waiting ? `?${waiting}` : '',
  }
}

type Pane = { bin: string; id: string }
type State = {
  pane: Pane | undefined
  reported: Partial<Tokens>
  inFlight: Promise<void> | undefined
  requests: number
  seq: number
  failures: number
  poll: { cancel: () => void } | undefined
}

// herdr drops a report whose seq is not above the last one, so the seq is taken
// before any await and a slow report cannot land over a newer one.
async function report($: EngineInterface, s: State, pane: Pane, args: string[], timeoutMs = 3000): Promise<boolean> {
  s.seq += 1
  const argv = [pane.bin, 'pane', 'report-metadata', pane.id, '--source', SOURCE, '--seq', String(s.seq), ...args]
  const { exitCode } = await $.process.run(argv, { timeoutMs }).catch(() => ({ exitCode: -1 }))
  s.failures = exitCode === -1 ? s.failures + 1 : 0
  if (s.failures >= SUSPEND_AFTER) {
    s.pane = undefined
    setPoll($, s, false)
  }
  return exitCode === 0
}

async function publish($: EngineInterface, s: State, tokens: Tokens): Promise<void> {
  const args: string[] = []
  for (const name of TOKEN_NAMES) {
    if ((s.reported[name] ?? '') === tokens[name]) continue
    args.push(...(tokens[name] === '' ? ['--clear-token', name] : ['--token', `${name}=${tokens[name]}`]))
  }
  const pane = s.pane
  if (!args.length || !pane) return
  if (await report($, s, pane, args)) s.reported = { ...tokens }
}

async function drain($: EngineInterface, s: State): Promise<void> {
  const seen = s.requests
  try {
    const tokens = tokensOf(await $.agent.list())
    await publish($, s, tokens)
    setPoll($, s, tokens.agents !== '')
  } catch {
    // A failed read leaves the last report in place; the next event retries.
  }
  if (s.requests !== seen && s.pane) return drain($, s)
  s.inFlight = undefined
}

function setPoll($: EngineInterface, s: State, on: boolean): void {
  if (on && s.pane) {
    s.poll ??= $.clock.every(POLL_MS, () => refresh($, s))
  } else {
    s.poll?.cancel()
    s.poll = undefined
  }
}

// Events come in bursts: a refresh that lands mid-flight is counted and the
// running read goes again instead of racing it.
function refresh($: EngineInterface, s: State): void {
  if (!s.pane) return
  s.requests += 1
  s.inFlight ??= drain($, s)
}

export const register: Register = on => {
  const s: State = { pane: undefined, reported: {}, inFlight: undefined, requests: 0, seq: 0, failures: 0, poll: undefined }

  on('session.start', async ($, e, next) => {
    const [env, id, bin, now] = await Promise.all([
      $.env.get('HERDR_ENV'),
      $.env.get('HERDR_PANE_ID'),
      $.env.get('HERDR_BIN_PATH'),
      $.clock.now(),
    ])
    // Clock-based, so a restarted session's seqs stay above the last one's.
    s.seq = Math.max(s.seq, now * 1000)
    s.reported = {}
    s.failures = 0
    s.pane = env === '1' && id && e.isInteractive ? { bin: bin || 'herdr', id } : undefined
    refresh($, s)
    return next(e)
  })

  on('turn.start', ($, e, next) => (refresh($, s), next(e)))
  on('turn.complete', ($, e, next) => (refresh($, s), next(e)))

  on('session.end', async ($, e, next) => {
    // /clear and /resume end the conversation, not the process.
    if (e.reason === 'clear' || e.reason === 'resume') {
      refresh($, s)
      return next(e)
    }
    const pane = s.pane
    s.pane = undefined
    setPoll($, s, false)
    if (pane) await report($, s, pane, TOKEN_NAMES.flatMap(name => ['--clear-token', name]), END_TIMEOUT_MS)
    return next(e)
  })
}

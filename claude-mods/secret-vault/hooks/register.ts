import { atom, read, update } from 'claude-code'
import type { ApiContentBlock, EngineInterface, Register } from 'claude-code'

import type { VaultEntry } from '../types'
import { hasPlaceholder, mapStrings, mask, placeholder, unmask } from './vault'

const vault = atom({ plugin: 'secret-vault', key: 'entries' } as const, [] as VaultEntry[])

// What the model reads beside a prompt or tool result that carries a
// placeholder. A user plugin cannot add to the system prompt (the built-in
// security plugin passes prompt.compose over it), so it rides as context.
const GUIDE = [
  'Secret placeholders:',
  'Text shaped `«secret:<name>»` (e.g. `«secret:discord-webhook-1»`) stands for a secret the secret-vault plugin',
  'took out of the conversation: a token, password, key or webhook URL the user pasted or a tool printed.',
  'Use the placeholder verbatim wherever the value is needed (Bash commands, file contents, edits, URLs, MCP',
  'arguments): it is replaced with the real value when the tool runs, and the value is masked again in what comes',
  'back. Do not ask the user to reveal it, do not try to print or decode it, and do not treat the placeholder as a',
  'bug in a file. Writing it into a file writes the real secret there, so only do that where the user wants it.',
].join('\n')

// Masks `text` against the vault, adding what the detectors find, and says
// which secrets were new. Only a find writes, and the write retries on a
// concurrent change, so two rows masking the same new value agree on a name.
async function absorb($: EngineInterface, text: string): Promise<string> {
  const first = mask(text, await read($, vault))
  if (!first.added.length) return first.text
  let masked = first.text
  let added: VaultEntry[] = []
  await update($, vault, entries => {
    const result = mask(text, entries ?? [])
    masked = result.text
    added = result.added
    return result.entries
  })
  if (added.length) $.ui.toast(`secret-vault: masked ${added.map(e => e.name).join(', ')}`)
  return masked
}

// Every text a row carries for the model: text blocks, and a tool result's
// content as a string or as text blocks.
type MaskedBlocks = { blocks: ApiContentBlock[]; isChanged: boolean }

async function maskBlocks($: EngineInterface, blocks: readonly ApiContentBlock[]): Promise<MaskedBlocks> {
  let isChanged = false
  const out: ApiContentBlock[] = []
  for (const block of blocks) {
    if (block.type === 'text' && typeof block.text === 'string') {
      const text = await absorb($, block.text)
      isChanged ||= text !== block.text
      out.push(text === block.text ? block : { ...block, text })
    } else if (block.type === 'tool_result' && typeof block.content === 'string') {
      const content = await absorb($, block.content)
      isChanged ||= content !== block.content
      out.push(content === block.content ? block : { ...block, content })
    } else if (block.type === 'tool_result' && Array.isArray(block.content)) {
      const inner: MaskedBlocks = await maskBlocks($, block.content as ApiContentBlock[])
      isChanged ||= inner.isChanged
      out.push(inner.isChanged ? { ...block, content: inner.blocks } : block)
    } else {
      out.push(block)
    }
  }
  return { blocks: out, isChanged }
}

// A tool's structured record (what the screen draws and the transcript file
// keeps beside the model's text), masked string by string so it keeps its
// shape for the tool's output schema.
async function maskRecord($: EngineInterface, record: unknown): Promise<{ record: unknown; isChanged: boolean }> {
  const strings = new Set<string>()
  mapStrings(record, s => (strings.add(s), s))
  const masked = new Map<string, string>()
  for (const s of strings) {
    const m = await absorb($, s)
    if (m !== s) masked.set(s, m)
  }
  if (!masked.size) return { record, isChanged: false }
  return { record: mapStrings(record, s => masked.get(s) ?? s), isChanged: true }
}

// Two files keep a secret before any hook sees it: the prompt history
// (~/.claude/history.jsonl, what the up arrow recalls, written as Enter is
// pressed) and, under `claude -p`, the transcript's queue record of the
// prompt. When the session ends, hooks/scrub.pl replaces each vaulted value
// there by its placeholder, in place. history.jsonl is shared by every
// session: a line another session appends in the instant between the
// script's read and its write is lost.
async function scrubFiles($: EngineInterface, sessionId: string): Promise<void> {
  const entries = [...(await read($, vault))].sort((a, b) => b.value.length - a.value.length)
  const home = await $.env.get('HOME')
  if (!entries.length || !home) return
  // The transcript is projects/<the cwd, sanitised>/<session id>.jsonl; the
  // script expands the pattern rather than this module re-deriving the name.
  const files = [`${home}/.claude/history.jsonl`, `${home}/.claude/projects/*/${sessionId}.jsonl`]
  const pairs = entries.map(e => [JSON.stringify(e.value).slice(1, -1), placeholder(e.name)])
  const ran = await $.process.run(['/usr/bin/perl', `${$.plugin.root}/hooks/scrub.pl`, ...files], {
    stdin: JSON.stringify(pairs),
  })
  if (ran.exitCode !== 0) $.ui.log(`secret-vault: scrub failed: ${ran.stderr.trim()}`, { to: 'debug' })
}

export const register: Register = on => {
  // The prompt as submitted, before it is queued: the queue's own record of
  // it in the transcript file then holds the placeholder too.
  on('prompt.submit', async ($, e, next) => {
    const text = await absorb($, e.text)
    const context = await Promise.all((e.context ?? []).map(c => absorb($, c)))
    if (hasPlaceholder(text)) context.push(GUIDE)
    return next({ ...e, text, ...(context.length ? { context } : {}) })
  })

  // Every row the conversation keeps, main and subagents alike: what the
  // model reads and what the transcript stores.
  on('session.append', async ($, e, next) => {
    const { blocks, isChanged } = await maskBlocks($, e.message.content)
    return isChanged ? next({ ...e, message: { ...e.message, content: blocks } }) : next(e)
  })

  // Placeholders in a call's arguments become the real values as it runs;
  // the record it returns is masked again.
  on('tool.call', async ($, e, next) => {
    const entries = await read($, vault)
    const input = entries.length && hasPlaceholder(JSON.stringify(e)) ? mapStrings(e, s => unmask(s, entries)) : e
    const ran = await next(input)
    if (ran.deny !== undefined || ran.isError) return ran
    const { record, isChanged } = await maskRecord($, ran.result)
    return isChanged ? { result: record as typeof ran.result, context: [...(ran.context ?? []), GUIDE] } : ran
  })

  // classic.SessionEnd would hand over the transcript's path, but the
  // built-in security plugin passes user plugins over on classic events.
  on('session.end', async ($, e, next) => {
    try {
      await scrubFiles($, e.sessionId)
    } catch (error) {
      $.ui.log(`secret-vault: files not scrubbed: ${String(error)}`, { to: 'debug' })
    }
    return next(e)
  })
}

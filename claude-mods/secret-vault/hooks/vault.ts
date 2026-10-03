import type { VaultEntry } from '../types'

/** What the model reads in place of a secret: `«secret:discord-webhook-1»`. */
export const placeholder = (name: string) => `«secret:${name}»`

// A fresh regex per use: a shared global one carries lastIndex from call to call.
const placeholders = () => /«secret:([a-z0-9-]+)»/g

type Detector = {
  kind: string
  pattern: RegExp
  /** The capture group holding the secret; the whole match when absent. */
  group?: number
}

// High-precision shapes only: a false positive costs the model a readable
// value (it still round-trips through tool calls), a false negative leaks.
// Order matters where shapes overlap (sk-ant- before sk-).
const DETECTORS: readonly Detector[] = [
  { kind: 'private-key', pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]+?-----END [A-Z ]*PRIVATE KEY-----/g },
  { kind: 'discord-webhook', pattern: /https:\/\/(?:(?:ptb|canary)\.)?discord(?:app)?\.com\/api\/webhooks\/\d+\/[\w-]{20,}/g },
  { kind: 'slack-webhook', pattern: /https:\/\/hooks\.slack\.com\/(?:services|workflows|triggers)\/[A-Za-z0-9/_-]{20,}/g },
  { kind: 'github-token', pattern: /\b(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,})\b/g },
  { kind: 'slack-token', pattern: /\bxox[abposr]-[A-Za-z0-9-]{10,}/g },
  { kind: 'anthropic-key', pattern: /\bsk-ant-[A-Za-z0-9_-]{20,}/g },
  { kind: 'openai-key', pattern: /\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}/g },
  { kind: 'stripe-key', pattern: /\b(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{20,}/g },
  { kind: 'aws-key-id', pattern: /\b(?:AKIA|ASIA)[0-9A-Z]{16}\b/g },
  { kind: 'google-api-key', pattern: /\bAIza[0-9A-Za-z_-]{35}\b/g },
  { kind: 'jwt', pattern: /\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g },
  // scheme://user:password@host
  { kind: 'url-password', pattern: /\b[a-z][a-z0-9+.-]*:\/\/[^\s:@/]+:([^\s@/]{3,})@/gi, group: 1 },
  // NAME=value lines of .env files and shell exports
  {
    kind: 'env-secret',
    pattern: /^[ \t]*(?:export[ \t]+)?[A-Za-z0-9_]*(?:PASSWORD|PASSWD|SECRET|TOKEN|API_?KEY|PRIVATE_?KEY|ACCESS_?KEY|CREDENTIALS?)[A-Za-z0-9_]*[ \t]*=[ \t]*(["']?)([^\s"'#]{8,})\1[ \t]*$/gim,
    group: 2,
  },
  // key: value lines of YAML, and "key": "value" members of JSON
  {
    kind: 'config-secret',
    pattern: /^[ \t]*-?[ \t]*["']?[\w.-]*(?:password|passwd|secret|token|api[_-]?key|private[_-]?key|access[_-]?key)[\w.-]*["']?[ \t]*:[ \t]*(["']?)([^\s"'#{}$<>([][^\s"'#]{7,})\1[ \t]*,?[ \t]*$/gim,
    group: 2,
  },
]

// Values an assignment detector matched that are references, not secrets.
const NOT_A_SECRET = /^(?:\$|\{\{|<|«secret:)|^(?:true|false|null|none|changeme|password)$|^\*+$/i

export type MaskResult = { text: string; entries: VaultEntry[]; added: VaultEntry[] }

/**
 * Replaces every secret in `text` by its placeholder: the vault's known
 * values first, then each detector's matches, which join the vault.
 */
export function mask(text: string, entries: readonly VaultEntry[]): MaskResult {
  const vault = [...entries]
  const added: VaultEntry[] = []
  let out = text

  for (const entry of [...vault].sort((a, b) => b.value.length - a.value.length)) {
    if (out.includes(entry.value)) out = out.split(entry.value).join(placeholder(entry.name))
  }

  const nameFor = (kind: string, value: string): string => {
    const known = vault.find(e => e.value === value)
    if (known) return known.name
    const n = vault.filter(e => e.name.startsWith(`${kind}-`)).length + 1
    const entry = { name: `${kind}-${n}`, value }
    vault.push(entry)
    added.push(entry)
    return entry.name
  }

  for (const { kind, pattern, group } of DETECTORS) {
    out = out.replace(pattern, (match: string, ...groups: unknown[]) => {
      const value = group === undefined ? match : groups[group - 1]
      if (typeof value !== 'string' || !value || value.includes('«secret:') || NOT_A_SECRET.test(value)) return match
      const name = nameFor(kind, value)
      return group === undefined ? placeholder(name) : match.replace(value, placeholder(name))
    })
  }

  return { text: out, entries: vault, added }
}

/** Puts each known secret back in place of its placeholder; unknown ones stay. */
export function unmask(text: string, entries: readonly VaultEntry[]): string {
  return text.replace(placeholders(), (match: string, name: string) => entries.find(e => e.name === name)?.value ?? match)
}

/** The distinct secret names `text` refers to by placeholder, in order. */
export function placeholderNames(text: string): string[] {
  return [...new Set([...text.matchAll(placeholders())].map(m => m[1] ?? ''))].filter(Boolean)
}

export function hasPlaceholder(text: string): boolean {
  return placeholders().test(text)
}

/** Applies `fn` to every string in a JSON-like value, keeping its shape. */
export function mapStrings<T>(value: T, fn: (s: string) => string): T {
  if (typeof value === 'string') return fn(value) as T
  if (Array.isArray(value)) return value.map(v => mapStrings(v, fn)) as T
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, mapStrings(v, fn)])) as T
  }
  return value
}

// How a tool call is shown in a confirmation dialog so that what the person
// approves is what runs: every argument, nothing cut, hidden characters made
// visible, and the call quoted line by line so its text cannot pass for the
// dialog's own (a fake question, a run of empty lines pushing the rest away).
// It names no destinations: a command reaches hosts in too many ways (nc,
// ssh, git remotes, bare names) for a list to be complete, and an incomplete
// one reads as an all-clear. The person reads the call itself.

/** The longest call a dialog shows whole; a longer one is refused. */
export const MAX_CHARS = 4000
/** The most lines a dialog shows whole; a longer call is refused. */
export const MAX_LINES = 60

// Characters that draw as nothing or move the cursor: C0/C1 controls but
// newline and tab (ANSI escapes, carriage return), soft hyphen, bidi marks
// and overrides, zero-width and other format characters.
const HIDDEN = /[\u0000-\u0008\u000B-\u001F\u007F-\u009F\u00AD\u061C\u180E\u200B-\u200F\u2028-\u202E\u2060-\u206F\uFEFF]/g

// A run of blanks inside a line long enough to wrap into empty-looking rows
// and push the rest of the call out of view; ordinary indentation is shorter.
const PADDING = /[ \t]{16,}/g

export type CallReview = { isReviewable: true; text: string } | { isReviewable: false; reason: string }

export type ReviewOptions = {
  /** Lines to point out in the header (a secret's placeholder, say), by what they hold. */
  mark?: { label: string; test: (line: string) => boolean }
}

/** The call's arguments (no `tool`, `tool_use_id`, `agentId`) as a dialog shows them. */
export function reviewCall(args: Record<string, unknown>, options: ReviewOptions = {}): CallReview {
  const { command, ...rest } = args
  const body =
    typeof command === 'string'
      ? Object.keys(rest).length
        ? `${command}\n\nwith ${JSON.stringify(rest, null, 2)}`
        : command
      : JSON.stringify(args, null, 2)
  if (body.length > MAX_CHARS) return { isReviewable: false, reason: `${body.length} characters, over ${MAX_CHARS}` }

  let hasHidden = false
  const visible = body.replace(HIDDEN, c => {
    hasHidden = true
    return `<U+${(c.codePointAt(0) ?? 0).toString(16).toUpperCase().padStart(4, '0')}>`
  })
  const lines = visible.split('\n')
  if (lines.length > MAX_LINES) return { isReviewable: false, reason: `${lines.length} lines, over ${MAX_LINES}` }

  const quoted: string[] = []
  const marked: number[] = []
  let blanks = 0
  const flushBlanks = () => {
    if (blanks === 1) quoted.push('│')
    else if (blanks > 1) quoted.push(`│ <${blanks} empty lines>`)
    blanks = 0
  }
  lines.forEach((line, i) => {
    if (!line.trim()) {
      blanks += 1
      return
    }
    flushBlanks()
    if (options.mark?.test(line)) marked.push(i + 1)
    quoted.push(`│ ${line.replace(PADDING, run => `<${run.length} blanks>`)}`)
  })
  flushBlanks()

  const header = [
    hasHidden ? 'WARNING: the call holds invisible or control characters, shown as <U+XXXX>.' : '',
    options.mark && marked.length ? `${options.mark.label} on line ${marked.join(', ')} of ${lines.length}.` : '',
  ].filter(Boolean)

  return { isReviewable: true, text: [...header, ...(header.length ? [''] : []), ...quoted].join('\n') }
}

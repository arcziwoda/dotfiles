/** One secret the session has seen: the name its placeholder carries, and the value. */
export type VaultEntry = { name: string; value: string }

declare module 'claude-code' {
  interface PluginState {
    'secret-vault': {
      /** Every secret masked in this session; never written to $.store or disk. */
      entries: VaultEntry[]
    }
  }
}

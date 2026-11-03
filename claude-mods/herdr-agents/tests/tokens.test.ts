import { describe, expect, test } from 'claude-code/testing'

import { tokensOf } from '../hooks/register'

const agent = (status: 'pending' | 'running' | 'waiting' | 'idle' | 'completed' | 'failed' | 'killed') => ({ status })

describe('tokensOf', () => {
  test('no agents clears both tokens', async () => {
    expect(tokensOf([])).toEqual({ agents: '', agents_waiting: '' })
  })

  test('counts live agents and leaves out finished ones', async () => {
    const tokens = tokensOf([agent('running'), agent('pending'), agent('idle'), agent('completed'), agent('failed'), agent('killed')])
    expect(tokens).toEqual({ agents: '\uebba 3', agents_waiting: '' })
  })

  test('waiting agents count in both tokens', async () => {
    expect(tokensOf([agent('waiting'), agent('running'), agent('waiting')])).toEqual({ agents: '\uebba 3', agents_waiting: '?2' })
  })
})

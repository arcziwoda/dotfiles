# Review scope

These paths and changes carry no executable code. Do not report findings on them unless the
change also touches code in the same diff:

- Generated data files committed by reporting skills, e.g. `notes/daily/*.json`.
- sops-encrypted files (`secrets/*.yaml`, `*.enc.yaml`): the values are ciphertext by design.
- Source material kept for reference: `**/sources/**`, saved artifact HTML, meeting transcripts.
- Commits that only bump the `version` field in `plugin.json` or `marketplace.json`.
- In a dotfiles repo: `settings.json` key reordering, theme, model or output-style changes.

Still review: hooks and scripts (`*.sh`, `*.py`, `*.ts`), permission rules, MCP server
definitions, and anything that runs commands, reads secrets or opens network connections.

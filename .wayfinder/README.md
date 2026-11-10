# Wayfinder tracker (local markdown)

This repo has no hosted issue tracker, so wayfinder maps live here as files.

- **Map:** `.wayfinder/<map>/map.md` (the `wayfinder:map`).
- **Ticket:** `.wayfinder/<map>/tickets/<id>-<slug>.md`. The zero-padded `<id>` is its identity.
- **Front matter** on each ticket:
  - `title`: the ticket's name. Refer to it by this, never by the bare id.
  - `type`: one of `research | prototype | grilling | task` (the `wayfinder:<type>` label)
  - `status`: `open | closed`
  - `assignee`: empty = unclaimed. Claim by setting it *before* any work.
  - `blocked_by`: list of ticket ids. Unblocked when every one is `closed`.
- **Resolution:** appended under `## Resolution` in the ticket, then `status: closed`.
- **Frontier:** open, unblocked, unassigned tickets.
  `grep -l 'status: open' .wayfinder/<map>/tickets/*.md`, then check `blocked_by` and `assignee`.

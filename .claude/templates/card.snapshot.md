---
card: GST-208
extracted: 2026-08-31T14:22:05-03:00
sources:
  - description
  - comments (4)
  - attachment: acceptance-criteria-v3.xlsx
  - confluence: PLAT/Scoring rules
not_read:
  - attachment: mockups.fig (could not be opened)
status: proposed
---

# Snapshot — GST-208 · customer search

Written by `/card`. **It is never edited.** If the card changed, it is renamed to
`card.snapshot.2026-08-31.md` and a new one is written.
`sources:` cannot be empty. `not_read:` can be empty but cannot be missing.
`status: proposed` means: a model wrote it and no person approved it.

## Card, as written

Transcription without interpretation, saying which source each block came from.

**Requirement** (source: description) — …
**Acceptance criteria** (source: attachment acceptance-criteria-v3.xlsx) — …
**Definitions that are only in comments** (source: comments) — who, when, what they said.

## Scenarios

Exact format: `- [ ] <CARD>-H<NN>-<NN> — <title in the business's language>`, always two digits.
An ID from another card, or two scenarios with the same ID, is a hard error.

- [ ] GST-208-H01-01 — searches customers by partial company name
- [ ] GST-208-H01-02 — the search returns nothing
- [ ] GST-208-H01-03 — searches by tax ID with and without hyphens
- [ ] GST-208-H02-01 — an analyst without approval permission does not see the button
- [ ] GST-208-H02-02 — a request above the customer's credit limit stays pending

## Contradictions within the card

Unresolved: what each side says and where each one is. The resolution goes in the plan.

- The requirement says “search by company name”; the acceptance criterion says “by company name
  or tax ID” · requirement in the description, criterion in the v3 attachment.

Ambiguities **do not go here**: they live in `ambiguities.md`, which is append-only because they
have a lifecycle. This file is immutable.

# The matrix: what has to be taken into account, at what moment, and how you know it was

The nine steps of `METHOD.md` say **in what order** to work. This matrix says **what cannot be
forgotten**. A flow tells you what comes next; it does not tell you what you skipped. **An empty
cell shows.**

Each cell names **the artifact** that has to exist and **how it is checked**. The detail lives in
the command or rule named: it is not repeated here, because an index that explains everything is
the long file nobody reads.

| Area | Start | Plan | Build | Verify | Close |
|---|---|---|---|---|---|
| **Scope** | `card.snapshot.md` frozen · empty `git diff` | the ten questions → `AMB-NN` · the `grep` gives 10 | each new file appears in the plan's map | **F1 by the `inspector` against the running app** (the verdict `reviewer` in a clean context too, with the inspector and before any correction, if a screen or a route that writes): each criterion meets or not, and what is extra | live assumptions, one by one, in the PR and the comment |
| **Design** | **the first card sets layout, layers and shape of enumerations** · the ADR and `system-design.md` · see below | file map **with its structure decisions** | layers per `rules/architecture.md` | dependency-direction test in the default command | — |
| **Behavior** | the card's scenarios, one per line | each scenario with its tagged test, red · `/scenarios` | unit test for each business rule | whole suite + `@extensible` · **mutation score** · the failure is classified by its shape | scenarios ↔ tags, in both directions, counting **scenarios** and not cases |
| **Interface** (ui) | — | visual brief: dials, material, **from where each thing is done** | appearance by **position**, not by name | `axe`, keyboard, contrast, `forced-colors`, required fields, what axe does not see | the capture strip, **who looked at it**, and the **conformance report** |
| **Security** | — | perimeter: declared auth or `ASM-NN` · STRIDE if there is a new surface · the secrets inventory | the gap where whoever starts the app sees it | **ASVS 5.0 level 1** row by row, against the running app · `reference/validate-mechanical.md` pause 4 | what was not tested, named |
| **Data** (data) | volumes the card asks for | the model in `system-design.md`, the query and its index | correlated seed, walking through the enumeration | causal chain · without the generator · **the promised number is fixed by a test** · R5, Q7 | **what data it was verified with** |
| **Endurance** | — | the budgets (the card's or an `ASM-NN`) · `hot-path` | atomic write · validation on open | p95 per screen, Web Vitals and load, alone at the end · a single port · `reference/validate-mechanical.md` pause 6 | the reported p95 |
| **Evolution** | see Design × Start | — | table indexed by enumeration, **typed by that enumeration** | test change **by name and by count**, counted by command | **the number of the test change**, so the next card sees whether it goes up |
| **Documentation** (docs) | the `docs/` skeleton (`templates/docs.md`) | the `Docs` and `API contract` lines | the doc in the same diff · the contract | Q8, Q9, Q10 · `required.mjs` | which docs changed |
| **Infrastructure** (infra, ci) | `doctor.mjs` · ADR · system design · cost model · runbook | the ADR and the cost model if the card adds infrastructure | `system-design.md` kept current | `required.mjs` · Q13, Q14 | the cost today and at 10x |
| **Operation** (observability) | the SLOs and the alerts | — | logs, metrics, traces, health | R8, R9, Q15 | what is observed |
| **Evidence** | `sources:` and `not_read:` | — | — | three states, exit codes, **nothing in the background that the close depends on** · `passed with flaky` stays visible (`.validation/verify/flaky.md`) and a line covered by another says `covered by` · one complete `verify.mjs` per chain of corrections | the PR and the comment come from the output, not from memory · **the session is recorded** |

In the fast lane (`steps/fast-lane.md`) the Verify column is the suite, the captures, axe and the overflow run.

## The cell the flow hides

**Design × Start.** The first card of a repository chooses the layout, the names of the layers
and the shape of the enumerations —whether a stage is a string, a named object or an index—, and
**those are the most expensive decisions to undo in the whole project**. A method that treats it
the same as card number forty lets it pass without looking.

So the first card of a new repo, besides its work, leaves three things written in the plan, each
with its reason:

- **Which layers there are and who knows whom.** It is what the dependency test later asserts; if
  it is not written, the test asserts whatever came out.
- **What a business enumeration looks like**: where it lives, what it carries —the name yes, the
  appearance no—, and how it is walked.
- **The `paths:` of `.claude/rules/`**, adjusted to the paths just invented. A rule that
  activates by path does not warn when it does not activate.

## How it is used

At **close**, the whole column is walked and each cell is answered with its evidence or with *not
applicable, because…*. **An unanswered cell is a cell that was not done.** A row that carries a module
in parentheses, with that module off, is answered `off by decision: <reason>` —the reason is in
`.claude/kit.json`—: it is an answer, not an empty cell.

The matrix does not replace the commands: it orders them. `/card` fills Start, `/scenarios` and
the plan fill Plan, `/validate` fills Verify, `/close` fills Close. If a cell has no command that
fills it, **that cell is the next mechanism that is missing.**

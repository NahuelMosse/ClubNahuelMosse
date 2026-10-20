# Step 4 · Each scenario is a test, before the code, red

## At a glance

`/scenarios <ID>` writes one test per scenario of the snapshot, tagged `@<ID>-H<NN>-<NN>`, through the
interface (a browser with a screen, HTTP or the function without one), and they must be **red** before any code.
The main thread writes them: they are the specification, never delegated. They can go in the same commit as
the plan; what freezes is the commit. The `reviewer` reads the red once (`RED-REVIEW`), not at poc.

**Closes with:** `grep -rl "@<ID>-H01-01" $E2E` finds a file for every snapshot ID, and
`grep -rhoE "@<ID>-H[0-9]+-[0-9]+" $E2E | sort -u` finds no tag of this card that the snapshot lacks.

Most broken:
- A grep at zero with a denominator of zero is not green: it is `could not be verified`.
- Each test asserts on a value that the same test created (or `@no-sentinel:<reason>`).
- Proportional: one test per scenario plus the attacks and edges a criterion names; no matrices.
- What only the real world can answer (how Excel opens a file) is tested disposably before freezing.
- Waiting: `node .claude/tools/wait.mjs --agent <id> --max 570` for an agent (a kit tool's log: `<log>`; another log: `<log> --until <regex>`), never `sleep` or `until grep`.

Read the rest only when a scenario depends on something the team does not control (how Excel opens a file, an external service), or a frozen test has to be refrozen.

## Full rules

**What can only be known by testing against the real world is tested before freezing.** If the
criterion depends on something the team does not control —how Excel opens a file, what an
external service returns—, first a disposable test against that, and only with the answer is the
scenario written.

`/scenarios <ID>` writes one test per scenario, tagged `@<ID>-H<NN>-<NN>`. How a test of this
suite is written —a file per screen, everything through the interface, real role, selectors by
accessible name— is in the command itself. **The scenarios in red and the plan can go in the same
commit**: what freezes is the commit, and one commit less is one round less. **The `reviewer` reads the red once**, with `RED-REVIEW` at the start of its prompt (`commands/scenarios.md`), and not at poc; the verdict reviewer is another stage with its own cap.

**The tests in red are written by the main thread**, because they are the specification: they are not delegated to a `grunt` or an `implementer`.

**Tests are proportional:** one per scenario, plus the attacks and edges a criterion of the bar names; no
matrices, no case repeated at every layer unless a criterion asks. Coverage and mutation stay as they are.

**Through the interface:** with a screen, a browser; without a screen, HTTP requests or the
function called from the test. A browser is not set up for a card that has no screen. The cases
come from named techniques and the oracles from the requirement: `.claude/reference/testing.md`. Why each rule is there: `.claude/reference/why-card-start.md`.

→ **Validate, in both directions, always together with the denominator:**
- For each ID of the snapshot: `grep -rl "@<ID>-H01-01" $E2E` returns at least one file.
- The other way round: `grep -rhoE "@<ID>-H[0-9]+-[0-9]+" $E2E | sort -u` — every tag of **this
  card** has to exist in `## Scenarios` of the snapshot. Tags of earlier cards belong to their
  cards and are not looked at here.
- A grep at zero is **not green if the denominator is also zero**: it is “could not be verified”.

**A scenario is not a case, and the close reports scenarios**: the number that goes to the close
is that of this card's unique tags, `grep -rhoE "@<ID>-H[0-9]+-[0-9]+" $E2E | sort -u | wc -l`.

→ **Sentinel data.** Each test asserts on a value that **that same test created**. If the
scenario does not allow it, `@no-sentinel:<reason>`.

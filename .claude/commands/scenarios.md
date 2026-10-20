---
description: Turns each snapshot scenario into a tagged test, red, in its own commit.
argument-hint: <CARD-ID>
---

Card: `$1`. Locate the feature folder under `specs/` —the one `/card` created for this work— and
read `card.snapshot.md` there — the `## Scenarios` section is the work list. **Do not write
production code in this command.** Only tests.

**First, the answers (first of the two readings).** Fetch the card's comments over the MCP and record
each answered question as `resolved` (`.claude/steps/02-ambiguities.md`): the tests are written
against those answers. What is still open is tested as its provisional `ASM-NN`, tagged
`@assumption:$1-ASM-NN`. Nothing is waited for; with no channel there is nothing to read.

**Each test file is created with the `Write` tool, one file per call**, not with a heredoc in the
shell; the shell's `>>` is only for the event line in `ambiguities.md`.

## At a glance

One test per scenario, written by the main thread (never delegated), tagged at the end of its title with the exact ID
(`test("<behavior in domain language, lowercase> @$1-H01-01", …)`; an assumption adds `@assumption:$1-ASM-NN`), in the
file of its screen. Through the interface: preconditions are built by clicking (a direct URL only when the interface
offers no vector on purpose, said in a comment); a real role, never `admin`; each test asserts on a value it created
(`@no-sentinel:<reason>` when it cannot), a global as a difference `N to N+1`; texts literal; selectors by role and
accessible name; `retries: 0`, no `waitForTimeout`, no timing. Proportional: one test per scenario plus the edges and
attacks a criterion names.

They are committed **red**, alone in a commit; the hash goes to `ambiguities.md` as `$1-TESTS · <date> · frozen at <hash>`.
Before committing:
```
grep -rl "@$1-H01-01" $E2E                          # each snapshot ID: >= 1 file
grep -rhoE "@$1-H[0-9]+-[0-9]+" $E2E | sort -u      # every tag of this card is in the snapshot
find "$E2E" -name '*.spec.*' | wc -l                # denominator: a grep at zero over zero files is "could not verify"
<scenarios by "@$1">  # fail on the assertion, not on an import; Node: `timeout 30 node --test --test-timeout=5000 --test-force-exit <files> 2>&1 | grep -E "^ℹ (tests|pass|fail)|^✖"` (Node ≥ 23 prints the spec reporter into a pipe too: there is no `# pass`); Playwright: `--timeout=5000 --retries=0`
<type checker over the tests>  ·  <test linter over them>   # 0 errors
```
The `reviewer` reads the red once (not at poc), in one message with the red run. First line of its prompt: `RED-REVIEW <ID> · the tests tagged @<ID>-H and card.snapshot.md · write your report in specs/<card>/red-review.md`.
It also asks for input shapes (missing, null, wrong type) and, with money, rounding at the cent: they are one more test now, before the implementer
starts. With a screen, it also asks: where the focus lands after each state change (submit, busy, failure, success; never `body`); a behavior the card gives to “a field” tested on every field type, the `select` included; what clears each message.
Its findings are fixed and the scenarios committed without a second review. Its findings go in with `Edit`, one per finding, in the same message as the rerun of the red; the file is written whole again only if more than half of its tests change.
Acceptance criteria are also tested as a plain client, with no header the card does not name (no `Origin`, no special `Host`); a 403 or 421 there is a defect.
A finding changes an ASM only when the card contradicts it (a sentence it makes false); a sentence it leaves without effect, already named in its event, is an observation the PR lists, and the tests stay. A change rewrites the tests of the new reading in the same commit, with the edges it opens.

Read the rest only when a screen has forms, searches, files or permissions (the grid under “The card’s scenarios are the floor”: `node .claude/tools/help.mjs grid`), or a locator targets a `menu`, `listbox`, `tablist`, `tree` or `grid`.

## How a test in this suite is written

→ **One test per scenario, at least, tagged with the exact ID**, at the end of the title —`--grep`
matches there—, never in front. **The title says the behavior, in domain language and lowercase**,
so that the suite reads as the list of what the product does:

```ts
test("the shareholding does not advance unless it adds up to 100% @$1-H01-01", …)
```

A title never starts with the number of an artifact. If the scenario encodes an
assumption of the plan, also add `@assumption:$1-ASM-NN`.

→ **The file goes by screen, not by card**: `<area>/<screen>` with the extension of the scenarios
suite, next to the tests that already exercise that screen, even if their card is another one.

→ **Everything through the interface: the precondition is built by clicking.** No endpoint, no
writing to the database, no saved session to skip the login: building the state through the screen
also proves that the flow leading to it works. **The rule is about building, not exercising**: when
the interface offers no vector on purpose —someone else's resource cannot be reached by clicking—
**the direct URL is the vector**, with a comment saying it is deliberate.

→ **Real role, never `admin`.** `admin` covers up the gating, which is usually what has to be
verified. Also test what a role **cannot** do: that the control is not rendered, not only the 403.

→ **Sentinel data.** Each test asserts on a value **that same test created**, generated inline, not
a shared fixture nor data already in the database:

```ts
const taxId = `30-${Date.now().toString().slice(-8)}-9`;
await createClient({ companyName: `Metalworks ${taxId}`, taxId });
// ...and the assertion is on `taxId`, not on "the first result"
```

If the scenario does not admit data of its own —empty state, error, permission denied— tag it
`@no-sentinel:<reason>`. Never invent data to make the check pass. It is the only check left to the
eye: no command validates it. **Something global —a counter, a total, a listing— is asserted as a
difference**: measure, act, `from N to N+1`; never `toBeGreaterThan(0)`, already true before the test.

→ **Texts are written literally, on purpose.** An assert that imports the product's constant asserts
that the text equals itself and cannot catch a wrong copy. The exception is the content-only card
(`steps/05-plan.md`), whose scenarios read the data from the source the page renders from.

→ **Selectors by role and accessible name.** `getByRole("button", { name: "Confirm" })` first;
visible text when there is no role; `data-*` only when the DOM gives nothing else, with a comment.
If there is no stable selector, the product lacks semantics —a `<label>` without `htmlFor`, a combo
without a name, a dialog without `role`— and it is fixed there. Never layout or icon classes: they
do not survive the production build. **A selector that names a business value is scoped to its
container** —the section, the column, the row—: the name of a stage *will* show up inside the data
(*“Proposed Location for the annex”*) and the suite falls with a strict mode violation. Before using a role with `name`, verify that the role
admits one: `definition` carries no accessible name, and it never finds anything.

→ **`retries: 0`, and `waitForTimeout` is forbidden.** A test that only passes sometimes says
nothing; you wait with assertions that retry, not with time.

→ **An absence the card states is asserted without retry**, right after the positive signal of the same state: `expect(await
locator.count()).toBe(0)`, not `toHaveCount(0)` or `toBeHidden()`, which wait and also pass over a node that fades out or is
only hidden. The card said it is gone; the test says gone now.

→ **No timing in a scenario.** Frame durations, milliseconds of a response, “nothing over 50 ms”:
on a shared machine they pass or fail with the load, not with the product. A scenario asserts what
happens —it responds, it moves, it does not move with reduced motion—; how fast is measured by
`motion-audit.mjs --cpu 4` alone, one at a time, as its own line of `## Verification`, and a
performance requirement of the card is answered there.

→ **Isolation is per test.** Each test starts from a state that is only its own, and no defenses
against other tests are written: if one seems to need them, the bug is somewhere else.

→ **Each test declares what it verified, in business language**: what was checked, with what
evidence, and what breaks in real life if it does not work.

→ **The card's scenarios are the floor, not the ceiling.** Before calling a screen covered, go
through this grid and write what applies:

| | |
|---|---|
| **Field validations** | empty, only spaces, the exact limit and ±1, invalid format, negative, zero, decimals, huge number. The expected message is taken **literally from the code** |
| **Business errors** | the ones that can be provoked from that screen |
| **Empty states** | and tell their causes apart: no data, no results, no permission |
| **Searches and filters** | accents, uppercase, partial, combined, clear, no results, order asc and desc per column |
| **Persistence and navigation** | what survives a reload, what is lost going back, cancelling a modal halfway |
| **Duplicates** | each unique index is a case: the same thing twice gives a readable error, not a 500 |
| **Soft delete** | what happens to what was already used, the combos, the history |
| **Double click and concurrency** | double submit, action already done in another tab, button disabled while saving |
| **Denied permissions in the UI** | that the control is not rendered |
| **Files** | wrong format, empty, large, odd name, delete and restore |

**If you test that something persists, verify that it persisted** —reloading—; **if a setting
changes, verify its effect on every screen where it applies.** What has no screen surface is not a
test gap: it is declared and taken to the business; what an integration test covers more cheaply
lives there.

## Red, and frozen

They are written before the code and **committed failing, in a commit of their own** that touches
nothing else. **The hash goes to `ambiguities.md`** as an event, next to the snapshot's —step 6 and
check 8 of the close need it, maybe in another session:

```
$1-TESTS · <date> · frozen at <hash>
```

## Validate before committing

```
grep -rl "@$1-H01-01" $E2E                          # for each ID in the snapshot: >= 1 file
grep -rhoE "@$1-H[0-9]+-[0-9]+" $E2E | sort -u      # every tag of this card exists in the snapshot; those of earlier cards belong to them
find "$E2E" -name '*.spec.*' | wc -l                # the denominator: a grep at zero over zero files is "could not verify"
<scenarios filtered by "@$1">                       # they have to fail, not break — the command, from the stack profile; only these, never the whole suite. Node tests: `timeout 30 node --test --test-timeout=5000 --test-force-exit <files> 2>&1 | grep -E "^ℹ (tests|pass|fail)|^✖"` (Node ≥ 23 prints the spec reporter into a pipe too: there is no `# pass`). Playwright: `--timeout=5000 --retries=0` (a red test must not wait out the 30 s default per test nor retry itself). Because a red test with a server left open hangs for minutes; the flags are for this run only, never for the final suite, where `--test-force-exit` hides open handles
<type checker over the test files>                  # 0 errors: a test that does not compile is not red, it is broken
<test linter from the profile, over those files>    # 0 errors: actions without await, awaits that do nothing
```

They fail on the assertion, not on a broken import or a nonexistent selector. **Here the two cannot
be told apart**: before implementing, a selector that finds nothing and a feature that does not
exist give the same error. That is why the role and name you choose have to be possible *by the
specification*, not by what you see.

**And before the commit, a second pair of eyes on the tests:** `reviewer` reads each scenario and
answers, for each step, whether it **does** something —a click, a `fill`, a navigation— or only
names it. The checklist of the `RED-REVIEW` also asks: **is an absence the card states asserted with an immediate `count()` right after the positive signal of the same state, not with a retrying `toHaveCount(0)` or `toBeHidden()`?** And: **inside a `menu`, `listbox`, `tablist`, `tree` or
`grid`, do the locators use only the child roles that container allows?** (`menuitem`, `menuitemcheckbox`,
`menuitemradio` in a `menu`; `option` in a `listbox`; `tab` in a `tablist`; `treeitem` in a `tree`; `row` and
`gridcell` in a `grid`.) A `button` inside a `menu` fails axe as critical and the frozen test then has to be
refrozen (`steps/06-implement.md`). With a screen it also asks the three of the glance: the focus after each state change, a
behavior given to “a field” on every field type, and what clears each message.

**The tests in red are written by the main thread**: they are the specification, so they are not delegated to a `grunt` or an `implementer`.

**The red run and the `reviewer` go out together, in one message** —neither needs the other—, and
the plan is written while they work.

**The review of the red is one round**, its prompt starts with `RED-REVIEW` and ends «write your report in `specs/<card>/red-review.md`» (never `review.md`, which is the verdict reviewer's and is judged for freshness); `review-cap.mjs` counts it apart from the verdict reviewer (one round against two). What it finds is fixed and the scenarios are committed without reviewing again; at poc, which launches no reviewer, it is not asked. **Its findings are applied with `Edit` on the test file, one per finding, not by rewriting it**: the rewrite re-sends all of it, and the freeze is by commit, not by file; the file is written whole again only if more than half of its tests change.
Why each rule of this command is there: `.claude/reference/why-card-start.md`.

## Report

Snapshot scenarios / this card's unique tags / tests red / scenarios with `@no-sentinel` and why.
If you could not run a command, say which and why. Do not count it as passed.

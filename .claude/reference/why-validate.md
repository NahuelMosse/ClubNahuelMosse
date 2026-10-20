# Why each `/validate` item is there

The `/validate` list says what each check has to return. This says **what was measured** for that
check to be there. Read it when an item looks like too much — almost always, some run already
showed it was not.

## The rules of the whole list

**Why it is a list and not a manual.** A checklist works with few items per pause —Gawande found
five to nine—, short, in *do and confirm* format. When every item comes with its justification, it
reads as text and stops being ticked. That is why the why lives here.

**Why four states.** OWASP ASVS requires in its report the requirements that passed, the ones that
failed and the not applicable ones with justification. The method already had *could not run*:
telling a client that something was verified when it is not known is the lie the method exists to
avoid.

**Why the why never justifies a ceiling.** “It is a small project”, “it is seeded data” or “there
is not enough time” are not constraints: they are the decision not to do it. A list of what was
not done, kept card after card, is a method that teaches not doing it.

**Why the commands are not run in the main thread.** Nine runs spent half their cost rereading the
accumulated context, and used subagents four times in five hundred requests. Everything that
enters the main thread is paid again on every following request.

## Pause 1

**S1.** One run left the default command running only the unit tests, with the e2e —the bulk of
the coverage— behind another command. Whoever clones and runs the obvious sees green without
having exercised the screen. *The default command is the one run by whoever read nothing.*

**S2.** It is the card's definition of done: if its own scenarios do not pass, nothing else
matters.

**S3.** Filtering by the card's tag runs only what the card added: an old scenario this card broke
stays excluded. The two runs are the difference between having regression detection and not having
it.

**S4.** Six scenarios stayed red with `getByRole('definition', { name })`: the `definition` role
carries no accessible name according to ARIA, so the selector found nothing whatever the app did.
It had passed the “must fail” of step 4 because at that moment failing was the right thing. *An
impossible selector looks the same as a missing feature, until the feature is there.*

**S5.** A real repo: 336 tests in 37 minutes. Without retries and with the machine shared, that is
not a slow run: it is whole runs lost.

**S6.** ISO/IEC 25010 calls this installability. A product that only starts on the machine of
whoever made it is not delivered: the first client who clones it discovers the missing step.

## Pause 2

**T1.** Freezing the tests keeps whoever implements from lowering the bar; it does not say whether
the bar is high. A suite with the failure modes below gave five of five green and **100%
coverage**, and left four of eight mutants alive. At Google, mutants are coupled to 70% of 1,502
high-priority bugs (Petrović, ICSE 2021). A survivor can be **equivalent** —it does not change
behavior— and that one is not killed: it is declared.

**T2.** One run delivered 24 e2e cases and no unit tests: the domain was separated and only
exercised through the screen. Another, with the same requirement, wrote 41. The difference was
chance, because the e2e were mechanism and the unit tests were left to discretion.

**T3.** The seed manufactured CUITs with the check digit calculated wrong, and the test took them
as good because it used the same function. The same repo had the correct version in another file.

**T4.** The two sides of the same error: one run derived what it asserted against —the CUIT above—
and another wrote the six stages by hand in the test's loop, so when the seventh was added it lost
coverage silently. Two more runs derived the enumeration in the unit tests and repeated it by hand
in the e2e.

**T5.** An architecture test asserted that the interface used “more than zero” domain symbols, and
it would have passed with a product that copied every rule but one. `assert(reason.length > 0)`
passes with the word “x”. A test called “the CSS does not encode the number of stages” only
searched for `repeat(6`. *If the test passes with the case you wanted to forbid, it proves
nothing.*

**T6.** The README said “about 150 interactions” and the seed generated 143. The serious part is
not the number: it is that prose and code diverged without anyone finding out.

**T7.** One run hid closed opportunities on the board and always showed them in the list. Each
screen had its test and both passed. An outside evaluator found it.

**T8.** One seed assigned “factory uniform supply” to an accounting firm; another dated
interactions before the opportunity that originated them. Each field was plausible; the record,
not.

## Pause 3

**C1.** `/code-review` looks for bugs and also for reuse and simplification. One code review found
an unescaped interpolated `<title>` that no test saw, and another, composed accents that came out
as `?` in the exported file. `/simplify` does only the cleanup: run separately, in three cards it
found a duplicated header and two renames, and each finding triggered another whole validation
round.

**One round.** Measured on an export card: six reviews in a row, each followed by its fix and by
rerunning the suite, the mutation and the captures. The suite ran six times and half of the 64
minutes was waiting for repeated validations. Reviews that only read do not step on each other, so
they go out together and the fix is made once.

**C2.** `.find(…)!` resolved the stage in two places: the day one arrives that is not in the table,
that is not an error with a message, it is an `undefined` that travels through three functions.
*The case the suppression covers is exactly the one the enumeration will have when it grows.*

**C3.** A validation returned `type ?? 'call'` together with the error: the filler traveled even
though the validation had failed. Not reading it is not enough; the type has to make it
impossible.

**C4.** `TABLE[key] ?? [0, 0]` turns “I forgot a stage” into a zero that propagates without noise.

**C5.** `typescript` was installed, with its configuration and type documentation all over the
code, and no command ran it. The repo pretended to have a control that did not exist.

**C6.** Three runs of the method: zero unused public symbols out of 276. The only deliverable with
dead code was the one a person reviewed, who left two constants hanging when moving a rule.

**C7.** The worst defect of four runs: an app parsed local storage without validating the shape.
Old data did not break at parsing: it broke the first render, left the screen blank and repeated on
every reload. *An error that persists across reload is not a bug: it is a lost app.*

**C8.** One run complied with the dependency direction by discipline and nothing forced it. The
architecture rule is loaded by path, and in four of six runs the repo did not use the paths it
expected: it was not loaded and nobody found out.

**C9.** GitClear measures the duplication of AI-generated code with a number, and it grows.
Reusability is one of the five parts of maintainability in ISO/IEC 25010, and duplication is what
measures it.

## Pause 4

**G1.** The eight security rows the method had before were its own; against ASVS, missing were,
among others, vulnerable dependencies, exposed `.git`, secrets in the URL, extra fields in
responses and skipping steps of a flow. 28 of the 70 level 1 requirements are about
authentication and sessions: in a product without users they stay at `not applicable`, with the
assumption that registered it.

**G2.** Measured in real runs: a declared timeout of 10 s with the connection still open at 25; a
declared 500 MB body that left the connection hanging for twenty seconds; `Host: evil.example`
answered with 200; a defense that let through whoever did not send origin headers; and a token that
withstood resending with a 409 but **three simultaneous submissions created three records** —it
was checked before a wait and marked after—. *A written timeout is not one that works.*

**G3.** Pearce and Perry found that AI code fails most in injection, cryptography, secrets and
dependencies. Models invent package names that do not exist, and somebody registers them.

**G4.** Pearce and Perry find secrets written in the code among the most frequent failures of
AI-generated code. A secret in git history is still there even if it is deleted from the file.

**G5.** It is NIST SSDF's *variant analysis*: a defect found once is almost never there only once.

**G6.** Three real defects that no test saw: an unescaped interpolated `<title>` —stored XSS from a
create—, a big body that cut the connection instead of answering, and an API served cacheable,
which behind a shared proxy hands one person the response of another.

**G7.** One app listened only on the machine and demanded the port through the environment; the
other was published on the whole network at first start. The same declared hole, contained in one
case and amplified in the other. A security assumption that lives only in the card's folder
protects nobody: whoever starts the app does not read it.

**G8.** ISO/IEC 27001, controls A.8.31 and A.8.33.

## Pause 5

**A1–A3.** One run had a navigation skip, visible focus, wired errors, 44 px targets and reduced
motion —all well decided— and **a single accessibility assertion in the whole suite**. The right
decisions nobody asserts last until the next rush.

**A4.** A color that passes by eye may not reach 4.5:1; computing it over the declared colors turns
it into a number. One run had the gray of the controls' borders at 1.31:1 against the 3:1 that
WCAG 1.4.11 asks for.

**A5.** With the system's high contrast, the browser replaces the colors: what separated by
background or shadow disappears, and it is not noticed by eye because the developer's screen is
not in that mode.

**A6–A7.** Automated analysis covers about a third of WCAG. “It passed the analysis” is not “it
meets AA”. Nobody grants the conformance report: the company issues it, and the method already
runs the tests that support it.

## Pause 6

**R1–R3.** They are three of ISO/IEC 25010's quality characteristics —performance, reliability and
compatibility— that the old rubric did not look at and the method did not check. One run parsed
the data file without validating its shape and started anyway, to die on the first screen; another
rejected it on opening without overwriting it. The difference was not visible in any functional
test.

## Pause 7

**M1.** One run closed saying “adding a stage = 2 files” and an outside count gave 7: it counted
the ones it had touched, not the ones that would have to be touched. Searching by name leaves out
the CSS grid with `repeat(4,…) repeat(2,…)`, which encodes the six without naming any stage. A
single change scenario can be chosen in one's favor; three to five fixed beforehand, no — it is
SEI's ATAM method.

**M2.** Two runs of the same kit: the one that chose each stage's color by its name needed four
files for a new stage and failed silently if the CSS was forgotten; the one that derived it from
position needed one line. Six against ten in maintainability.

**M3–M4.** A typed table with free keys left the compiler green with a missing key, and the gap
appeared as “42 against 40” when running. Forty hand-written records with their literal stage left
the new stage without data, and the e2e found out six minutes later.

**M5.** A count says how it is today; a test says it will stay that way.

**M6.** The run that reused the domain from the interface had 18 imports; the other two, zero, and
both had the rule copied.

**M7.** An isolated count says nothing; a series does. If the cost of adding a member keeps going
up from card to card, the rule is being copied and it is not yet noticeable in any of them.

**M8.** Ousterhout measures complexity as the information that whoever reads has to carry, and his
central criticism is of shallow modules: many small pieces that pass the call along without hiding
anything. The method writes smaller files than the control; that does not say whether they are deep
or shells. Ponytail flags wrappers that only delegate for the same reason.

## Pause 8

**F1.** The question “what is here that was not asked for?” was answered by the same agent that
wrote the code. Anthropic recommends that the review be done by someone who did not write it. Also,
in twenty evaluations nobody had scored whether the product did what the card asked: it is the
first characteristic of ISO/IEC 25010.

**F2.** See *why the why never justifies a ceiling*, at the very top.

**F3.** ISO/IEC 42001, control A.6.2.6: the record of what the AI system did.

**F4.** Three runs sent the validations to the background, wrote “I'll continue when they finish”
and there was no when they finish. A hook now prevents it, besides this line.

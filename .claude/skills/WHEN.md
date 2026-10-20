# Which skill goes at which moment

Reference. You do not need to read it to follow the method: each step of `METHOD.md` names its
own. This is useful when you have to choose between two, or justify why one was not run.

The skills for screens —`interface-design`, `find-animation-opportunities`, `build-awwwards-quality-sites`,
`cinematic-gsap-lenis-motion-system`, `apple-design`, `review-animations`, `/design-review` and
`/accessibility-audit`— come with the module ui (`.claude/kit.json`); without it there is no screen to look at.

They are not alternatives: they are **different moments**. Running them together over the same
change produces four reports that say the same thing and nobody reads any of them.

| Skill | When | What it looks at | Cost |
|---|---|---|---|
| `clean-architecture` | **Before coding**, in step 5, if there is a design decision | a proposal in natural language, not code | low |
| `interface-design` | **Before the screen**, in step 5, when writing the `## Visual brief` | product domain, focus, visual signature, tokens, states | low |
| `find-animation-opportunities` | **Step 5**, when writing the state changes of the screen in the design line | where something teleports, lacks feedback or continuity, and what should not move | low |
| `build-awwwards-quality-sites` · `cinematic-gsap-lenis-motion-system` | **Step 5 of a showcase card** (expression 8–10), when writing the design line, and step 6 for what the catalog does not cover | hero, GSAP and Lenis choreography, scroll storytelling | low |
| `apple-design` | **Reference**, when a component has physics —drag, sheet, switch, reorder— or materials | springs, interruption, momentum, translucency, reduced transparency | — |
| `review-animations` | **Step 9, if the card creates a screen or changes the component set**, in a subagent, with the contact sheets of `motion-audit.mjs` | the motion code and how it looks: purpose, frequency, curves, origin, interruption | low |
| `.claude/rules/architecture.md` | **Before merging**, in step 7 — it is not invoked, it loads by itself | the five rules of the stack, with their `grep`s | free until touching `apps/**`, `src/**`, `packages/**` or `lib/**` |
| `/design-review` | **Step 8, if the card creates a screen or a component** | the component's code: tokens, consistency, generic patterns, declared breakpoints | low |
| `/accessibility-audit` | **Step 8, if the card creates a screen or a component** | the code: semantics, focus, keyboard, ARIA, declared contrast. It audits against WCAG 2.1 AA; the kit's target is 2.2 AA, so the five criteria of I14 and the manual protocol of I15 are checked apart (`.claude/reference/accessibility.md`, module ui) | low |
| `/architecture-review` | **Outside a card's cycle** | the whole repo, 5 phases, SOLID one by one + scalability at 10× | **high** |
| `/beyond-solid-principles` | **On demand**, for a specific smell | whatever you point it at, by principle | medium/high |

**Optional figure skills (module docs).** They are not installed or vendored by the kit: a project that
wants one installs it and pins a commit (`skills/PROVENANCE.md`). None goes by default and none replaces
a diagram as code (Mermaid, D2, Structurizr, LikeC4) when that is enough. Each is chosen by the question
the figure answers (module docs: `reference/documentation.md`, Choosing a figure; DOC-24, DOC-26), is asked for by the
card or decided in the plan, carries its **own cap** in `## Time plan` apart from the card's, and has a
static fallback.

| Skill | When | Cost | Check |
|---|---|---|---|
| `diagram-design` | **Step 5–6**, a static editorial figure or a quantitative one with a real scale, when Mermaid and D2 fall short: business docs, onboarding | no published cost [NV]; Python, Google fonts by default | `self_check.py --offline` exits 0 (no external fonts in published docs) [NV flags] and the checklist “the figure explains” |
| `archify` | **Step 5–6**, a navigable architecture map with links to the source, or the architecture delta of a pull request | no published cost [NV]; Node; an optional update check over the network to disable or declare in CI | the JSON spec (`<name>.archify.json`) validates and counts as the render; the HTML regenerates with no diff |
| `anatomy` | **Step 5–6**, a hard concept that is a **mechanism** with real numbers from a model, for an explanation or onboarding page | up to 1 h for a small figure, 2–4 h a dense one (its SKILL.md); tokens not published [NV] | its build and audit exit 0, a capture at 390 px and dark, a human signs the metaphor; the tier is Figure only |

Install, only in the project that wants it: `npx skills add tt-a1i/archify -g`;
`npx skills add cathrynlavery/diagram-design` and `npx skills add wheresryan22/anatomy` [NV form]. The
`build.mjs` of a figure lives under `docs/` and is documentation, not production code.

A change to a screen that already exists is covered by the inspector —areas I and C— and the design
checks of `verify.mjs`.

**The UI ones read code, not screen.** None opens a browser or takes a capture, so **none
replaces step 9**: they review what is decided by writing the component —a contrast declared in
a token, a missing `aria-label`, twelve identical cards—, not what only appears when the browser
composes the page. The five defects that motivated step 9 are all in the second category.

**The split of the UI ones, which is easy to confuse.** Four moments and three different
objects:

| | When | Over what | What it asks |
|---|---|---|---|
| `interface-design` | step 5, when writing the brief | nothing yet — it decides | what is the focus and signature of this screen? |
| `/design-review` · `/accessibility-audit` | step 8 | the component's **code** | is it coherent with its own tokens? |
| `/design-deslop` | step 9, with the captures | the **render**, and only afterwards the diff | does it show that a model generated it? |
| `review-animations` | step 9, with the contact sheets | the **motion** | does every change have a designed response, and none for its own sake? |
| **a person** | step 9, before closing | the strip against what came before | **is it better, or only different?** |

**The last row is covered by no skill, and it is the one that was most missed.** The three judge
a build against a bar; none compares against the previous version. *Measured:* a screen came out
more distinctive and worse with all three reviews green.

Running the review ones without having written the brief is asking a reviewer to guess what to
compare against: all it can flag is internal incoherence, not whether the screen came out
generic.

**The two at the bottom do not go in a card's cycle.** `/architecture-review` sweeps the whole
repo and produces a long report: it is useful for onboarding, for an audit before a release, or
to plan a big refactor. Running it per card is paying for a repo audit to review fifteen files.

**`/beyond-solid-principles` is the only one that looks at what is not layers** — DRY, Law of
Demeter, KISS, YAGNI, resilience (timeouts, retries, circuit breakers), evolvability. Invoke it
by principle (`sw-dry`, `sw-demeter`, `sw-coupling`) when you suspect something specific; asking
it for all ten costs as much as a full audit.

**And the built-in that always goes**, in step 8: `/code-review`, which looks for bugs and also
reuse and simplification. `/simplify` does only the second half, so it is not run separately:
*measured*, in one card the only thing it found was a duplicated header that `/code-review` also
saw.

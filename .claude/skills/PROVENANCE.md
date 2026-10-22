# Where each skill came from and under what license

This repo is a template: what is here is copied to client projects. A skill without a verifiable
origin cannot be updated, and one without a license cannot be distributed.

**Everything vendored is MIT, verified in the upstream's `LICENSE` —not in the README or the
frontmatter—** on 21/09/2026.

| Skill | Upstream | License | How it came in |
|---|---|---|---|
| `interface-design` | `Dammyjay93/interface-design` | MIT | `npx skills add` → `skills-lock.json` with hash |
| `clean-architecture` | `tokenaissance/clean-architecture` | MIT (ships `LICENSE`) | `npx skills add` → `skills-lock.json` with hash |
| `architecture-review` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | manual copy |
| `design-review` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | manual copy |
| `accessibility-audit` | `tansuasici/claude-code-kit` | MIT, Tansu Asici | manual copy |
| `beyond-solid-principles` | `florianbuetow` (marketplace) | MIT | manual copy |
| `speckit-*` (10) | `github/spec-kit` | MIT, GitHub Inc. | `specify init` |
| `apple-design`, `find-animation-opportunities`, `review-animations` | `emilkowalski/skills` | MIT, Emil Kowalski (`LICENSE` copied into each) | manual copy, 06/10/2026 |
| `build-awwwards-quality-sites`, `cinematic-gsap-lenis-motion-system` | `MengTo/skills` (`agent-skills/web-design/`) | MIT, Meng To (`LICENSE` copied into each) | manual copy, 07/10/2026 |

| Command | Upstream | License |
|---|---|---|
| `.claude/commands/design-deslop.md` (module ui) | `Dammyjay93/interface-design` | MIT |

`card.md`, `scenarios.md`, `validate.md` and `close.md` are our own.

`/code-review` and `/simplify` **come with Claude Code**: they are not in this kit and there is no
need to look for them here.

## What is not a skill

| File | From where | License |
|---|---|---|
| `.claude/templates/asvs-level-1.md` and `asvs-level-2.md` | **OWASP ASVS 5.0.0**, the level 1 requirements and those level 2 adds, unmodified, from the official CSV at `github.com/OWASP/ASVS` | **CC BY-SA 4.0** — if the text of the requirements is modified, the modified version is published under the same license |
| `.claude/tools/mutate.mjs` | our own | — |
| `.claude/tools/once.mjs` | our own | — |
| `.claude/tools/attack.mjs` | our own | — |
| The coverage and duplication thresholds of the gate (`stacks/`) | the **Sonar way** quality gate of SonarQube: no new issues, security hotspots reviewed, coverage of 80 % or more and duplication of 3 % or less over the new code | — |
| The gate's static-analysis line with Semgrep | Semgrep Community Edition rules use the *Semgrep Rules License v1.0*: internal use, not for competing nor for a SaaS service | see the license before using it for a client |
| The ladder of `.claude/rules/architecture.md` —reuse, standard library, platform, installed dependency— | the idea is from **Ponytail** (`github.com/DietrichGebert/ponytail`); the wording is our own and leaves out its testing doctrine | — |

**`design-review`** is the one from `claude-code-kit`; **`interface-design`**, the one from
`Dammyjay93`.

## Optional figure skills: not vendored, not installed

Module docs names three skills a project may install for a figure (module docs `reference/documentation.md` DOC-24 and DOC-26). The kit carries none of them; the license was read
from the upstream's repository data on 14/10/2026, and the project that installs one verifies the
`LICENSE` file itself (see the rule below) and pins a commit.

| Skill | Upstream | License | How a project installs it |
|---|---|---|---|
| `anatomy` | `wheresryan22/anatomy` (created 08/10/2026, v1.1.0) | MIT, © 2026 Ryan | `npx skills add wheresryan22/anatomy` [NV form]; pin the commit |
| `diagram-design` | `cathrynlavery/diagram-design` | MIT | `npx skills add cathrynlavery/diagram-design` [NV form]; pin the commit |
| `archify` | `tt-a1i/archify` (v3.1.0) | MIT | `npx skills add tt-a1i/archify -g` |

## The rule

**Before vendoring: license verified in the upstream's file, and a way to download it again.**
Prefer `npx skills add`, which leaves the entry in `skills-lock.json` with a hash; if it is
copied by hand, the row goes here.

It is not enough for the frontmatter to declare a license: a case was seen pointing to a
`LICENSE.txt` that did not exist anywhere. **The file is verified, not the promise.**

`skills-lock.json` only covers what was installed with the tool —today 2 of 16—, so **this
document is the record, not the lockfile.**

## Component libraries: installed per project, never copied here

The catalog of `reference/components.md` (module ui) names components of shadcn/ui (MIT), coss ui (MIT, only its
`apps/ui`), React Aria (Apache-2.0), Magic UI (MIT), Aceternity (MIT core; Pro not used), Motion
Primitives (MIT), Animate UI (MIT + Commons Clause) and Kokonut UI (MIT, free components). They are
not vendored in the kit: each project installs what it uses with the shadcn CLI, and its license
travels with the code into that project. Animate UI's Commons Clause forbids reselling its components
as such, which a client project does not do.

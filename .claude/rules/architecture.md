---
paths: ["apps/**","src/**","packages/**","lib/**"]
---

# Architecture

With that frontmatter these rules are loaded only when one of those files is touched; without it,
they are paid for in every session. Adjust them to the repo's real structure — **and in the first
card of a new repo that is part of the work**, because it is the card that invents the structure.

*Measured, and it is the reason this is written up here and not at the end:* the kit came with
`apps/api/**` and `apps/web/**`, and out of six runs of the method itself **four chose
`apps/crm/`**. In those four the rule was never loaded — and nobody noticed, because **a rule that
is activated by path does not warn you when it is not activated**: there is no error, no warning,
simply nothing happens.

*What did work, and why the critical content does not live only here:* the dependency-direction
test was written anyway by the runs where this rule was not loaded, because the obligation is also
in `/validate`, which is always invoked. **What rests on a single door is lost when that door does
not open.**

## The five that matter

They are the ones that cost the most and that no generic linter catches.

1. **A controller does not talk to persistence.** Whoever receives the request validates it,
   delegates to a use case and responds; it does not import the ORM, the database client or the
   table models. *In NestJS with Sequelize: nothing under `*.controller.ts` imports `sequelize` or
   a `*.model.ts`.*
2. **The domain carries no appearance — but it does carry the name.** A color, an icon, a column
   width or a date format inside the rules layer means that **a new screen with another palette
   can no longer use that domain**. Measured: the stages table carried `color: '#7a889c'`.

   **The cut is at “how it looks”, not at “what it is called”.** That the stage knows it is called
   *Negotiation* is business vocabulary and saves a parallel map that has to be kept up to date.
   Measured with two runs of the same kit: the one that took the name out of the domain gained one
   design point and **lost three of maintainability** —the test change cost it 8 files against
   4—, because each new stage also needed its entry in the label map. *A principle that charges
   three points where it wins one is badly applied.*

   The exception is **translated** text: if there is more than one language, the label is
   presentation and goes out, because there the map exists anyway.
3. **The domain does not import infrastructure.** Nothing under `**/domain/**` imports an external
   SDK, the ORM, HTTP, a queue or the file system. If a business rule needs a piece of data from
   outside, it receives it as a parameter.
4. **Modules do not import each other in a circle.** If `clients` imports `requests` and
   `requests` imports `clients`, there is a third thing neither of them saw. Take it out to a
   shared module or invert the dependency.
5. **A service does one thing.** If to explain what it does you use “and” more than twice, they are
   two services. It is not a line rule: it is about reasons to change it.

## Dependency direction

```
interface (controllers, pages) → application (use cases) → domain (entities, rules)
infrastructure (Sequelize, HTTP, queues) → domain
```

The arrows point inward and **never the other way round**. The domain knows nobody.

## Module boundaries

You import another module's public index, never its inside:
`import { X } from '../clients'` yes; `import { X } from '../clients/infrastructure/client.model'` no.
The index exports types and interfaces.

- **Each module owns its tables**; nobody else reads or writes them.
- **Cross effects** go through the other module's interface or through an event. In the front end, through
  props, events or a public API: never a `querySelector` inside another component, nor its internal state.
- **A non-trivial library** (ORM, HTTP client, payments, mail, PDF, queues) is used behind an adapter
  module in infrastructure, with names from the domain; domain and application do not import it. The
  exceptions are the standard library, the web framework in the interface layer and the pure utilities
  declared in `system-design.md`.

The rules with their sources and checks are in `.claude/reference/architecture.md`; when a pattern
is in doubt, `.claude/reference/code-patterns.md`.

## Before writing a new piece, in this order

1. **Does it already exist in the repo?** It is reused. Two implementations of the same thing is
   the copied rule that later diverges.
2. **Does the standard library bring it?** `node:crypto` for a token, `URL` to parse, `Intl` to
   format. Writing it by hand is maintaining what others already maintain.
3. **Does the platform do it?** `required` and `type="email"` before a JavaScript validation;
   `<details>` before an accordion; a uniqueness constraint in the database before a check in the
   code. **The native comes with accessibility and with edge cases you will not remember to
   write.**
4. **Does a dependency that is already there cover it?** Adding a new one for one function is
   adding a tree.
5. Only then, **the minimum that works.**

*The ladder is Ponytail's, validated by others —10% less cost with the same success rate over 80
paired tasks— and **it does not apply to what this method explicitly asks for**: edge validation,
error handling, security, accessibility and the tests of `/validate` are not “extra” code, they
are the product. Ponytail itself excludes them; it is clarified here because an agent that
receives “write the minimum” and “write these tests” picks one of the two if nobody tells it
which one rules.*

## What not to do in the name of architecture

These weigh as much as the ones above, because the mistake of overdesigning is more expensive to
undo than that of underdesigning.

- **Do not create an interface to satisfy DIP.** An interface with a single implementation and no
  second consumer in sight is indirection, not decoupling. The adapter that isolates a library is a
  **module** with names from the domain; an interface type only if a test needs a fake of it (the
  exception of D6) or there is a second implementation.
- **Do not add an event bus for a single consumer.** An event only when the emitter must not know the
  receiver.
- **Do not make a generic repository** if a domain repository expresses the intent better.
  `findByTaxId()` says something; `findOne(criteria)` does not.
- **Do not introduce an abstraction until you have a concrete reason.** Two uses are not a pattern.
- **Do not turn a CRUD into hexagonal.** If the card is a CRUD, deliver a CRUD.

## How it is reviewed

`/code-review` for the diff: bugs and cleanup in a single pass.

**And the dependency direction is asserted with a test, not eyeballed.** A review in the PR holds
as long as somebody remembers; the arrow gets inverted in the rushed commit of a Tuesday and then
there is nobody to notice it. The test is ten lines and needs no dependency: it reads the imports
of each layer and fails if they point outward.

```
domain/       imports nothing from outside domain/
application/  does not import from infra/ or interface/
interface/    does not import from infra/
```

Measured: a run complied with the three by discipline and **nothing forced it** — the application
layer imported the store's concrete class and the views queried the raw data. Both things passed
all the tests and were found by an outside reviewer reading. *A property that only holds because
someone remembers it is already a lost property; the only difference is when you find out.*

The same test also asserts that a module is imported only through its public index, that each table is
touched only by its owner module (the “table → owner module” of `docs/technical/system-design.md`) and
that domain and application import no library outside the declared allow-list; cycles are C10.

In a large repo the tool is `dependency-cruiser` with a `.dependency-cruiser.js` that encodes
these same arrows, running in the default command. In a small one, the hand-written test is
enough. What is not enough is the review.

## The compiler at its maximum strictness

The stack's type checker, **in its strictest mode** —which one it is and how it is configured is
in `.claude/stacks/<stack>.md`—. What the strict mode catches and the normal one does not is not
always the same: access to a list or a map treated as if the element were always there, and a null
that propagates. The answer to that lie is usually a suppression that covers it up instead of
handling it.

The same from the other side: **a `!`, an `as any` or a `@ts-ignore` is the compiler warning and
somebody covering its mouth.** They are removed; the one that survives carries a line saying why.

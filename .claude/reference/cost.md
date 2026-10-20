# What a card costs, and where it comes from

**Before reading any of this: you do not optimize by removing checks.** What makes this method
worth it is that it tells you **everything** that has to be taken into account — whoever codes
does not have to remember accessibility, the origin of the request, the date that cannot be
reconstructed later. Removing a row from a table to save two dollars destroys exactly that.
*What is optimized is how the list is executed, never what the list contains.*

## How the bill is made

Each request re-sends the whole context. With caching, re-reading costs $0.20 per million tokens
in Opus 5.5 and in Sonnet 5.5 alike; writing new content to the cache costs $8 (Opus) or $4
(Sonnet) per million with a one-hour lifetime, $5 or $2.50 with five minutes; output, thinking
included, $20 or $10.

*Measured on three cards of the current kit:* about 170 requests each, the main thread's context
growing from 28 to 200 thousand tokens, $4.86 to $5.45 of main thread. Of that, 43 % was re-reading,
31 % writing to the cache and 26 % output. The subagents —reviewer, inspector, runners— added
between a quarter and a third more.

Everything that enters the main thread is paid again on every request that follows: a raw output
read at request 50 of 170 is paid 120 times. Half of what entered and was re-read were documents
of the kit read at the start; the rest, command output, screenshots and the code itself.

## What comes out of that, in order of weight

- **The main thread does not write code.** The `implementer` writes it in its own context, in
  Sonnet, starting from the plan and the tests. Two thirds of a card's requests were writing and
  verifying.
- **Long output does not come in.** Tests, builds, installs and logs go to `runner`, or are
  trimmed before entering. *Measured: runs used `Agent` four times in five hundred requests and
  swallowed the output of seventy commands.*
- **Documents are read when their step arrives, and only the part that is needed.** A document
  read at request 150 is re-read 20 times; at request 10, 160 times. The bar is written from
  `tools/bar.mjs`, not from the whole `criteria.md`.
- **Write the whole file, do not edit it ten times.** Two runs of the same kit with the same note:
  one made 115 `Edit`s and the other 4 `Edit`s and 53 `Write`s. The difference was 111 requests
  and $25.
- **Group what is independent into one call.** Three `grep`s that do not depend on each other are
  one request, not three.
- **The mechanical checks are not run by whoever decides.** The `/validate` list that is a
  command is executed by `verify.mjs` and by `runner`; the list is run in full all the same.
- **Prices and the web go to a `scout`.** The prices of a cost model and the web search that finds them
  are a `scout`'s task; the ADR that chooses between the alternatives is decided by the main thread.
- **The cache lifetime.** The main thread keeps one hour: a wait of more than five minutes with
  five-minute caching rewrites the whole context. *Measured: a small card spent 71 % of its $31 on
  fifteen rewrites of a 300-thousand-token context, all after waiting for Stryker, Excel or a
  subagent.* Subagents rarely sit idle for five minutes and keep five, except the `implementer`,
  which waits for suites.

## Which model, and why

**Delegate to the cheapest model whose output you can verify without redoing the work.** An exit
code is verified by looking at it; a judgment is not. That is why `executor` and `archivist` run
on haiku —they return numbers and transcripts—, `runner`, `scout`, `grunt` and `implementer` on
Sonnet, and `inspector`, `reviewer`, `planner` and `oracle` on Opus, `oracle` with `xhigh` effort.
**The main thread stays on Opus**: it writes the design line and the visual brief. *Measured: on
Sonnet it cost half, and the same screen scored 34 against 50 out of 60 in a blind comparison.*
The efforts are calibrated for generation 5.5, which at `medium` performs like the previous one at
`high`: when the generation changes they are recalibrated, not carried over.

*Measured:* a run delegated four tasks to `general-purpose`, which inherits Opus and the caller's
context, while `runner` and `grunt` were available on Sonnet. The generic one is the last resort.

*Every request not spent on re-reading is budget for one more check. That is the only direction
this moves in: more coverage for the same money, never less coverage for less money.*

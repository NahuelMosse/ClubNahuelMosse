# Why each rule of step 8 and of `/validate`'s procedure is there

What was measured for `steps/08-verify.md` and the batch procedure of `commands/validate.md`. The
reason of each checklist item is in `why-validate.md`. Read it when a rule looks like too much.

**One complete verification per chain of corrections.** About 40 % of the wall time from
implementing to closing was waiting for `verify.mjs` over code the next round was going to change;
one card launched it 10 times (254 min, 223 on the critical path).

**A single verdict.** With reviews, mechanical pauses and closing validations in stages, each one
found something and opened another lap; half the time of a card was spent waiting on validations in
a row.

**Everything goes out in one message.** A small card ran `verify.mjs` twice, fixing in between,
before launching the inspector; its 17 minutes came on top, and the card spent 35 of its 53 minutes
waiting. `sleep` and `until grep` loops cost about 100 minutes of a card.

**The verdict reviewer goes out with the inspector, before any correction.** The reviewer of a card
with a screen went out after the first round of `actions.md`, which forced a second round and a
third complete verification (CRM-7: 240 min and USD 36 against a bar of 180 min and USD 30).

**`design-review` in a subagent.** In the main thread it took 14 of the 31 minutes of a card that
added one text.

**The reports are saved in the repo.** A close said “clean-context review: meets” and “inspection:
24 meet, 0 fail”, and the external inspection failed it because that output was nowhere in the repo.

**Findings come as `ACT` lines.** Rewriting the findings into `actions.md` took the main thread 1.8
minutes of Opus.

**A finding reopens the card only with a failing proof.** A model reviewer always finds another
“what if…?”; the proof separates error from conjecture.

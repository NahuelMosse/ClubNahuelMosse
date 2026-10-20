# Why each rule of `/close` is there

What was measured for the rules of `commands/close.md`. Read it when a rule looks like too much.

**This is not step 8.** A run did step 8 by hand and then ran `/validate` again from `/close` —a
second inspector, a second review—, because the line only recognized the command. And a card that
only goes through the validations of the close closes green without anyone having looked at what was
written: they are about traceability and do not look at the code.

**Nothing of yours stays alive.** A run ended with background tasks alive and the process was cut
off waiting for them, with step 8 not run and the card not closed. It did not lose the work by luck.
A live process with no explanation is a hung process.

**The notices the repo asks for.** Two runs touched a file that says “DO NOT TOUCH without
telling …”; one noted it in the plan and neither left the notice where whoever has to read it reads
it.

**The session is recorded.** It is what ISO/IEC 42001 asks of the record of an AI system, and it is
the only thing that allows reconstructing afterwards who did what.

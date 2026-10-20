# Why each rule of step 5 is there

What was measured for the rules of `steps/05-plan.md`. Read it when a rule looks like too much.

**The verification lines come from what the card touches.** With fixed-size steps, a one-minute
card without the method took two hours with the method.

**The file map.** It is what makes implementing a matter of writing and not deciding.

**The bar lists every criterion by ID.** The agent wrote against one list and was inspected
against another, longer one; what was not on its list went undone.

**Changes to existing behavior.** One run started rejecting a method on a route that already
existed, and another touched a file that said “DO NOT TOUCH without notice”; neither declared it.

**The time plan.** Measured in teams, the complete quality process —tests first, review,
inspection— adds between 1.3 and 1.8 times the time (TDD at IBM and Microsoft, 15 to 35 % more;
code review, around 10 %; TSP, around 8 %); an agent also pays a fixed cost —re-reading context, the
reviewer in a clean context, the mechanical verification— that weighs more the smaller the card is.
In the method's runs the model generating was between 4 and 15 % of the time: the rest was waiting
—correcting actions 34 %, verification 25 %, tool installation 11 %, and `sleep` loops that came to
add up to six hours—. Time is not won by rushing at the end, which worsens the result: it is won by
planning what waits for what.

**The ADR only for an architecture change.** An ADR was written for a form of three fields.

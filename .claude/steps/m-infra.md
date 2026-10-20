# Module infra · what it adds to the steps

Read the section of the step you are on, only while `infra` is on in `.claude/kit.json`. It is about
what the app runs on. Its criteria: O13, O14, O24, O29, E14 and W5; its items: Q14 and R11 of
`.claude/reference/validate-mechanical.md`. The rules are in `.claude/reference/infrastructure.md`,
read by section.

## Step 1 · The first card of a repo

The ADR of the stack, `docs/technical/system-design.md` (the infrastructure as it is today, O14), the
cost model from `.claude/templates/infra-cost.md` (O13) and the runbook from
`.claude/templates/runbook.md` (W5) are born in the first card that adds infrastructure.

## Step 5 · The plan

A File map that names an infrastructure file —a Dockerfile, compose, Terraform, a chart, a platform
file— or a card that adds a package for a cloud service or a queue asks for: the ADR with its
alternatives (D14), the cost model updated with the prices read from the provider (COST rules of
`infrastructure.md` section 2; prices are asked of a `scout`, never remembered), and the line
`- System design: <what changes>`. The `- Infra cost:` and `- ADR:` lines settle a false positive
(`unchanged — <why>`).

## Step 6 · Implementing

One build artifact is promoted across environments (O24). A queue has a dead letter, a retry limit
and an alert (E14). Whoever starts the app sees the declared risk where they start it.

## Step 8 · Verifying

Q14: the image and the infrastructure code are scanned and the container does not run as root. R11:
the post-deploy smoke and the rollback work in staging, only when the card changes the deployment
(O29).

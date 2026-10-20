# Runbook

Saved as `docs/technical/runbook.md` (criterion W5). Written for someone who is tired and did not write the
system: short sentences, commands that can be pasted, symptoms before causes. Validated by a person other than
the author, with an owner and a review date. Deployment commands live here once; the system design links
this page and does not repeat them. Rules and checks: `reference/observability.md` (module observability; OBS-SUP-*),
`reference/security.md` (SEC-SECR-*, SEC-IR-*).

Owner: `<team or person>` · Last reviewed: `<date>` by `<person who did not write it>`

## Deploy

The one command or the pipeline job, the checks that gate it, how long it takes, how to see it finished.

## Roll back

The one command or the pipeline job that returns to the previous build, what it does not undo (migrations:
expand and contract make the previous build compatible), how to confirm the previous version is serving.

## Diagnose

First look: the service dashboard, the error rate and the last deploy. Then the logs and traces by
correlation id. The command or link for each.

## Alerts, by symptom

One section per alert, with a stable anchor that the alert links through `runbook_url`. First stop the
bleeding (roll back, divert traffic, disable the feature); the root cause comes after.

### <anchor>: <symptom in the user's words>

- **What the user sees:** …
- **Confirm:** what to look at first and what a real case looks like.
- **Mitigate:** the step that reduces the harm now, before any deep diagnosis.
- **Verify:** how to know it worked.
- **Escalate:** to whom, through which channel, in how long.
- **Communicate:** what to tell customers and when (see Communication).

## Support view

How support finds what happened to one customer or one order, with no access to production:

1. Ask the customer for the reference id the error showed.
2. Search that id in the logs: `<query or link>`; it returns the request, its trace and the error.
3. The view per customer or per order: the timeline of business events, the errors with their reference id,
   the state of the dependencies.
4. What each support level (N1, N2, N3) can see; personal data is masked and access is audited.

Each stable error code has an entry in the error catalog: meaning, probable cause, what to tell the customer,
when to escalate.

## Escalation matrix

| Severity | Support level | Who | Channel | In how long | Data package passed |
|---|---|---|---|---|---|

The package on escalating: error reference id or trace id, tenant, UTC time, what the customer expected, what
happened, steps to reproduce.

## Incidents

Declare an incident if the customer sees it, another team is needed, or it is unresolved after an hour. On
declaring: roles (lead, communications, scribe) and a living document with a UTC timeline.

## Communication

One template per state: Investigating, Identified, Monitoring, Resolved. First message within 5 minutes,
updates at least every 20 minutes in the first two hours, always with the time of the next one; the closing
says whether there was data loss.

## Secret rotation and revocation

For each secret of the inventory in `docs/technical/system-design.md`: who rotates it, how often, the steps,
and how to check the old value stopped working. On a leak, in this order: revoke everything exposed in the
same operation → issue the replacement → deploy → verify the old value fails (401 or 403) → clean the place of
the leak → review the use of the secret during the exposed window → record. Deleting the commit or restarting
the app revokes nothing.

## Security incident response

Phases: detect → contain → eradicate → recover → postmortem. Roles and contacts. Who assesses whether personal
data was involved. Legal notification decided beforehand: GDPR, the authority within 72 hours and the data
subjects if the risk is high; Argentina, Ley 25.326 does not require notification but the AAIP recommends it
**[NV in the primary source]**. Every breach is documented even if it is not notified; a blameless postmortem
follows, with impact, a timeline backed by data, causes and actions with an owner.

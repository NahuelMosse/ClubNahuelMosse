# Documentation assumptions

The assumptions that change what whoever uses the app sees or what whoever operates it does are in the READMEs of `apps/api` and
`apps/mobile`; the complete record of each use case, in `specs/<case>/ambiguedades.md`.

- REV-07-ASM-01: where the app does not have something yet (backups, measured service objectives, performance
  budget) the document says so as is and writes the objective as an unmeasured goal.
- REV-07-ASM-02: the READMEs of `apps/api` and `apps/mobile` list the assumptions that change what whoever uses it sees or what
  whoever operates it does, with their ID, and not all 545 recorded.
- REV-07-ASM-03: the data model carries the columns, keys, indexes and triggers of each table.
- REV-07-ASM-04: these documents are written even if the documentation module of the method is off, because the production
  grade requires them.
- REV-07-ASM-05: the documents describe `main`; the finding numbers they cite refer to the review of the `kit-3`
  branch.
- REV-07-ASM-06: the rows of the ASVS matrix that fail today stay `fails` with the finding and the card that fixes them; the
  remediation deadlines (V15.1.1) are decided by a person.
- REV-07-ASM-08: the prices come from https://render.com/pricing.md consulted on 2026-10-20; the page does not say whether the free
  database has backups.
- REV-07-ASM-09: the key policy with its life cycle, the complete cryptographic inventory and the document of the authentication
  paths (ASVS V11.1.1, V11.1.2, V6.1.3) were not requested and are decided by a person: those rows stay `fails`.

## Status

The general review of `main` is in [`specs/REVISION-main.md`](../specs/REVISION-main.md): what ran, what fails and what
should be done next. The previous one, of the `kit-3` branch, is still in `specs/REVISION-kit3.md`; cards `REV-01` to `REV-08`
fixed what it found.

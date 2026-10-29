# Equivalent mutants

- apps/mobile/lib/features/admin/domain/venue_rules.dart:14 · “.trim()” → “.trimRight()” · only `isEmpty` is read after it: a name of spaces alone is empty with either trim
- apps/mobile/lib/features/users/domain/registration_rules.dart:31 · “.trim()” → “.trimRight()” · only `isEmpty` is read after it: a date of spaces alone is empty with either trim

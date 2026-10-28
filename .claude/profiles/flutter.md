# Profile: flutter

Mobile screens in Flutter. The base method does not name a framework; this profile brings the instruments.

## What it brings
- Dart helpers copied to `test/kit/` of the Flutter package (the folder of the `pubspec.yaml` with `flutter:`: the repo root, or the shallowest one such as `apps/mobile/`): `kit_states.dart` (`kitGolden`), `kit_a11y.dart` (`kitA11y`), `kit_motion.dart` (`kitTrace`).
- Tools: `flutter-gate.mjs` (`flutter analyze` and `flutter test`; `--accept` adds `--update-goldens`), `motion-audit.mjs compare`, `motion-curves.mjs`.
- Agent: `designer` (its `## Flutter` section). Reference: `design-refs-mobile.md`.
- The SDK is looked up in the `PATH` and in `FLUTTER_ROOT`; without it the gate says `could not run: flutter is not in the PATH`.

## Gate lines it uses
- `golden <state>:` one per state of `## Look`, a `flutter test` whose test calls `kitGolden`.
- `a11y:` a `flutter test` that calls `kitA11y`.
- `motion:` a `flutter test` that calls `kitTrace`, when `## Look` declares movement.
- `flutter: node .claude/tools/flutter-gate.mjs`.
- No `probe`, axe, `enter-each`, `type-markup` or `overflow`: the goldens at three widths and `kitA11y` cover them.
- With `web` on too, a card whose `## Tasks` name only Dart files (no web screen) is checked the same way, with goldens and `kitA11y`: no probe, axe, dead-clicks or copy lint.
- The rounds' captures are the goldens, copied to `specs/<card>/rondas/r<k>/`; a card that only takes something off a screen writes `remove-only:` in `## Look` and has no rounds.
- Mutation over `.dart` is `could not run: mutate.mjs has no Dart operators`.

## Libraries and structure
- Features are folders, layers inside from the first file: `lib/features/<feature>/{presentation,domain,data}` (`application/` for a use case that orchestrates), the feature's door `<feature>.dart` at its root; `lib/shared/` holds the kernel. Never `lib/screens/`, `lib/widgets/`, `lib/models/` or `lib/services/` across features (`.claude/reference/structure.md`, «Flutter»).
- Solved problems use a library, the repo's choice first: persistence **drift**, DI **get_it** or **riverpod**, HTTP **dio**; the full list is in `stacks/others.md`.

## How to turn it on
- `node .claude/tools/install.mjs --profiles flutter` at install (a `pubspec.yaml` with `flutter:` suggests it).
- `node .claude/tools/kit.mjs profile on flutter --reason "..."` afterwards, between cards; a card that needs it to close adds `--card-open "<why>"`, recorded in its Log; `profile off flutter --reason "..."` removes the helpers if they are unchanged.
- With `web` on too (Flutter web), both sets of lines apply.
- With neither on, a `visual` card lists `lensesOff` in `risk.json`.

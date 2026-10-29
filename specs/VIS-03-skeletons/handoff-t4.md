# Handoff T4 (admin skeletons)

Done: RED committed (89c299b): `apps/mobile/test/skeletons_admin_test.dart`, 6 tests, they fail for the right reason
(no `ValueKey('skeleton-card')` frame, radius 12 vs 20, spinner on new space).

Blocked: every Write of a production file (`lib/**`) is refused by the PreToolUse hook:
"the card in progress (specs\VIS-03-skeletons\card.md) is missing ## Specs with a line `S1 · "<quote>"`".
The card does have `## Specs` with `- S1 · "los skeletons estan algunos mal hechos" · acceptance: ...` (checked); the hook
probably reads the card from the main repo (`CLAUDE_PROJECT_DIR`, whose `specs/.current` is ENG-16-app-en-ingles) or a
concurrent edit of card.md. Not worked around. The main thread must fix it, or write the files itself.

## Plan (all files in lib/features/admin/presentation/, nothing written yet)

- `admin_card_skeleton.dart`: `enum AdminCardShape {space, venue}`, `AdminCardSkeletons(shape, count 3)` = `SkeletonZone` + Column of
  `_Frame` (Container key `ValueKey('skeleton-card')`, padding 16, border `borderDefault`, radius `Spacing.radiusLg`; details
  blocks (space: 44x44 + 2 bars = 44 high; venue: 3 bars ~ 22+8+14+12+14), 12, Row of two `Skeleton(height: Spacing.controlHeight)` gap 8).
  Real heights: space card = 16+44+12+52+16 = 140; venue ~ 172 (calibrate with the test).
- `admin_listing.dart` line 68: replace `SkeletonList(venue)` by `AdminCardSkeletons(shape:)`; the template needs a new
  `AdminCardShape shape` param passed by the space and venue screens (grep `AdminListingTemplate(`).
- `admin_booking_card_skeleton.dart`: `adminBookingCardHeight` const (measure the real `AdminBookingCard` voidable, calibrate), 
  `AdminBookingCardSkeleton` frame (key `skeleton-card`, border, radius lg, fixed height, bars + button block at the bottom) and
  `NextPageSkeleton` = `SkeletonZone(Skeleton(height: adminBookingCardHeight, radius: Spacing.radiusLg))` (exactly one Skeleton, test ASM-04).
- `admin_panel_body.dart`: loadingMore -> `NextPageSkeleton` (keep padding vertical 16).
- `admin_bookings_loading.dart`: keep `Cargando reservas…` (liveRegion) and add below, in `SliverPadding(24,0,24,40)`, 3 `AdminBookingCardSkeleton`
  in a `SkeletonZone` with gap 12 (left/right/height must match the real card; top may differ: the text sits above).
- `new_space_skeleton.dart`: `NewSpaceSkeleton` = `SingleChildScrollView(NeverScrollable, padding: Spacing.formPagePadding)`,
  `spaceFormHeading(context, 'Nuevo espacio deportivo')`, then in a `SkeletonZone` 3 selector blocks, the CONDICIÓN/ILUMINACIÓN pair, price, name, buttons.
  Selector block height = real `SelectorField` height (calibrate: the test checks the first 5 blocks against `SelectorField` rects). 
- `new_space_screen.dart` line ~158: `const Center(child: CircularProgressIndicator())` -> `const NewSpaceSkeleton()`.
- Add the new files to the T4 line of card.md, plus `apps/mobile/test/capturas/skeletons_admin_capturas.dart`.

## Left after that

1. Run `sh D:/Temp/w/herramientas/flutter-mobile.sh test/skeletons_admin_test.dart test/admin/pantalla_panel_admin_test.dart`
   (background, log; the test mounts with `App` + `HeldApi`, never `pumpAndSettle` while held: the shimmer repeats).
2. Goldens: `test/capturas/skeletons_admin_capturas.dart` (dark 393x852, each loading state beside the loaded one, `--update-goldens`);
   regenerate `test/capturas/admin/reservas_cargando_{360,430}_{claro,oscuro}.png` via `reservas_admin_capturas.dart`.
3. `dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/skeletons_admin_test.dart`, `flutter analyze --no-pub apps/mobile`.
4. Log line `- L<n> · <date> · T4 · ...` in card.md. `integration_test/reservas/historial_global_test.dart` @CU-14-H01-09 needs the text kept.

# Handoff T1 (VIS-03), second builder

## Done
- RED committed (6ca2d37): `apps/mobile/test/skeletons_venues_test.dart` (4 tests, titles per card T1). It does not compile yet because the files below are missing: the right reason.

## Blocked
The `Write` hook refuses every production file: "the card in progress (specs\VIS-03-skeletons\card.md) is missing `## Specs` with a line `S1 · "..."`". The worktree card HAS `## Specs` with `- S1 · "..."` (lines 14-16, same format as templates/card.md), so the hook probably reads another card (the main repo cwd `app-tp`, not the worktree). The main thread must fix it or say where the hook looks; do not bypass it.

## Code to write (designed, nothing written; all under `apps/mobile/lib/features/venues/presentation/`)
- `space_card_skeleton.dart`: `SpaceCardSkeleton` = `CardFrame` > Column[Skeleton(h180,r0), Padding(16,16,16,0) SizedBox(h42) Row[2 pill Skeleton 84x24 gap4, Spacer, Skeleton 88x42], Padding(16,12,16,0) Skeleton(w220,h18), Padding(16) Skeleton(h controlHeight)]; `SpaceCardSkeletons` = Column of 2 cards, s16 gap, no zone (caller wraps in `SkeletonZone`).
- `venue_card_skeleton.dart`: `VenueCardSkeleton` = Material(bgSurface, radiusLg, clip) > Column[Skeleton(h158,r0), Padding(16) Row[2 pill 72x24, Spacer, Skeleton 96x20]].
- `venue_skeleton.dart`: `VenueSkeleton(onBack)` = Stack[SkeletonZone(SingleChildScrollView never-scroll > Column[Skeleton(h: MediaQuery top + 202, r0), Padding(24,24,24,40) body]), SafeArea(bottom:false) Padding(L12,T8) real TextButton.icon "Todas las sedes" (textPrimary, min 0x44, Texts.caption, chevron_left 20)]. Body = DEPORTE bar 64x14, s8, Wrap(spacing 8) of 3 pill Skeleton 100x48, s24, counter bar 180x14, s12, `SpaceCardSkeletons`. The test takes `skeletonRects.first` as the cover and `[2]` as the first chip; tune 202 / 42 until `expectSameBox` passes (height tolerance 8).
- `venue_screen.dart` (222-230): body = data != null ? VenueContent : _loading ? VenueSkeleton(onBack: () => context.go('/sedes')) : SafeArea(child: SizedBox.shrink()); drop the unused `skeleton.dart` import.
- `venue_content.dart` (156-161): `filtering ? SkeletonZone(key: ValueKey('carga'), child: SpaceCardSkeletons()) : SpaceList(...)`.
- `venues_screen.dart` (147-148): loading = SkeletonZone(Column[Skeleton(h18,w220) after the title (s4 above, s16 below), 3 VenueCardSkeleton separated by s16]); the test expects the real title "Sedes" to stay.
- Keep `SkeletonList`/`SkeletonShape` API intact (other tests and T3/T4 use it).

## Left after the code
Gate in background with a log: `sh D:/Temp/w/herramientas/flutter-mobile.sh test/skeletons_venues_test.dart`; `D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/skeletons_venues_test.dart apps/mobile/test/soporte/held_api.dart`; `D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile`. Also run `test/esqueletos_de_carga_test.dart` and `esqueletos_de_carga_pantallas_test.dart`.
Then `apps/mobile/test/capturas/skeletons_venues_capturas.dart` (rename it in the T1 line of card.md; add the 3 new skeleton files to that line): follow `capturas/sedes_usuario_capturas.dart` (`matchesGoldenFile`, `montarUsuario`, `rutasDeSedes`, `HeldApi`), 393x852 dark, one golden per loading state (sede, sede filtrando, Sedes) next to the loaded one, `--update-goldens`. `sedes_usuario_capturas.dart` shows only loaded states. Then the Log line `- L<n> · <date> · T1 · <evidence>`.

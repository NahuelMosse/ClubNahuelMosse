# Handoff T3 (bookings, venues, spaces)

Worktree D:/Temp/w/eng19-t3, branch ENG-19-t3. RED committed (be8c016).

## Done
- Domain: booking_status.dart (apiValue only), search_rules.dart (RangeProblem), venue.dart (WeekdaysLabel, OpenDays without text), space.dart (no condition/lighting/description), venue_summary.dart (sportsOf only).
- Text mappers: bookings/presentation/search_problem_texts.dart, booking_status_text.dart; venues/presentation/venue_texts.dart; spaces/presentation/space_texts.dart.
- .arb block (about 160 keys after loginPasswordLabel) and generated l10n files.
- Presentation converted to AppLocalizations: availability_screen, availability_space_card, booking_actions, booking_card, booking_confirmed_screen, booking_exit_bar, booking_receipt, booking_steps, booking_summary, bookings_tab_bar, cancel_confirmation, cancellation, confirm_booking_screen, confirm_change_screen, covered_filter, duration_picker, duration_section, modification_note, my_bookings_header, my_bookings_screen (textoDeCancelacion now takes l first), search_error_card, search_time_range, slot_card, space_search_bar, status_label; venues: venue_card, venue_card_cover, venue_card_footer, venue_content, venues_screen, labels_and_price, space_card, space_list.

## Left
- space_search_screen.dart: `_errores` converted (needs the imports of l10n and search_problem_texts); still has literals elsewhere (labels, placeholder, subtitle, results header, empty state, SELECT hints). Keys: spaceSearch*.
- venue_screen.dart, venue_skeleton.dart, availability_skeleton.dart and any other file the T5 scan (test/bilingual_app_test.dart) still lists under my folders.
- space_card.dart line 49 holds a leftover commented line to delete.
- Spanish copies of broken frozen tests: test/bookings_in_english_test.dart:103 (BookingStatus.label), test/buscar_cancha_test.dart:28 (rangeErrors strings, map through rangeProblemText with es), test/espacios_admin_test.dart:114 (space.description, admin is T4). Write replaces-T3.md.
- dart format, flutter analyze, run my tests: `sh D:/Temp/w/herramientas/flutter-mobile.sh test/bilingual_bookings_test.dart test/bilingual_replacements_test.dart` from the worktree root.
- Admin (T4) uses venue.daysLabel, weekdaysLabel, OpenDays.text, space.description(catalog): the parent must adapt it with weekdaysText/openDaysText/spaceDescription.

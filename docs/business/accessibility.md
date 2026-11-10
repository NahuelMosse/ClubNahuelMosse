# Accessibility of ClubNahuelMosse

ClubNahuelMosse wants everyone to be able to book a sports space from the app. This document says how much
has been achieved today, without embellishment: what was not tested appears as `not verified`.

## Standard

The app aims to meet WCAG 2.2 level AA. The legal context is Law 26.653 on the accessibility of information on
web pages, which informs the text; compliance with the law was not assessed.

## Conformance status

Partially conforms, as of 2026-10-20. The app is an Android Flutter application; the results use the
four terms of VPAT 2.5Rev INT.

| Area | Result (Supports, Partially Supports, Does Not Support, Not Applicable) | Notes |
|---|---|---|
| Keyboard operation | Partially Supports | in irreversible confirmations no button has `autofocus` and the first Tab lands on the destructive one (`apps/mobile/lib/common/error_dialog.dart`, finding 18, I24); the rest of the keyboard is `not verified` |
| Screen readers (reader and browser tested) | Partially Supports | semantics tests in widget tests (68 of 68 pass); TalkBack was not run: `not verified`. The error of each field is a separate node and the expected format ("DD / MM / YYYY") stays hidden from the reader (I7) |
| Zoom and reflow (200 % text, 320 px) | Partially Supports | 170 screenshots at 320 px and 170 at 200 % with no overflow exception; with text at 200 %, the bottom bar cuts "BOOKINGS" short (I9); 6 space-creation screenshots fail at 320×568, not analyzed (finding 27) |
| Color and contrast | Partially Supports | the dimmed button in dark mode gives 4.06:1 at 15 px bold, below AA (`apps/mobile/lib/common/button.dart`); the rest was not measured screen by screen |
| Forms and errors | Partially Supports | I7 and, when submitting the registration, it does not say what is missing (finding 17) |
| Time limits and motion | Partially Supports | the rejection of a booking shows in a 4 s SnackBar and the screen goes back at the same time (I20); motion is `not verified` |

## How it was assessed

The review of 2026-10-20 of the `kit-3` branch (`specs/REVISION-kit3.md`, findings 17, 18 and 27) was done by the development
team, without an external audit. What ran: 68 widget accessibility tests, which passed; golden screenshots of 85
views at 360 and 430 px in dark and light, 340 of 340 with no differences, and 170 at 320 px and 170 at 200 % with no
overflow exception; semantics and focus probes in widget tests for I7, I20 and I24. **What did not run:** TalkBack on a phone or
emulator (`not verified`), the keyboard test on a device, an iOS screen reader (the app is only built
for Android), nor an external audit.

## Per-screen register

One row per screen (`apps/mobile/lib/**/*_screen.dart`). "Supports" means no failure was found in
the widget tests or the screenshots; not that it was tested with TalkBack (`not verified` in all). References I7, I9, I20 and I24
are those of the review; the column says which one affects each screen.

| Screen | Result | What was found | Verified |
|---|---|---|---|
| `login_screen` | Partially Supports | I7: field errors as a separate node | widget tests and screenshots; TalkBack `not verified` |
| `registration_screen` | Partially Supports | I7; on submit, it does not say what is missing (finding 17) | widget tests and screenshots; TalkBack `not verified` |
| `registration_done_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `forgot_password_screen` | Partially Supports | I7 | widget tests and screenshots; TalkBack `not verified` |
| `new_password_screen` | Partially Supports | I7 | widget tests and screenshots; TalkBack `not verified` |
| `change_password_screen` | Partially Supports | I7 | widget tests and screenshots; TalkBack `not verified` |
| `my_profile_screen` | Partially Supports | I7; I9 (bottom bar); I24 in account deactivation | widget tests and screenshots; TalkBack `not verified` |
| `home_screen` | Partially Supports | I9 (bottom bar); I24 in cancellation | widget tests and screenshots; TalkBack `not verified` |
| `venues_screen` | Partially Supports | I9 (bottom bar) | widget tests and screenshots; TalkBack `not verified` |
| `venue_screen` | Partially Supports | I9 (bottom bar) | widget tests and screenshots; TalkBack `not verified` |
| `space_search_screen` | Partially Supports | I7 in date and hours | widget tests and screenshots; TalkBack `not verified` |
| `availability_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `confirm_booking_screen` | Partially Supports | I20: 4 s SnackBar with the screen going back | widget tests and screenshots; TalkBack `not verified` |
| `confirm_change_screen` | Partially Supports | I20 | widget tests and screenshots; TalkBack `not verified` |
| `booking_confirmed_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `my_bookings_screen` | Partially Supports | I9 (bottom bar); I24 in cancellation | widget tests and screenshots; TalkBack `not verified` |
| `notifications_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `access_denied_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `loading_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `admin_panel_screen` | Partially Supports | I9 ("SPACES" touches the edge at 200 %); I24 in deactivations | widget tests and screenshots; TalkBack `not verified` |
| `admin_venues_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `venue_form_screen` | Partially Supports | I7; contrast of the SAVE VENUE button (4.06:1 in dark); I24 in deactivation | widget tests and screenshots; TalkBack `not verified` |
| `venue_created_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `admin_spaces_screen` | Partially Supports | I24 in space deactivation | widget tests and screenshots; TalkBack `not verified` |
| `new_space_screen` | Partially Supports | I7; contrast of the SAVE SPACE button; 6 screenshots fail at 320×568 (not analyzed) | widget tests and screenshots; TalkBack `not verified` |
| `edit_space_screen` | Partially Supports | I7; contrast of the SAVE SPACE button; I24 in deactivation | widget tests and screenshots; TalkBack `not verified` |
| `space_created_screen` | Supports | no failures found | widget tests and screenshots; TalkBack `not verified` |
| `booking_filters_screen` | Partially Supports | I7 | widget tests and screenshots; TalkBack `not verified` |
| `booking_detail_screen` | Partially Supports | I24 in voiding a booking | widget tests and screenshots; TalkBack `not verified` |
| startup error (`resumeWithRetry` in `apps/mobile/lib/main.dart`) | Supports | no failures found (`apps/mobile/test/startup_no_connection_test.dart`) | widget tests; TalkBack `not verified` |

## Known limitations

- **Form errors (I7).** Affects all forms; whoever uses a screen reader does not hear the expected date format
  and finds the error in a separate node. Alternative: none written. Fix: pending a person.
- **Booking rejection (I20).** The notice lasts 4 s and the screen goes back at the same time: whoever needs more time may
  miss it. Alternative: the booking does not appear in "My bookings". Fix: pending a person.
- **Irreversible confirmations (I24).** No initial focus: with a keyboard, the first Tab lands on the destructive button. Fix:
  pending a person.
- **Text at 200 % (I9).** The bottom bar cuts "BOOKINGS" short and "SPACES" touches the edge. Fix: pending a person.
- **Contrast.** The dimmed button in dark, 4.06:1. Fix: pending a person.
- **Screen reader.** It was not tested with TalkBack, so there may be failures the widget tests do not see.

Who fixes each one and when is not decided: the request behind this documentation does not fix code.

## Feedback and contact

How to report an accessibility barrier, who answers and within what time: pending a person. Until it is decided,
tell whoever maintains the repository.

## Date

Last review: 2026-10-20, on the `kit-3` branch. It was done by the development team; it was not reviewed by an outside person.

// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
/// The app's clock: `clubNow` is the only place that reads it, and tests and screenshots
/// pin it with `withClock`.
library;

export 'club_timezone.dart' show clubNow;

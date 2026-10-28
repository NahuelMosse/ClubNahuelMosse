// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:clock/clock.dart';

/// The club is at UTC−3, with no daylight saving time: hours and days are counted that way
/// whatever the phone's zone is.
const _offset = Duration(hours: 3);

/// The [moment] seen from the club.
DateTime toClubTime(DateTime moment) => moment.toUtc().subtract(_offset);

/// The real instant of a club hour.
DateTime fromClubTime(DateTime clubTime) => clubTime.add(_offset);

/// The current moment at the club, whatever the phone's zone is.
DateTime clubNow() => toClubTime(clock.now());

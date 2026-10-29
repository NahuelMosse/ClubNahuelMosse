import 'package:clubnahuelmosse/common/dates.dart';
import 'package:clubnahuelmosse/features/notifications/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 12, 10);
  Arrival at(Duration ago) => arrivalOf(now.subtract(ago), now);

  test(
    'the arrival of a notice is a value the language turns into text: now, minutes, hours, yesterday or a date @ENG-19-S1',
    () {
      expect(at(Duration.zero), (when: ArrivalWhen.now, amount: 0, date: ''));
      expect(at(const Duration(seconds: 59)), (
        when: ArrivalWhen.now,
        amount: 0,
        date: '',
      ));
      expect(at(const Duration(minutes: 1)), (
        when: ArrivalWhen.minutesAgo,
        amount: 1,
        date: '',
      ));
      expect(at(const Duration(minutes: 59)), (
        when: ArrivalWhen.minutesAgo,
        amount: 59,
        date: '',
      ));
      expect(at(const Duration(minutes: 60)), (
        when: ArrivalWhen.hoursAgo,
        amount: 1,
        date: '',
      ));
      expect(at(const Duration(hours: 11)), (
        when: ArrivalWhen.yesterday,
        amount: 0,
        date: '',
      ));
      final older = DateTime(2026, 11, 9, 18);
      expect(arrivalOf(older, now), (
        when: ArrivalWhen.date,
        amount: 0,
        date: dayAndMonth(older),
      ));
    },
  );

  test(
    'the day group of a notice is today, yesterday or its date @ENG-19-S1',
    () {
      expect(dayOf(DateTime(2026, 11, 12, 8), now), (
        when: ArrivalWhen.today,
        amount: 0,
        date: '',
      ));
      expect(dayOf(DateTime(2026, 11, 11, 8), now), (
        when: ArrivalWhen.yesterday,
        amount: 0,
        date: '',
      ));
      final older = DateTime(2026, 11, 1, 8);
      expect(dayOf(older, now), (
        when: ArrivalWhen.date,
        amount: 0,
        date: dayAndMonth(older),
      ));
    },
  );
}

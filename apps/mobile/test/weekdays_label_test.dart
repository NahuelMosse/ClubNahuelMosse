import 'package:clubnahuelmosse/features/venues/domain/weekdays_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loose days keep Monday and Sunday and drop what is not a weekday @ENG-19-ASM-05',
    () {
      expect(weekdaysLabel([7, 1, 0, 8, 1]), const WeekdaysLabel(null, [1, 7]));
      expect(weekdaysLabel([1]).days, [1]);
      expect(weekdaysLabel([7]).days, [7]);
    },
  );

  test(
    'five days that are not Monday to Friday stay loose days @ENG-19-ASM-05',
    () {
      expect(
        weekdaysLabel([1, 2, 3, 4, 6]),
        const WeekdaysLabel(null, [1, 2, 3, 4, 6]),
      );
    },
  );
}

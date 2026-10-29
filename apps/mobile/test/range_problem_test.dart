import 'package:clubnahuelmosse/features/bookings/domain/search_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a search problem is a value: same kind and datum are equal, any difference is not @ENG-19-ASM-05',
    () {
      const tooFar = RangeProblem(RangeProblemKind.dateTooFar, 30);
      expect(tooFar, const RangeProblem(RangeProblemKind.dateTooFar, 30));
      expect(
        tooFar.hashCode,
        const RangeProblem(RangeProblemKind.dateTooFar, 30).hashCode,
      );
      expect(
        tooFar == const RangeProblem(RangeProblemKind.datePast, 30),
        isFalse,
      );
      expect(
        tooFar == const RangeProblem(RangeProblemKind.dateTooFar, 31),
        isFalse,
      );
    },
  );
}

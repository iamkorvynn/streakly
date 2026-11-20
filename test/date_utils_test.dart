import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/utils/date_utils.dart';

void main() {
  group('dateOnly', () {
    test('strips the time component', () {
      final stripped = dateOnly(DateTime(2026, 11, 20, 14, 30, 45));
      expect(stripped, DateTime(2026, 11, 20));
    });
  });

  group('isSameDay', () {
    test('same day different times is true', () {
      expect(
        isSameDay(
          DateTime(2026, 11, 20, 8),
          DateTime(2026, 11, 20, 23, 59),
        ),
        isTrue,
      );
    });

    test('adjacent days is false', () {
      expect(
        isSameDay(DateTime(2026, 11, 20), DateTime(2026, 11, 21)),
        isFalse,
      );
    });
  });

  group('toDateKey / parseDateKey', () {
    test('round-trips a date', () {
      const key = '2026-11-20';
      expect(toDateKey(DateTime(2026, 11, 20)), key);
      expect(parseDateKey(key), DateTime(2026, 11, 20));
    });

    test('zero-pads month and day', () {
      expect(toDateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('lastNDays', () {
    test('returns n days ending today, oldest first', () {
      final days = lastNDays(3, today: DateTime(2026, 11, 20));
      expect(days, [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      ]);
    });
  });

  group('startOfWeek', () {
    test('Friday 2026-11-20 starts Monday 2026-11-16', () {
      expect(
        startOfWeek(DateTime(2026, 11, 20)),
        DateTime(2026, 11, 16),
      );
    });

    test('a Monday is its own week start', () {
      expect(
        startOfWeek(DateTime(2026, 11, 16)),
        DateTime(2026, 11, 16),
      );
    });
  });

  group('daysInMonth', () {
    test('November has 30 days', () {
      expect(daysInMonth(2026, 11), 30);
    });

    test('February 2026 has 28 days, February 2028 has 29', () {
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2028, 2), 29);
    });

    test('December has 31 days', () {
      expect(daysInMonth(2026, 12), 31);
    });
  });
}

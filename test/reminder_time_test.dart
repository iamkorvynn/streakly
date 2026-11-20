import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/utils/reminder_time.dart';

void main() {
  group('nextReminderDateTime', () {
    test('reminder later today returns today', () {
      final now = DateTime(2026, 11, 20, 7, 0);
      expect(nextReminderDateTime(now, 8 * 60 + 30), DateTime(2026, 11, 20, 8, 30));
    });

    test('reminder already passed returns tomorrow', () {
      final now = DateTime(2026, 11, 20, 9, 0);
      expect(nextReminderDateTime(now, 8 * 60 + 30), DateTime(2026, 11, 21, 8, 30));
    });

    test('reminder exactly now returns tomorrow', () {
      final now = DateTime(2026, 11, 20, 8, 30);
      expect(nextReminderDateTime(now, 8 * 60 + 30), DateTime(2026, 11, 21, 8, 30));
    });

    test('midnight reminder rolls to tomorrow after midnight', () {
      final now = DateTime(2026, 11, 20, 0, 1);
      expect(nextReminderDateTime(now, 0), DateTime(2026, 11, 21, 0, 0));
    });

    test('late-night reminder today when now is early evening', () {
      final now = DateTime(2026, 11, 20, 18, 0);
      expect(nextReminderDateTime(now, 22 * 60), DateTime(2026, 11, 20, 22, 0));
    });
  });

  group('formatReminderMinutes', () {
    test('formats 8:30', () {
      expect(formatReminderMinutes(8 * 60 + 30), '08:30');
    });

    test('formats midnight', () {
      expect(formatReminderMinutes(0), '00:00');
    });

    test('formats 23:59', () {
      expect(formatReminderMinutes(23 * 60 + 59), '23:59');
    });
  });

  group('formatReminderMinutes12h', () {
    test('8:30 AM', () {
      expect(formatReminderMinutes12h(8 * 60 + 30), '8:30 AM');
    });

    test('noon is 12:00 PM', () {
      expect(formatReminderMinutes12h(12 * 60), '12:00 PM');
    });

    test('midnight is 12:00 AM', () {
      expect(formatReminderMinutes12h(0), '12:00 AM');
    });

    test('9:05 PM', () {
      expect(formatReminderMinutes12h(21 * 60 + 5), '9:05 PM');
    });
  });

  group('minutesFromHourMinute', () {
    test('8:30 is 510 minutes', () {
      expect(minutesFromHourMinute(8, 30), 510);
    });
  });
}

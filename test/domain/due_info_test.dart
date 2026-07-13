import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/domain/due_info.dart';

void main() {
  // Late evening on purpose: proves calendar-day truncation beats
  // time-of-day off-by-ones.
  final now = DateTime(2026, 7, 13, 23, 45);

  group('computeDueInfo', () {
    test('future date → due in N days', () {
      final info = computeDueInfo(DateTime(2026, 7, 16), now);
      expect(info.days, 3);
      expect(info.label, 'Due in 3 days');
      expect(info.isOverdue, isFalse);
      expect(info.needsAttention, isFalse);
    });

    test('tomorrow early morning is still "Due tomorrow"', () {
      final info = computeDueInfo(DateTime(2026, 7, 14, 0, 30), now);
      expect(info.days, 1);
      expect(info.label, 'Due tomorrow');
    });

    test('same calendar day → due today, needs attention', () {
      final info = computeDueInfo(DateTime(2026, 7, 13, 8, 0), now);
      expect(info.days, 0);
      expect(info.isDueToday, isTrue);
      expect(info.label, 'Due today');
      expect(info.needsAttention, isTrue);
    });

    test('yesterday → overdue by 1 day', () {
      final info = computeDueInfo(DateTime(2026, 7, 12), now);
      expect(info.days, -1);
      expect(info.isOverdue, isTrue);
      expect(info.label, 'Overdue by 1 day');
    });

    test('five days ago → overdue by 5 days', () {
      final info = computeDueInfo(DateTime(2026, 7, 8), now);
      expect(info.label, 'Overdue by 5 days');
      expect(info.needsAttention, isTrue);
    });
  });
}

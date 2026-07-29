import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/domain/date_range.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 12, day);

  group('DateRange', () {
    test('nights counts charged days, not calendar endpoints', () {
      expect(DateRange(d(12), d(15)).nights, 3);
      expect(DateRange.day(d(12)).nights, 1);
      expect(DateRange.nights(d(12), 4).nights, 4);
      expect(DateRange.nights(d(12), 4).end, d(16));
    });

    test('times are discarded — a rental day is a calendar day', () {
      final withTime = DateRange(
        DateTime(2026, 12, 12, 23, 59),
        DateTime(2026, 12, 15, 0, 1),
      );
      expect(withTime.start, d(12));
      expect(withTime.end, d(15));
      expect(withTime, DateRange(d(12), d(15)));
    });

    group('overlaps', () {
      test('ranges sharing days overlap', () {
        expect(DateRange(d(12), d(15)).overlaps(DateRange(d(14), d(18))), isTrue);
        expect(DateRange(d(14), d(18)).overlaps(DateRange(d(12), d(15))), isTrue);
      });

      test('a contained range overlaps', () {
        expect(DateRange(d(12), d(20)).overlaps(DateRange(d(14), d(16))), isTrue);
      });

      test('identical ranges overlap', () {
        expect(DateRange(d(12), d(15)).overlaps(DateRange(d(12), d(15))), isTrue);
      });

      test('back-to-back ranges do NOT overlap', () {
        // The reason for half-open ranges: the 15th is free for the next
        // renter, so a same-day handover is not a double-booking.
        final first = DateRange(d(12), d(15));
        final next = DateRange(d(15), d(18));
        expect(first.overlaps(next), isFalse);
        expect(first.isAdjacentTo(next), isTrue);
      });

      test('separated ranges do not overlap', () {
        expect(DateRange(d(12), d(15)).overlaps(DateRange(d(20), d(22))), isFalse);
      });
    });

    test('contains is inclusive of start, exclusive of end', () {
      final r = DateRange(d(12), d(15));
      expect(r.contains(d(12)), isTrue);
      expect(r.contains(d(14)), isTrue);
      expect(r.contains(d(15)), isFalse, reason: 'end is exclusive');
      expect(r.contains(d(11)), isFalse);
    });

    test('containsRange requires full enclosure', () {
      final outer = DateRange(d(12), d(20));
      expect(outer.containsRange(DateRange(d(13), d(19))), isTrue);
      expect(outer.containsRange(outer), isTrue);
      expect(outer.containsRange(DateRange(d(13), d(21))), isFalse);
    });

    test('rent multiplies days by the daily rate', () {
      // Sabyasachi lehenga at ₹9,500/day for three days.
      expect(DateRange(d(12), d(15)).rentInr(9500), 28500);
    });

    group('Postgres interchange', () {
      test('emits yyyy-MM-dd', () {
        final r = DateRange(DateTime(2026, 1, 5), DateTime(2026, 1, 9));
        expect(r.startIso, '2026-01-05');
        expect(r.endIso, '2026-01-09');
      });

      test('parses the half-open literal Postgres returns', () {
        final r = DateRange.tryParsePostgres('[2026-12-12,2026-12-15)');
        expect(r, DateRange(d(12), d(15)));
      });

      test('parses quoted and inclusive-bracket variants', () {
        expect(DateRange.tryParsePostgres('["2026-12-12","2026-12-15")'),
            DateRange(d(12), d(15)));
      });

      test('garbage yields null rather than throwing', () {
        for (final bad in [null, '', 'not a range', '[2026-12-12)', '[b,a)']) {
          expect(DateRange.tryParsePostgres(bad), isNull, reason: 'input: $bad');
        }
      });

      test('reversed bounds are rejected', () {
        expect(DateRange.tryParsePostgres('[2026-12-15,2026-12-12)'), isNull);
      });

      test('round-trips through the Postgres literal form', () {
        final r = DateRange(d(12), d(15));
        expect(DateRange.tryParsePostgres('[${r.startIso},${r.endIso})'), r);
      });
    });
  });

  group('Availability', () {
    // A listing booked 12–15 Dec, with the owner keeping 20–22 Dec.
    final availability = Availability([
      DateRange(d(12), d(15)),
      DateRange(d(20), d(22)),
    ]);

    test('an empty calendar is free', () {
      expect(Availability.empty.isFree(DateRange(d(1), d(31))), isTrue);
    });

    test('a clashing range is not free', () {
      expect(availability.isFree(DateRange(d(13), d(14))), isFalse);
      expect(availability.isFree(DateRange(d(14), d(18))), isFalse);
    });

    test('a gap between blocks is free', () {
      expect(availability.isFree(DateRange(d(15), d(20))), isTrue,
          reason: 'the 15th is released and the 20th not yet taken');
    });

    test('single-day queries respect the boundaries', () {
      expect(availability.isFreeOn(d(14)), isFalse);
      expect(availability.isFreeOn(d(15)), isTrue);
      expect(availability.isFreeOn(d(19)), isTrue);
      expect(availability.isFreeOn(d(20)), isFalse);
    });

    test('conflicts names the clashing ranges, earliest first', () {
      final clashes = availability.conflicts(DateRange(d(14), d(21)));
      expect(clashes, hasLength(2));
      expect(clashes.first.start, d(12));
      expect(clashes.last.start, d(20));
    });

    test('conflicts is empty when the span is free', () {
      expect(availability.conflicts(DateRange(d(16), d(19))), isEmpty);
    });

    group('nextFreeStart', () {
      test('finds the first date a rental of that length fits', () {
        // A 3-day rental cannot start 12th–19th (15,16,17 would hit the 20th),
        // so the first fit from the 12th is the 15th.
        expect(availability.nextFreeStart(d(12), 3), d(15));
      });

      test('a shorter rental fits sooner in a gap', () {
        expect(availability.nextFreeStart(d(16), 2), d(16));
      });

      test('returns the requested date when already free', () {
        expect(availability.nextFreeStart(d(25), 2), d(25));
      });

      test('null when nothing fits inside the search window', () {
        // Fully blocked for the whole window.
        final blocked = Availability([DateRange(d(1), DateTime(2027, 12, 1))]);
        expect(blocked.nextFreeStart(d(1), 2, searchDays: 30), isNull);
      });
    });
  });
}

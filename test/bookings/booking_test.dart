import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/bookings/domain/booking.dart';
import 'package:mangwalo/src/features/listings/domain/date_range.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 12, day);

  Booking booking({
    BookingStatus status = BookingStatus.requested,
    int pricePerDay = 4800,
    int? deposit = 25000,
    DateRange? during,
    DateTime? respondsBy,
  }) =>
      Booking(
        id: 'b1',
        listingId: 'l1',
        ownerId: 'owner',
        renterId: 'renter',
        during: during ?? DateRange(d(12), d(15)),
        status: status,
        pricePerDayInr: pricePerDay,
        depositInr: deposit,
        respondsBy: respondsBy,
        createdAt: d(1),
      );

  group('wire format matches the database', () {
    test('inProgress serialises with an underscore, not camelCase', () {
      // The status check constraint spells it in_progress; a mismatch here
      // would be rejected by Postgres at runtime.
      expect(BookingStatus.inProgress.wire, 'in_progress');
      expect(BookingStatus.confirmed.wire, 'confirmed');
    });

    test('every status round-trips through the wire form', () {
      for (final s in BookingStatus.values) {
        expect(BookingStatusX.fromWire(s.wire), s, reason: 'failed for $s');
      }
    });

    test('an unknown status decodes to requested rather than throwing', () {
      expect(BookingStatusX.fromWire('teleported'), BookingStatus.requested);
      expect(BookingStatusX.fromWire(null), BookingStatus.requested);
    });
  });

  group('blocksCalendar mirrors the exclusion constraint', () {
    // If these ever disagree with the WHERE clause on bookings_no_overlap, the
    // UI will offer dates the database refuses — so pin them explicitly.
    test('states that hold the item block it', () {
      for (final s in [
        BookingStatus.confirmed,
        BookingStatus.inProgress,
        BookingStatus.returned,
        BookingStatus.closed,
      ]) {
        expect(s.blocksCalendar, isTrue, reason: '$s should block');
      }
    });

    test('states that do not hold the item leave it free', () {
      for (final s in [
        BookingStatus.requested,
        BookingStatus.declined,
        BookingStatus.expired,
        BookingStatus.withdrawn,
        BookingStatus.cancelled,
      ]) {
        expect(s.blocksCalendar, isFalse, reason: '$s should not block');
      }
    });

    test('a mere request does not block — competing requests are allowed', () {
      expect(BookingStatus.requested.blocksCalendar, isFalse);
    });
  });

  group('money', () {
    test('rent is nights times the frozen daily rate', () {
      expect(booking().nights, 3);
      expect(booking().rentInr, 14400);
    });

    test('due now adds the refundable deposit', () {
      expect(booking().dueNowInr, 14400 + 25000);
    });

    test('a listing with no deposit charges rent only', () {
      expect(booking(deposit: null).dueNowInr, 14400);
    });

    test('the rate is frozen on the booking, not read from the listing', () {
      // Price lives on the booking precisely so a later listing edit cannot
      // change what was agreed.
      final agreed = booking(pricePerDay: 4800);
      expect(agreed.rentInr, 14400);
    });
  });

  group('response deadline', () {
    final now = DateTime(2026, 12, 2, 12);

    test('a request inside its window is awaiting response', () {
      final b = booking(respondsBy: now.add(const Duration(hours: 5)));
      expect(b.awaitingResponse(now), isTrue);
      expect(b.hasLapsed(now), isFalse);
    });

    test('a request past its deadline reads as lapsed, not live', () {
      // Shown as expired before any job rewrites the row, so the UI never
      // claims a stale request is still awaiting an answer.
      final b = booking(respondsBy: now.subtract(const Duration(hours: 1)));
      expect(b.hasLapsed(now), isTrue);
      expect(b.awaitingResponse(now), isFalse);
    });

    test('a confirmed booking is neither awaiting nor lapsed', () {
      final b = booking(
          status: BookingStatus.confirmed,
          respondsBy: now.subtract(const Duration(hours: 1)));
      expect(b.awaitingResponse(now), isFalse);
      expect(b.hasLapsed(now), isFalse);
    });
  });

  group('participants', () {
    test('owner and renter are distinguished', () {
      final b = booking();
      expect(b.isOwner('owner'), isTrue);
      expect(b.isRenter('renter'), isTrue);
      expect(b.isOwner('renter'), isFalse);
      expect(b.isRenter('someone-else'), isFalse);
    });
  });

  group('isOver', () {
    test('terminal states are over', () {
      for (final s in [
        BookingStatus.declined,
        BookingStatus.expired,
        BookingStatus.withdrawn,
        BookingStatus.closed,
        BookingStatus.cancelled,
      ]) {
        expect(s.isOver, isTrue, reason: '$s');
      }
    });

    test('live states are not over', () {
      for (final s in [
        BookingStatus.requested,
        BookingStatus.confirmed,
        BookingStatus.inProgress,
        BookingStatus.returned,
      ]) {
        expect(s.isOver, isFalse, reason: '$s');
      }
    });
  });

  group('availability drives what a renter may pick', () {
    // Booked 12–15 Dec; owner keeps 20–22 Dec.
    final availability = Availability([
      DateRange(d(12), d(15)),
      DateRange(d(20), d(22)),
    ]);

    test('a span that jumps over a blocked stretch is not free', () {
      // The calendar refuses this, and the exclusion constraint would too.
      expect(availability.isFree(DateRange(d(18), d(24))), isFalse);
    });

    test('a span sitting entirely in a gap is free', () {
      expect(availability.isFree(DateRange(d(15), d(20))), isTrue);
    });

    test('conflicts explain exactly which stretch clashes', () {
      final clashes = availability.conflicts(DateRange(d(19), d(21)));
      expect(clashes.single.start, d(20));
    });
  });
}

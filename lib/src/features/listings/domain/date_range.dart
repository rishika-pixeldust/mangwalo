import 'package:flutter/foundation.dart';

/// A half-open range of whole days: `[start, end)`.
///
/// Half-open is the same convention as the Postgres `daterange(..., '[)')` the
/// booking table uses, and it is chosen deliberately. With inclusive ends,
/// "12–15 Dec" and "15–18 Dec" collide on the 15th, so a same-day handover to
/// the next renter looks like a double-booking. Half-open makes back-to-back
/// rentals expressible, which matters in wedding season when an item is in
/// demand on consecutive days.
///
/// Dates only — no times, no timezones. A rental day is a calendar day
/// wherever both parties happen to be.
@immutable
class DateRange {
  DateRange(DateTime start, DateTime end)
      : start = _dateOnly(start),
        end = _dateOnly(end) {
    assert(!this.end.isBefore(this.start), 'end must not precede start');
  }

  /// A single day: `[day, day + 1)`.
  factory DateRange.day(DateTime day) =>
      DateRange(day, _dateOnly(day).add(const Duration(days: 1)));

  /// [nights] days starting at [start].
  factory DateRange.nights(DateTime start, int nights) {
    assert(nights > 0, 'a rental is at least one day');
    return DateRange(start, _dateOnly(start).add(Duration(days: nights)));
  }

  final DateTime start;

  /// Exclusive: the item is free again on this date.
  final DateTime end;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days charged for. `[12 Dec, 15 Dec)` is three.
  int get nights => end.difference(start).inDays;

  bool get isEmpty => nights == 0;

  /// True when the two ranges share at least one day. Back-to-back ranges do
  /// not overlap, which is the whole point of the half-open convention.
  bool overlaps(DateRange other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  bool contains(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(start) && d.isBefore(end);
  }

  bool containsRange(DateRange other) =>
      !other.start.isBefore(start) && !other.end.isAfter(end);

  /// Whether this range ends exactly where [other] begins, or vice versa —
  /// adjacent but not overlapping.
  bool isAdjacentTo(DateRange other) =>
      end == other.start || other.end == start;

  /// Total rent for the range at a daily rate, before deposit or commission.
  int rentInr(int pricePerDayInr) => nights * pricePerDayInr;

  DateRange copyWith({DateTime? start, DateTime? end}) =>
      DateRange(start ?? this.start, end ?? this.end);

  /// `yyyy-MM-dd` pair, matching how the codec and Postgres exchange dates.
  String get startIso => _iso(start);
  String get endIso => _iso(end);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Parses `[2026-12-12,2026-12-15)` as returned by Postgres, or null if it
  /// cannot be understood — tolerant, like the rest of the data layer.
  static DateRange? tryParsePostgres(String? raw) {
    if (raw == null || raw.length < 10) return null;
    final body = raw.replaceAll(RegExp(r'^[\[(]|[\])]$'), '');
    final parts = body.split(',');
    if (parts.length != 2) return null;
    final a = DateTime.tryParse(parts[0].replaceAll('"', '').trim());
    final b = DateTime.tryParse(parts[1].replaceAll('"', '').trim());
    if (a == null || b == null || b.isBefore(a)) return null;
    return DateRange(a, b);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$startIso, $endIso)';
}

/// Everything blocking a listing's calendar: confirmed bookings plus the
/// owner's own holds. Deliberately does not know *why* a range is blocked —
/// a renter should not learn who booked what, and the server's availability
/// function returns bare ranges for exactly that reason.
@immutable
class Availability {
  const Availability(this.blocked);

  /// May overlap each other; no ordering assumed.
  final List<DateRange> blocked;

  static const empty = Availability(<DateRange>[]);

  bool isFree(DateRange range) => !blocked.any(range.overlaps);

  bool isFreeOn(DateTime day) => isFree(DateRange.day(day));

  /// The blocked ranges that clash with [range] — what the UI shows when a
  /// requested span is unavailable ("booked 14–18 Dec").
  List<DateRange> conflicts(DateRange range) =>
      blocked.where(range.overlaps).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// The next date on or after [from] where a [nights]-long rental fits.
  /// Returns null if nothing fits inside [searchDays].
  DateTime? nextFreeStart(DateTime from, int nights, {int searchDays = 180}) {
    var candidate = DateRange._dateOnly(from);
    for (var i = 0; i < searchDays; i++) {
      if (isFree(DateRange.nights(candidate, nights))) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }
    return null;
  }
}

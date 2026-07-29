import 'package:flutter/foundation.dart';

import '../../listings/domain/date_range.dart';

/// Lifecycle of a rental, mirroring the `status` check constraint on the
/// `bookings` table so the client can never invent a state the database will
/// reject.
enum BookingStatus {
  requested,
  declined,
  expired,
  withdrawn,
  confirmed,
  inProgress,
  returned,
  closed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  /// The wire value. `inProgress` differs from its Dart name, so this is not
  /// simply `name` — hence the explicit mapping in both directions.
  String get wire => switch (this) {
        BookingStatus.inProgress => 'in_progress',
        _ => name,
      };

  String get label => switch (this) {
        BookingStatus.requested => 'Requested',
        BookingStatus.declined => 'Declined',
        BookingStatus.expired => 'Expired',
        BookingStatus.withdrawn => 'Withdrawn',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.inProgress => 'With the renter',
        BookingStatus.returned => 'Returned',
        BookingStatus.closed => 'Closed',
        BookingStatus.cancelled => 'Cancelled',
      };

  /// Whether this status holds the item and therefore blocks the calendar.
  /// Must match the WHERE clause of the `bookings_no_overlap` constraint —
  /// if these ever disagree, the UI will offer dates the database refuses.
  bool get blocksCalendar => switch (this) {
        BookingStatus.confirmed ||
        BookingStatus.inProgress ||
        BookingStatus.returned ||
        BookingStatus.closed =>
          true,
        _ => false,
      };

  /// Still awaiting the owner's answer.
  bool get isPending => this == BookingStatus.requested;

  /// Finished, one way or another — nothing further will happen.
  bool get isOver => switch (this) {
        BookingStatus.declined ||
        BookingStatus.expired ||
        BookingStatus.withdrawn ||
        BookingStatus.closed ||
        BookingStatus.cancelled =>
          true,
        _ => false,
      };

  static BookingStatus fromWire(String? raw) => switch (raw) {
        'in_progress' => BookingStatus.inProgress,
        'declined' => BookingStatus.declined,
        'expired' => BookingStatus.expired,
        'withdrawn' => BookingStatus.withdrawn,
        'confirmed' => BookingStatus.confirmed,
        'returned' => BookingStatus.returned,
        'closed' => BookingStatus.closed,
        'cancelled' => BookingStatus.cancelled,
        // Unknown values fall back to the harmless initial state rather than
        // throwing, matching the tolerance of the listing codec.
        _ => BookingStatus.requested,
      };
}

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.listingId,
    required this.ownerId,
    required this.renterId,
    required this.during,
    required this.status,
    required this.pricePerDayInr,
    this.depositInr,
    this.note = '',
    this.respondsBy,
    this.confirmedAt,
    this.returnedAt,
    required this.createdAt,
    this.listingTitle = '',
  });

  final String id;
  final String listingId;
  final String ownerId;
  final String renterId;
  final DateRange during;
  final BookingStatus status;

  /// Frozen at request time, so a later listing edit cannot change the price
  /// that was agreed.
  final int pricePerDayInr;
  final int? depositInr;
  final String note;

  /// Owner must answer before this, or the request expires.
  final DateTime? respondsBy;
  final DateTime? confirmedAt;
  final DateTime? returnedAt;
  final DateTime createdAt;

  /// Denormalised for inbox rows, so listing a booking does not need a join.
  final String listingTitle;

  int get nights => during.nights;

  /// Rent for the whole span, before deposit or commission.
  int get rentInr => during.rentInr(pricePerDayInr);

  /// What the renter pays up front: rent plus the refundable deposit.
  int get dueNowInr => rentInr + (depositInr ?? 0);

  bool isOwner(String userId) => userId == ownerId;
  bool isRenter(String userId) => userId == renterId;

  /// Whether the owner still has time to answer.
  bool awaitingResponse(DateTime now) =>
      status.isPending && (respondsBy == null || now.isBefore(respondsBy!));

  /// A request the owner left unanswered past the deadline. Shown as expired
  /// even before a job rewrites the row, so the UI never lies about a stale
  /// request still being live.
  bool hasLapsed(DateTime now) =>
      status.isPending && respondsBy != null && now.isAfter(respondsBy!);

  Booking copyWith({BookingStatus? status, DateTime? confirmedAt}) => Booking(
        id: id,
        listingId: listingId,
        ownerId: ownerId,
        renterId: renterId,
        during: during,
        status: status ?? this.status,
        pricePerDayInr: pricePerDayInr,
        depositInr: depositInr,
        note: note,
        respondsBy: respondsBy,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        returnedAt: returnedAt,
        createdAt: createdAt,
        listingTitle: listingTitle,
      );

  @override
  bool operator ==(Object other) =>
      other is Booking &&
      other.id == id &&
      other.status == status &&
      other.during == during &&
      other.pricePerDayInr == pricePerDayInr &&
      other.depositInr == depositInr;

  @override
  int get hashCode =>
      Object.hash(id, status, during, pricePerDayInr, depositInr);
}

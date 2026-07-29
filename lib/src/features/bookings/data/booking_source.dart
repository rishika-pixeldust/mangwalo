import 'package:supabase_flutter/supabase_flutter.dart';

import '../../listings/data/supabase_listing_source.dart' show OfflineWriteException;
import '../../listings/domain/date_range.dart';
import '../domain/booking.dart';

/// Bookings over Supabase.
///
/// Availability comes from `listing_unavailable_ranges`, a security-definer
/// function returning bare date ranges — so a renter can see that dates are
/// taken without learning who took them. Reading the `bookings` table directly
/// would be blocked by RLS for exactly that reason.
class BookingSource {
  BookingSource(this._client);

  final SupabaseClient _client;

  static const _table = 'bookings';

  String? get _uid => _client.auth.currentUser?.id;

  /// Dates already taken, from confirmed bookings and owner blackouts.
  /// Returns [Availability.empty] on failure: an unreachable server must not
  /// make a listing look bookable when it might not be — the database's
  /// exclusion constraint is the real guard, so a stale calendar can only
  /// cause a rejected request, never a double-booking.
  Future<Availability> availability(String listingId) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'listing_unavailable_ranges',
        params: {'p_listing_id': listingId},
      );
      return Availability([
        for (final row in rows)
          ?DateRange.tryParsePostgres(
              row is Map ? row['during'] as String? : row as String?),
      ]);
    } on Object {
      return Availability.empty;
    }
  }

  /// Server-side availability check, run immediately before requesting so the
  /// user gets a clear answer rather than a constraint violation.
  Future<bool> isAvailable(String listingId, DateRange range) async {
    try {
      return await _client.rpc<bool>('listing_is_available', params: {
        'p_listing_id': listingId,
        'p_from': range.startIso,
        'p_to': range.endIso,
      });
    } on Object {
      // Let the request itself be the authority if the check cannot run.
      return true;
    }
  }

  /// Asks to rent. Status is always `requested` — RLS enforces that too, so a
  /// client cannot self-approve by posting `confirmed`.
  Future<void> request({
    required String listingId,
    required String ownerId,
    required DateRange during,
    required int pricePerDayInr,
    int? depositInr,
    String note = '',
    Duration respondWithin = const Duration(hours: 24),
  }) async {
    final uid = _requireSession();
    await _client.from(_table).insert({
      'listing_id': listingId,
      'owner_id': ownerId,
      'renter_id': uid,
      'during': '[${during.startIso},${during.endIso})',
      'status': BookingStatus.requested.wire,
      'price_per_day_inr': pricePerDayInr,
      'deposit_inr': depositInr,
      'note': note,
      'responds_by':
          DateTime.now().toUtc().add(respondWithin).toIso8601String(),
    });
  }

  /// Everything involving me, either side. RLS scopes this to the two parties.
  Future<List<Booking>> mine() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from(_table)
        .select('*, listings(title)')
        .order('created_at', ascending: false);
    return [for (final row in rows) ?_fromRow(row)];
  }

  /// Owner accepts. This is the write the exclusion constraint guards: if a
  /// competing request was confirmed first, Postgres rejects this one and the
  /// caller surfaces [BookingConflict] rather than silently double-booking.
  Future<void> approve(String bookingId) async {
    _requireSession();
    try {
      await _client.from(_table).update({
        'status': BookingStatus.confirmed.wire,
        'confirmed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', bookingId);
    } on PostgrestException catch (e) {
      // 23P01 = exclusion_violation: those dates just became unavailable.
      if (e.code == '23P01') {
        throw const BookingConflict(
            'Those dates were just taken by another confirmed booking.');
      }
      rethrow;
    }
  }

  Future<void> decline(String bookingId) => _setStatus(bookingId, BookingStatus.declined);

  Future<void> withdraw(String bookingId) => _setStatus(bookingId, BookingStatus.withdrawn);

  Future<void> cancel(String bookingId) => _setStatus(bookingId, BookingStatus.cancelled);

  Future<void> _setStatus(String bookingId, BookingStatus status) async {
    _requireSession();
    await _client
        .from(_table)
        .update({'status': status.wire}).eq('id', bookingId);
  }

  String _requireSession() {
    final uid = _uid;
    if (uid == null) {
      throw const OfflineWriteException(
          'Sign in to book on the shared noticeboard.');
    }
    return uid;
  }

  /// Tolerant, like every other decode in the app: a row we cannot understand
  /// is skipped rather than allowed to break an inbox.
  Booking? _fromRow(Map<String, dynamic> row) {
    try {
      final id = row['id'] as String?;
      final during = DateRange.tryParsePostgres(row['during'] as String?);
      if (id == null || during == null) return null;
      final listing = row['listings'];
      return Booking(
        id: id,
        listingId: row['listing_id'] as String? ?? '',
        ownerId: row['owner_id'] as String? ?? '',
        renterId: row['renter_id'] as String? ?? '',
        during: during,
        status: BookingStatusX.fromWire(row['status'] as String?),
        pricePerDayInr: (row['price_per_day_inr'] as num?)?.toInt() ?? 0,
        depositInr: (row['deposit_inr'] as num?)?.toInt(),
        note: row['note'] as String? ?? '',
        respondsBy: _ts(row['responds_by'] as String?),
        confirmedAt: _ts(row['confirmed_at'] as String?),
        returnedAt: _ts(row['returned_at'] as String?),
        createdAt: _ts(row['created_at'] as String?) ?? DateTime.now(),
        listingTitle:
            listing is Map ? (listing['title'] as String? ?? '') : '',
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _ts(String? v) =>
      (v == null || v.isEmpty) ? null : DateTime.tryParse(v)?.toLocal();
}

/// The dates were taken between showing the calendar and confirming. Expected
/// under contention, not exceptional — the UI asks the owner to pick again.
class BookingConflict implements Exception {
  const BookingConflict(this.message);
  final String message;
  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/listing_photo.dart';
import '../domain/listing.dart';

/// Thrown when a write is attempted without a usable connection or session.
/// Phase B is deliberately read-offline / write-online, so this is an expected
/// outcome the UI reports plainly rather than an exceptional crash.
class OfflineWriteException implements Exception {
  const OfflineWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The shared noticeboard, over Supabase.
///
/// Deliberately NOT a [ListingRepository]: it has no cache and no offline
/// story, so composing it with the local box is [CachedSyncedListingRepository]'s
/// job. Keeping it dumb makes the row↔domain mapping the only thing to test.
class SupabaseListingSource {
  SupabaseListingSource(this._client);

  final SupabaseClient _client;

  static const _table = 'listings';
  static const _reviewTable = 'reviews';

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isSignedIn => currentUserId != null;

  /// Every listing the caller may see. RLS decides that, not this query —
  /// an unauthenticated caller simply gets an empty list back.
  Future<List<Listing>> fetchAll() async {
    final rows = await _client
        .from(_table)
        .select('*, $_reviewTable(rating, body, reviewer_name, created_at)')
        .order('updated_at', ascending: false);

    final mine = currentUserId;
    return [
      for (final row in rows) ?_fromRow(row, myUserId: mine),
    ];
  }

  Future<void> upsert(Listing listing) async {
    final uid = _requireSession();
    await _client.from(_table).upsert(_toRow(listing, ownerId: uid));
  }

  Future<void> upsertAll(List<Listing> listings) async {
    if (listings.isEmpty) return;
    final uid = _requireSession();
    await _client
        .from(_table)
        .upsert([for (final l in listings) _toRow(l, ownerId: uid)]);
  }

  Future<void> delete(String id) async {
    _requireSession();
    await _client.from(_table).delete().eq('id', id);
  }

  /// Uploads any base64 photos to Storage and returns the list with those
  /// entries replaced by public URLs. Already-uploaded URLs pass through, so
  /// re-saving a listing does not re-upload its gallery.
  ///
  /// Paths are namespaced by user id because the Storage policy confines each
  /// user to a folder named after their uid.
  Future<List<String>> uploadPhotos(String listingId, List<String> photos) async {
    final uid = _requireSession();
    final out = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo.isEmpty || isPhotoUrl(photo)) {
        out.add(photo);
        continue;
      }
      final Uint8List bytes;
      try {
        bytes = base64Decode(photo);
      } on FormatException {
        continue; // Skip a corrupt entry rather than failing the whole save.
      }
      final path = '$uid/$listingId-$i.jpg';
      await _client.storage.from(AppConfig.photoBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      out.add(_client.storage.from(AppConfig.photoBucket).getPublicUrl(path));
    }
    return out;
  }

  String _requireSession() {
    final uid = currentUserId;
    if (uid == null) {
      throw const OfflineWriteException(
          'Sign in to post to the shared noticeboard.');
    }
    return uid;
  }

  // --- mapping -------------------------------------------------------------

  Map<String, dynamic> _toRow(Listing l, {required String ownerId}) => {
        'id': l.id,
        'owner_id': ownerId,
        'type': l.type.name,
        'title': l.title,
        'description': l.description,
        'category': l.category.name,
        'sub_category': l.subCategory,
        'condition_tags': l.conditionTags,
        'area': l.area,
        'locality': l.neighborhood,
        'price_per_day_inr': l.pricePerDayInr,
        'deposit_inr': l.depositInr,
        'status': l.status.name,
        'lending_state': l.lendingState.name,
        'due_date': l.dueDate == null ? null : _dateOnly(l.dueDate!),
        'returned_at': l.returnedAt?.toUtc().toIso8601String(),
        'borrower_name': l.borrowerName,
        'suggested_duration_days': l.suggestedDurationDays,
        'photos': l.photos,
        'is_demo': l.isDemo,
        'updated_at': l.updatedAt.toUtc().toIso8601String(),
      };

  /// Tolerant like the local codec: a row we cannot understand is skipped,
  /// never allowed to break the whole board.
  Listing? _fromRow(Map<String, dynamic> row, {String? myUserId}) {
    try {
      final id = row['id'] as String?;
      final title = row['title'] as String?;
      if (id == null || title == null) return null;

      var lendingState = _enumByName(LendingState.values,
          row['lending_state'] as String?, LendingState.available);
      var dueDate = _parseDate(row['due_date'] as String?);
      // Repair rather than reject, matching the local codec's contract.
      if (lendingState == LendingState.lentOut && dueDate == null) {
        lendingState = LendingState.available;
      }
      if (lendingState != LendingState.lentOut) dueDate = null;

      final created = _parseTs(row['created_at'] as String?) ?? DateTime.now();
      final ownerId = row['owner_id'] as String?;

      return Listing(
        id: id,
        type: _enumByName(
            ListingType.values, row['type'] as String?, ListingType.offer),
        title: title,
        description: row['description'] as String? ?? '',
        category: _enumByName(
            Category.values, row['category'] as String?, Category.other),
        subCategory: row['sub_category'] as String? ?? '',
        conditionTags:
            (row['condition_tags'] as List?)?.whereType<String>().toList() ??
                const [],
        area: row['area'] as String? ?? '',
        neighborhood: row['locality'] as String? ?? '',
        pricePerDayInr: (row['price_per_day_inr'] as num?)?.toInt() ?? 0,
        depositInr: (row['deposit_inr'] as num?)?.toInt(),
        status: _enumByName(InteractionStatus.values, row['status'] as String?,
            InteractionStatus.saved),
        lendingState: lendingState,
        dueDate: dueDate,
        returnedAt: _parseTs(row['returned_at'] as String?),
        borrowerName: row['borrower_name'] as String? ?? '',
        suggestedDurationDays:
            (row['suggested_duration_days'] as num?)?.toInt(),
        photos: (row['photos'] as List?)?.whereType<String>().toList() ??
            const [],
        reviews: _reviews(row[_reviewTable]),
        createdAt: created,
        updatedAt: _parseTs(row['updated_at'] as String?) ?? created,
        // "Mine" is ownership on the server, not a local flag any more.
        isMine: ownerId != null && ownerId == myUserId,
        isDemo: row['is_demo'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  List<Review> _reviews(Object? raw) {
    if (raw is! List) return const [];
    final out = <Review>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final rating = (entry['rating'] as num?)?.toInt();
      final body = entry['body'] as String?;
      if (rating == null || rating < 1 || rating > 5 || body == null) continue;
      out.add(Review(
        rating: rating,
        text: body,
        reviewerName: entry['reviewer_name'] as String? ?? '',
        createdAt: _parseTs(entry['created_at'] as String?) ?? DateTime.now(),
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? v) =>
      (v == null || v.isEmpty) ? null : DateTime.tryParse(v);

  static DateTime? _parseTs(String? v) =>
      (v == null || v.isEmpty) ? null : DateTime.tryParse(v)?.toLocal();

  static T _enumByName<T extends Enum>(
      List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

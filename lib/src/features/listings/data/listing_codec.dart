import '../../../core/constants.dart';
import '../domain/listing.dart';

/// Hand-written JSON codec — no codegen, no Hive TypeAdapters. Every payload
/// carries a schema version; decoding is tolerant (missing keys get defaults,
/// undecodable entries return null so callers can skip them).
abstract final class ListingCodec {
  static Map<String, dynamic> toJsonMap(Listing l) => <String, dynamic>{
        'v': AppConstants.schemaVersion,
        'id': l.id,
        'type': l.type.name,
        'title': l.title,
        'description': l.description,
        'category': l.category.name,
        'subCategory': l.subCategory,
        'conditionTags': l.conditionTags,
        'area': l.area,
        'neighborhood': l.neighborhood,
        'contactChannel': l.contactChannel.name,
        'pricePerDayInr': l.pricePerDayInr,
        'depositInr': l.depositInr,
        'status': l.status.name,
        'lendingState': l.lendingState.name,
        // Date-only, so timezone round-trips can never shift the day.
        'dueDate': l.dueDate == null ? null : _dateOnly(l.dueDate!),
        'returnedAt': l.returnedAt?.toUtc().toIso8601String(),
        'borrowerName': l.borrowerName,
        'suggestedDurationDays': l.suggestedDurationDays,
        'photos': l.photos,
        'reviews': [
          for (final r in l.reviews)
            {
              'rating': r.rating,
              'text': r.text,
              'reviewerName': r.reviewerName,
              'createdAt': r.createdAt.toUtc().toIso8601String(),
            }
        ],
        'createdAt': l.createdAt.toUtc().toIso8601String(),
        'updatedAt': l.updatedAt.toUtc().toIso8601String(),
        'isMine': l.isMine,
        'isDemo': l.isDemo,
      };

  static Listing? fromJsonMap(Map<String, dynamic> map) {
    try {
      final id = map['id'] as String?;
      final title = map['title'] as String?;
      if (id == null || id.isEmpty || title == null) return null;

      var lendingState = _enumByName(
        LendingState.values,
        map['lendingState'] as String?,
        LendingState.available,
      );
      var dueDate = _parseDate(map['dueDate'] as String?);
      // Repair the invariant instead of refusing to load the row.
      if (lendingState == LendingState.lentOut && dueDate == null) {
        lendingState = LendingState.available;
      }
      if (lendingState != LendingState.lentOut) {
        dueDate = null;
      }

      final createdAt =
          _parseTimestamp(map['createdAt'] as String?) ?? DateTime.now();
      return Listing(
        id: id,
        type: _enumByName(
            ListingType.values, map['type'] as String?, ListingType.offer),
        title: title,
        description: map['description'] as String? ?? '',
        // Unknown/legacy categories (v1 rows) land in Others rather than
        // being dropped or silently mislabelled as Accessories.
        category: _enumByName(
            Category.values, map['category'] as String?, Category.other),
        subCategory: _decodeSubCategory(map['subCategory']),
        conditionTags: (map['conditionTags'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const <String>[],
        area: map['area'] as String? ?? '',
        neighborhood: map['neighborhood'] as String? ?? '',
        contactChannel: _enumByName(ContactChannel.values,
            map['contactChannel'] as String?, ContactChannel.societyBoard),
        // `contactNote` stays deliberately unread: a free-text contact field
        // is the likeliest place a phone number ends up, so legacy values are
        // dropped rather than migrated. The preference above carries the
        // intent without ever holding a digit.
        pricePerDayInr: (map['pricePerDayInr'] as num?)?.toInt() ?? 0,
        depositInr: (map['depositInr'] as num?)?.toInt(),
        status: _enumByName(InteractionStatus.values, map['status'] as String?,
            InteractionStatus.saved),
        lendingState: lendingState,
        dueDate: dueDate,
        returnedAt: _parseTimestamp(map['returnedAt'] as String?),
        borrowerName: map['borrowerName'] as String? ?? '',
        suggestedDurationDays: (map['suggestedDurationDays'] as num?)?.toInt(),
        photos: _decodePhotos(map),
        reviews: _decodeReviews(map['reviews']),
        createdAt: createdAt,
        updatedAt: _parseTimestamp(map['updatedAt'] as String?) ?? createdAt,
        isMine: map['isMine'] as bool? ?? false,
        isDemo: map['isDemo'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Free-text sub-categories reach storage from user input, so cap the
  /// length here too — the repository is the last line of defence.
  static String _decodeSubCategory(Object? raw) {
    if (raw is! String) return '';
    final trimmed = raw.trim();
    return trimmed.length <= kMaxSubCategoryLength
        ? trimmed
        : trimmed.substring(0, kMaxSubCategoryLength);
  }

  /// v2 stores a `photos` list; v1 rows carried a single `photoBase64`,
  /// migrated here into a one-element gallery.
  static List<String> _decodePhotos(Map<String, dynamic> map) {
    final list =
        (map['photos'] as List<dynamic>?)?.whereType<String>().toList();
    if (list != null && list.isNotEmpty) {
      return list.take(kMaxListingPhotos).toList();
    }
    final legacy = map['photoBase64'] as String?;
    return legacy == null || legacy.isEmpty ? const [] : [legacy];
  }

  static List<Review> _decodeReviews(Object? raw) {
    if (raw is! List) return const [];
    final out = <Review>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final rating = (entry['rating'] as num?)?.toInt();
      final text = entry['text'] as String?;
      if (rating == null || rating < 1 || rating > 5 || text == null) continue;
      out.add(Review(
        rating: rating,
        text: text,
        reviewerName: entry['reviewerName'] as String? ?? '',
        createdAt:
            _parseTimestamp(entry['createdAt'] as String?) ?? DateTime.now(),
      ));
    }
    return out;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    // Date-only strings parse as local midnight — exactly what we want.
    return DateTime.tryParse(value);
  }

  static DateTime? _parseTimestamp(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

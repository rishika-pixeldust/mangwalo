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
        'conditionTags': l.conditionTags,
        'area': l.area,
        'neighborhood': l.neighborhood,
        'contactChannel': l.contactChannel.name,
        'contactNote': l.contactNote,
        'status': l.status.name,
        'lendingState': l.lendingState.name,
        // Date-only, so timezone round-trips can never shift the day.
        'dueDate': l.dueDate == null ? null : _dateOnly(l.dueDate!),
        'returnedAt': l.returnedAt?.toUtc().toIso8601String(),
        'borrowerName': l.borrowerName,
        'suggestedDurationDays': l.suggestedDurationDays,
        'photoBase64': l.photoBase64,
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
        category: _enumByName(
            Category.values, map['category'] as String?, Category.other),
        conditionTags: (map['conditionTags'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const <String>[],
        area: map['area'] as String? ?? '',
        neighborhood: map['neighborhood'] as String? ?? '',
        contactChannel: _enumByName(ContactChannel.values,
            map['contactChannel'] as String?, ContactChannel.societyBoard),
        contactNote: map['contactNote'] as String? ?? '',
        status: _enumByName(InteractionStatus.values, map['status'] as String?,
            InteractionStatus.saved),
        lendingState: lendingState,
        dueDate: dueDate,
        returnedAt: _parseTimestamp(map['returnedAt'] as String?),
        borrowerName: map['borrowerName'] as String? ?? '',
        suggestedDurationDays: (map['suggestedDurationDays'] as num?)?.toInt(),
        photoBase64: map['photoBase64'] as String?,
        createdAt: createdAt,
        updatedAt: _parseTimestamp(map['updatedAt'] as String?) ?? createdAt,
        isMine: map['isMine'] as bool? ?? false,
        isDemo: map['isDemo'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
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

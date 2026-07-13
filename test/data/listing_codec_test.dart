import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/data/listing_codec.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  final listing = Listing(
    id: 'id-1',
    type: ListingType.offer,
    title: 'Cricket bat, size 6',
    description: 'Kashmir-willow bat, lightly taped handle.',
    category: Category.sportsFitness,
    conditionTags: const ['Gently used'],
    area: 'Opposite Jogger\'s Park',
    neighborhood: 'Bandra West',
    contactChannel: ContactChannel.buildingWhatsApp,
    contactNote: 'R. Nair — building group',
    status: InteractionStatus.contacted,
    lendingState: LendingState.lentOut,
    dueDate: DateTime(2026, 7, 15),
    borrowerName: 'Asha',
    suggestedDurationDays: 7,
    photoBase64: 'aGVsbG8=',
    createdAt: DateTime(2026, 7, 1, 10, 30),
    updatedAt: DateTime(2026, 7, 10, 18, 45),
    isMine: true,
    isDemo: true,
  );

  group('ListingCodec', () {
    test('round-trip preserves every field', () {
      final decoded = ListingCodec.fromJsonMap(ListingCodec.toJsonMap(listing));
      expect(decoded, listing);
    });

    test('dueDate round-trips as a date, never shifted by timezone', () {
      final map = ListingCodec.toJsonMap(listing);
      expect(map['dueDate'], '2026-07-15');
      final decoded = ListingCodec.fromJsonMap(map)!;
      expect(decoded.dueDate, DateTime(2026, 7, 15));
    });

    test('old/partial schema decodes with defaults', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'old-1',
        'title': 'Old row',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(decoded, isNotNull);
      expect(decoded!.type, ListingType.offer);
      expect(decoded.category, Category.other);
      expect(decoded.status, InteractionStatus.saved);
      expect(decoded.lendingState, LendingState.available);
      expect(decoded.conditionTags, isEmpty);
      expect(decoded.borrowerName, isEmpty);
      expect(decoded.photoBase64, isNull);
      expect(decoded.isMine, isFalse);
      expect(decoded.isDemo, isFalse);
    });

    test('repairs lentOut-without-dueDate instead of refusing to load', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'broken-1',
        'title': 'Broken row',
        'lendingState': 'lentOut',
      });
      expect(decoded, isNotNull);
      expect(decoded!.lendingState, LendingState.available);
      expect(decoded.dueDate, isNull);
    });

    test('drops dueDate when state is not lentOut', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'stale-due',
        'title': 'Stale due date',
        'lendingState': 'available',
        'dueDate': '2026-07-20',
      });
      expect(decoded!.dueDate, isNull);
    });

    test('missing id or title → null (row skipped)', () {
      expect(ListingCodec.fromJsonMap({'title': 'No id'}), isNull);
      expect(ListingCodec.fromJsonMap({'id': 'no-title'}), isNull);
    });

    test('unknown enum names fall back safely', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'weird-1',
        'title': 'Weird enums',
        'type': 'auction',
        'category': 'spaceships',
        'status': 'ghosted',
      });
      expect(decoded!.type, ListingType.offer);
      expect(decoded.category, Category.other);
      expect(decoded.status, InteractionStatus.saved);
    });
  });
}

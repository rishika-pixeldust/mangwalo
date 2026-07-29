import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/data/listing_codec.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  final listing = Listing(
    id: 'id-1',
    type: ListingType.offer,
    title: 'Cricket bat, size 6',
    description: 'Kashmir-willow bat, lightly taped handle.',
    category: Category.sportsKits,
    subCategory: 'Cricket',
    contactChannel: ContactChannel.buildingWhatsApp,
    conditionTags: const ['Gently used'],
    area: 'Opposite Jogger\'s Park',
    neighborhood: 'Bandra West',
    pricePerDayInr: 900,
    depositInr: 3000,
    status: InteractionStatus.contacted,
    lendingState: LendingState.lentOut,
    dueDate: DateTime(2026, 7, 15),
    borrowerName: 'Asha',
    suggestedDurationDays: 7,
    photos: const ['aGVsbG8=', 'd29ybGQ='],
    reviews: [
      Review(
        rating: 5,
        text: 'Kit was complete and the owner was punctual.',
        reviewerName: 'Rohan',
        createdAt: DateTime(2026, 7, 5, 9, 0),
      ),
    ],
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
      expect(decoded.subCategory, isEmpty);
      expect(decoded.status, InteractionStatus.saved);
      expect(decoded.lendingState, LendingState.available);
      expect(decoded.conditionTags, isEmpty);
      expect(decoded.borrowerName, isEmpty);
      expect(decoded.photos, isEmpty);
      expect(decoded.reviews, isEmpty);
      expect(decoded.pricePerDayInr, 0);
      expect(decoded.depositInr, isNull);
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

    test('legacy v1 photoBase64 migrates into a one-element gallery', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'v1-row',
        'title': 'Old photo row',
        'photoBase64': 'aGVsbG8=',
      });
      expect(decoded!.photos, ['aGVsbG8=']);
    });

    test('malformed reviews are skipped, valid ones kept', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'rev-row',
        'title': 'Review row',
        'reviews': [
          {'rating': 9, 'text': 'impossible rating'},
          {'text': 'no rating'},
          {'rating': 4, 'text': 'valid one', 'reviewerName': 'Ira'},
        ],
      });
      expect(decoded!.reviews, hasLength(1));
      expect(decoded.reviews.single.rating, 4);
      expect(decoded.reviews.single.reviewerName, 'Ira');
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

    test('contact preference survives, the free-text note does not', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'v2-row',
        'title': 'Row with a retired note',
        'contactChannel': 'buildingWhatsApp',
        'contactNote': 'R. Nair — building group, ring twice',
      })!;
      // The preference is a closed enum and is kept; the free-text note was
      // the likeliest place a phone number ended up, so it is never read and
      // never re-emitted.
      expect(decoded.contactChannel, ContactChannel.buildingWhatsApp);
      final reEncoded = ListingCodec.toJsonMap(decoded);
      expect(reEncoded['contactChannel'], 'buildingWhatsApp');
      expect(reEncoded.containsKey('contactNote'), isFalse);
      expect(reEncoded['v'], 3);
    });

    test('an unknown contact preference falls back safely', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'weird-contact',
        'title': 'Weird contact',
        'contactChannel': 'carrier_pigeon',
      })!;
      expect(decoded.contactChannel, ContactChannel.societyBoard);
    });

    test('over-long free-text sub-category is capped at the storage boundary',
        () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'long-sub',
        'title': 'Custom category row',
        'category': 'other',
        'subCategory': 'x' * (kMaxSubCategoryLength + 40),
      })!;
      expect(decoded.subCategory.length, kMaxSubCategoryLength);
    });

    test('sub-category whitespace is trimmed', () {
      final decoded = ListingCodec.fromJsonMap({
        'id': 'ws-sub',
        'title': 'Whitespace row',
        'subCategory': '  Kundan  ',
      })!;
      expect(decoded.subCategory, 'Kundan');
    });
  });
}

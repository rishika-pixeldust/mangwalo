import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/domain/feed_filter.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  final now = DateTime(2026, 7, 13);

  Listing make(
    String id, {
    ListingType type = ListingType.offer,
    Category category = Category.sportsKits,
    String title = 'Test item',
    String description = 'A perfectly ordinary description.',
    String area = 'Near the market',
    InteractionStatus status = InteractionStatus.saved,
    LendingState lendingState = LendingState.available,
    DateTime? dueDate,
    DateTime? updatedAt,
    bool isMine = false,
    bool isDemo = false,
    String neighborhood = 'Powai',
    String subCategory = '',
  }) {
    return Listing(
      id: id,
      isMine: isMine,
      isDemo: isDemo,
      subCategory: subCategory,
      type: type,
      title: title,
      description: description,
      category: category,
      area: area,
      neighborhood: neighborhood,
      pricePerDayInr: 900,
      status: status,
      lendingState: lendingState,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('FeedFilter.apply', () {
    test('type filter keeps only matching listings', () {
      final listings = [
        make('a', type: ListingType.offer),
        make('b', type: ListingType.request),
      ];
      const filter = FeedFilter(type: ListingType.request);
      expect(filter.apply(listings, now).map((l) => l.id), ['b']);
    });

    test('category filter', () {
      final listings = [
        make('a', category: Category.designerBags),
        make('b', category: Category.sportsKits),
      ];
      const filter = FeedFilter(category: Category.designerBags);
      expect(filter.apply(listings, now).map((l) => l.id), ['a']);
    });

    test('query matches title, description, and area', () {
      final listings = [
        make('a', title: 'Cricket bat'),
        make('b', description: 'includes a cricket ball too'),
        make('c', area: 'Near cricket maidan'),
        make('d', title: 'Ladder'),
      ];
      const filter = FeedFilter(query: 'cricket');
      expect(filter.apply(listings, now).map((l) => l.id).toSet(),
          {'a', 'b', 'c'});
    });

    test('mineOnly keeps only listings created on this device', () {
      final listings = [
        make('mine', isMine: true),
        make('board'),
      ];
      const filter = FeedFilter(mineOnly: true);
      expect(filter.apply(listings, now).map((l) => l.id), ['mine']);
    });

    test('closed listings hidden by default, shown when toggled', () {
      final listings = [
        make('a', status: InteractionStatus.closed),
        make('b'),
      ];
      expect(const FeedFilter().apply(listings, now).map((l) => l.id), ['b']);
      expect(
          const FeedFilter(showClosed: true)
              .apply(listings, now)
              .map((l) => l.id)
              .toSet(),
          {'a', 'b'});
    });


    group('locality scoping', () {
      final board = [
        make('powai-1', neighborhood: 'Powai'),
        make('powai-2', neighborhood: 'Powai'),
        make('bandra-1', neighborhood: 'Bandra West'),
        make('dadar-1', neighborhood: 'Dadar'),
      ];

      test('scopes the board to one locality', () {
        final shown = const FeedFilter(neighborhood: 'Powai').apply(board, now);
        expect(shown.map((l) => l.id), {'powai-1', 'powai-2'});
      });

      test('switching locality changes what the board shows', () {
        // The reported bug: the header changed but the listings did not.
        final powai = const FeedFilter(neighborhood: 'Powai').apply(board, now);
        final bandra =
            const FeedFilter(neighborhood: 'Bandra West').apply(board, now);
        expect(powai.map((l) => l.id), isNot(bandra.map((l) => l.id)));
        expect(bandra.map((l) => l.id), ['bandra-1']);
      });

      test('null locality shows every locality', () {
        expect(const FeedFilter().apply(board, now), hasLength(4));
      });

      test('your own listings stay visible from any locality', () {
        final withMine = [...board, make('mine', neighborhood: 'Chembur', isMine: true)];
        final shown = const FeedFilter(neighborhood: 'Powai').apply(withMine, now);
        expect(shown.map((l) => l.id), contains('mine'));
      });
    });

    test('hideSamples drops demo rows but keeps real ones', () {
      final listings = [
        make('real'),
        make('sample', isDemo: true),
      ];
      expect(const FeedFilter().apply(listings, now), hasLength(2));
      expect(const FeedFilter(hideSamples: true).apply(listings, now).single.id,
          'real');
    });

    test('sub-category narrows within a category', () {
      final listings = [
        make('kundan', category: Category.jewellery, subCategory: 'Kundan'),
        make('polki', category: Category.jewellery, subCategory: 'Polki'),
        make('bag', category: Category.designerBags, subCategory: 'Tote'),
      ];
      final shown = const FeedFilter(
              category: Category.jewellery, subCategory: 'Kundan')
          .apply(listings, now);
      expect(shown.single.id, 'kundan');
    });

    test('search also matches the sub-category', () {
      final listings = [
        make('a', subCategory: 'Jhumkas', title: 'Gold pair'),
        make('b', subCategory: 'Tote', title: 'Brown bag'),
      ];
      expect(const FeedFilter(query: 'jhumka').apply(listings, now).single.id,
          'a');
    });

    test('locality and sample scoping do not count as user filters', () {
      // Otherwise a "clear filters" affordance would show permanently.
      const scoped = FeedFilter(neighborhood: 'Powai', hideSamples: true);
      expect(scoped.isDefault, isTrue);
      expect(const FeedFilter(query: 'x').isDefault, isFalse);
    });

    test('sorting: overdue first, then due-soonest, then latest update', () {
      final listings = [
        make('fresh', updatedAt: DateTime(2026, 7, 12)),
        make('stale', updatedAt: DateTime(2026, 7, 1)),
        make('dueSoon',
            lendingState: LendingState.lentOut,
            dueDate: DateTime(2026, 7, 15)),
        make('dueLater',
            lendingState: LendingState.lentOut,
            dueDate: DateTime(2026, 7, 20)),
        make('overdue',
            lendingState: LendingState.lentOut,
            dueDate: DateTime(2026, 7, 8)),
      ];
      final sorted = const FeedFilter().apply(listings, now);
      expect(sorted.map((l) => l.id).toList(),
          ['overdue', 'dueSoon', 'dueLater', 'fresh', 'stale']);
    });
  });
}

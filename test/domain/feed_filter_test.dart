import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/domain/feed_filter.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  final now = DateTime(2026, 7, 13);

  Listing make(
    String id, {
    ListingType type = ListingType.offer,
    Category category = Category.toolsRepair,
    String title = 'Test item',
    String description = 'A perfectly ordinary description.',
    String area = 'Near the market',
    InteractionStatus status = InteractionStatus.saved,
    LendingState lendingState = LendingState.available,
    DateTime? dueDate,
    DateTime? updatedAt,
    bool isMine = false,
  }) {
    return Listing(
      id: id,
      isMine: isMine,
      type: type,
      title: title,
      description: description,
      category: category,
      area: area,
      neighborhood: 'Powai',
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
        make('a', category: Category.booksStudy),
        make('b', category: Category.toolsRepair),
      ];
      const filter = FeedFilter(category: Category.booksStudy);
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

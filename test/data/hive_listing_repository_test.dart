import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mangwalo/src/features/listings/data/hive_listing_repository.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late HiveListingRepository repo;

  Listing make(String id, {String title = 'Cricket kit'}) => Listing(
        id: id,
        type: ListingType.offer,
        title: title,
        description: 'Kashmir-willow bat, lightly taped handle.',
        category: Category.sportsKits,
        area: 'Near the market',
        neighborhood: 'Powai',
        pricePerDayInr: 900,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mangwalo_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('listings_test');
    repo = HiveListingRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('HiveListingRepository', () {
    test('put + getAll + getById round-trip through real Hive', () async {
      final listing = make('a');
      await repo.put(listing);
      expect(await repo.getAll(), [listing]);
      expect(await repo.getById('a'), listing);
      expect(await repo.getById('missing'), isNull);
    });

    test('put is an upsert', () async {
      await repo.put(make('a'));
      await repo.put(make('a', title: 'Taller ladder'));
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.title, 'Taller ladder');
    });

    test('watchAll emits current list immediately, then on change', () async {
      await repo.put(make('a'));
      final emissions = <List<Listing>>[];
      final sub = repo.watchAll().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emissions, hasLength(1));
      expect(emissions.first, hasLength(1));

      await repo.put(make('b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emissions.last, hasLength(2));
      await sub.cancel();
    });

    test('delete and clear', () async {
      await repo.putAll([make('a'), make('b')]);
      await repo.delete('a');
      expect((await repo.getAll()).map((l) => l.id), ['b']);
      await repo.clear();
      expect(await repo.getAll(), isEmpty);
    });

    test('sanitizes at the storage boundary (defense in depth)', () async {
      await repo.put(make('a', title: '  spaced   out   title  '));
      expect((await repo.getById('a'))!.title, 'spaced out title');
    });

    test('corrupt row is skipped, not fatal', () async {
      await repo.put(make('a'));
      await box.put('corrupt', 'not-json-at-all{{{');
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'a');
    });
  });
}

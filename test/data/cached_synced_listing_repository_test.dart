import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/listings/data/cached_synced_listing_repository.dart';
import 'package:mangwalo/src/features/listings/data/in_memory_listing_repository.dart';
import 'package:mangwalo/src/features/listings/data/supabase_listing_source.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

/// Stands in for Supabase so the read-offline / write-online contract can be
/// tested without a network or a project. Only the surface
/// [CachedSyncedListingRepository] actually touches is implemented.
class _FakeRemote implements SupabaseListingSource {
  _FakeRemote({this.rows = const [], this.offline = false, this.signedIn = true});

  List<Listing> rows;
  bool offline;
  bool signedIn;

  int fetchCount = 0;
  final List<Listing> upserted = [];
  final List<String> deleted = [];
  final List<List<String>> uploadCalls = [];

  void _guard() {
    if (offline) throw const OfflineWriteException('offline');
    if (!signedIn) throw const OfflineWriteException('sign in');
  }

  @override
  Future<List<Listing>> fetchAll() async {
    fetchCount++;
    if (offline) throw const OfflineWriteException('offline');
    return rows;
  }

  @override
  Future<void> upsert(Listing listing) async {
    _guard();
    upserted.add(listing);
  }

  @override
  Future<void> upsertAll(List<Listing> listings) async {
    _guard();
    upserted.addAll(listings);
  }

  @override
  Future<void> delete(String id) async {
    _guard();
    deleted.add(id);
  }

  /// Mirrors the real contract: base64 becomes a URL, existing URLs pass through.
  @override
  Future<List<String>> uploadPhotos(String listingId, List<String> photos) async {
    _guard();
    uploadCalls.add(photos);
    return [
      for (var i = 0; i < photos.length; i++)
        if (photos[i].startsWith('http'))
          photos[i]
        else
          'https://cdn.test/$listingId-$i.jpg',
    ];
  }

  @override
  String? get currentUserId => signedIn ? 'user-1' : null;

  @override
  bool get isSignedIn => signedIn;
}

Listing _listing(
  String id, {
  List<String> photos = const [],
  bool isDemo = false,
  bool isMine = false,
  String title = 'Test item',
}) =>
    Listing(
      id: id,
      isDemo: isDemo,
      isMine: isMine,
      type: ListingType.offer,
      title: title,
      description: 'A perfectly ordinary description.',
      category: Category.designerBags,
      area: 'Near the market',
      neighborhood: 'Bandra West',
      pricePerDayInr: 900,
      photos: photos,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

void main() {
  late InMemoryListingRepository cache;
  late _FakeRemote remote;
  late CachedSyncedListingRepository repo;

  setUp(() {
    cache = InMemoryListingRepository();
    remote = _FakeRemote();
    repo = CachedSyncedListingRepository(cache: cache, remote: remote);
  });

  group('reads work offline', () {
    test('getAll serves the cache without touching the network', () async {
      await cache.put(_listing('cached'));
      remote.offline = true;

      final all = await repo.getAll();
      expect(all.single.id, 'cached');
      expect(remote.fetchCount, 0, reason: 'reads must not require a request');
    });

    test('a failed refresh leaves the cached board intact', () async {
      await cache.put(_listing('cached'));
      remote.offline = true;

      await repo.refresh();
      expect((await repo.getAll()).single.id, 'cached');
    });

    test('refresh pulls server rows into the cache', () async {
      remote.rows = [_listing('remote-1'), _listing('remote-2')];
      await repo.refresh();

      expect((await cache.getAll()).map((l) => l.id),
          containsAll(['remote-1', 'remote-2']));
    });

    test('concurrent refreshes share one request', () async {
      remote.rows = [_listing('r')];
      await Future.wait([repo.refresh(), repo.refresh(), repo.refresh()]);
      expect(remote.fetchCount, 1);
    });

    test('an empty server response never wipes the cache', () async {
      // Guards against a fresh install or an RLS refusal blanking the board.
      await cache.put(_listing('local'));
      remote.rows = const [];

      await repo.refresh();
      expect((await repo.getAll()).single.id, 'local');
    });
  });

  group('refresh reconciles deletions', () {
    test('a synced row the server no longer has is dropped', () async {
      await cache.put(_listing('gone', photos: ['https://cdn.test/a.jpg']));
      remote.rows = [_listing('still-there')];

      await repo.refresh();
      expect((await repo.getAll()).map((l) => l.id), ['still-there']);
    });

    test('sample rows survive reconcile', () async {
      // Samples are shared reference data, not something this device owns.
      await cache.put(_listing('sample-1', isDemo: true));
      remote.rows = [_listing('other')];

      await repo.refresh();
      expect((await repo.getAll()).map((l) => l.id), contains('sample-1'));
    });

    test('my own listing is never deleted by reconcile', () async {
      // A row created in Phase A, before this device had any backend, exists
      // only here. Reconcile must not be what destroys it.
      await cache.put(_listing('mine-from-phase-a', isMine: true));
      remote.rows = [_listing('other')];

      await repo.refresh();
      expect((await repo.getAll()).map((l) => l.id),
          contains('mine-from-phase-a'));
    });

    test('my own photo-less listing also survives', () async {
      // Regression: an earlier rule inferred "synced" from having no photos,
      // which silently deleted exactly this row.
      await cache.put(_listing('no-photos', isMine: true, photos: const []));
      remote.rows = [_listing('other')];

      await repo.refresh();
      expect((await repo.getAll()).map((l) => l.id), contains('no-photos'));
    });
  });

  group('writes require the network', () {
    test('put uploads photos, then stores the URL form in the cache', () async {
      await repo.put(_listing('with-photos', photos: const ['aGVsbG8=']));

      expect(remote.uploadCalls.single, const ['aGVsbG8=']);
      final stored = await cache.getById('with-photos');
      expect(stored!.photos.single, 'https://cdn.test/with-photos-0.jpg');
      expect(remote.upserted.single.photos.single, startsWith('https://'));
    });

    test('already-uploaded photos are not re-uploaded', () async {
      const url = 'https://cdn.test/existing.jpg';
      await repo.put(_listing('again', photos: const [url]));
      expect((await cache.getById('again'))!.photos.single, url);
    });

    test('put offline throws and writes nothing anywhere', () async {
      remote.offline = true;

      await expectLater(
        repo.put(_listing('nope')),
        throwsA(isA<OfflineWriteException>()),
      );
      expect(await cache.getById('nope'), isNull,
          reason: 'a rejected write must not appear to have succeeded');
    });

    test('put while signed out throws', () async {
      remote.signedIn = false;
      await expectLater(
        repo.put(_listing('anon')),
        throwsA(isA<OfflineWriteException>()),
      );
    });

    test('delete offline throws and keeps the cached row', () async {
      await cache.put(_listing('keep'));
      remote.offline = true;

      await expectLater(
          repo.delete('keep'), throwsA(isA<OfflineWriteException>()));
      expect(await cache.getById('keep'), isNotNull);
    });

    test('delete online removes it from both sides', () async {
      await cache.put(_listing('bye'));
      await repo.delete('bye');

      expect(remote.deleted.single, 'bye');
      expect(await cache.getById('bye'), isNull);
    });
  });

  test('clear is local-only — never deletes the shared board', () async {
    await cache.put(_listing('mine'));
    await repo.clear();

    expect(await cache.getAll(), isEmpty);
    expect(remote.deleted, isEmpty,
        reason: '"Reset all local data" must not wipe the neighbourhood');
  });

  test('watchAll emits the cache immediately, before any refresh', () async {
    await cache.put(_listing('instant'));
    remote.rows = [_listing('later')];

    final first = await repo.watchAll().first;
    expect(first.single.id, 'instant');
  });
}

import 'dart:async';

import '../domain/listing.dart';
import 'listing_repository.dart';
import 'supabase_listing_source.dart';

/// The shared noticeboard with the local box in front of it — the phase-2
/// implementation ADR-0001 anticipated, dropped in behind the same interface
/// the UI has always used.
///
/// Read-offline / write-online, deliberately:
///
///  * **Reads** always come from the cache, so the board paints instantly and
///    keeps working with no connection. A remote refresh runs alongside and
///    updates the cache, which re-emits through the cache's own stream.
///  * **Writes** go to the server first and are only cached once it accepts
///    them. There is no offline queue, so the UI can promise that what you see
///    is what everyone sees — and an offline write fails loudly
///    ([OfflineWriteException]) instead of silently diverging.
///
/// [clear] is local-only on purpose: "Reset all local data" must never be a
/// button that deletes the neighbourhood's noticeboard.
class CachedSyncedListingRepository implements ListingRepository {
  CachedSyncedListingRepository({
    required this.cache,
    required this.remote,
  });

  /// The local box. Serves every read so the board never waits on a request.
  final ListingRepository cache;

  /// The shared noticeboard. Required for every write.
  final SupabaseListingSource remote;

  Future<void>? _inFlightRefresh;

  @override
  Future<List<Listing>> getAll() => cache.getAll();

  @override
  Future<Listing?> getById(String id) => cache.getById(id);

  @override
  Stream<List<Listing>> watchAll() {
    // Kick off a refresh but do not await it: the first frame comes from the
    // cache, and remote data arrives as a later emission.
    refresh();
    return cache.watchAll();
  }

  /// Pulls the server's view into the cache. Safe to call often — concurrent
  /// calls share one request — and safe to fail: offline just means the cache
  /// stays as it is.
  Future<void> refresh() {
    return _inFlightRefresh ??= _refresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<void> _refresh() async {
    try {
      final fromServer = await remote.fetchAll();
      if (fromServer.isEmpty) return;
      // Reconcile rather than blindly overwrite: a row that exists locally but
      // not remotely was deleted by its owner, so drop it. Anything the server
      // does not know about (a local-only draft) is left alone.
      final local = await cache.getAll();
      final remoteIds = {for (final l in fromServer) l.id};
      for (final l in local) {
        if (!remoteIds.contains(l.id) && _isServerOwned(l)) {
          await cache.delete(l.id);
        }
      }
      await cache.putAll(fromServer);
    } on Object {
      // Offline, RLS refusal, or a transient error — the cached board stands.
    }
  }

  /// Whether a cached row is one the server is authoritative for, and may
  /// therefore be removed when the server stops returning it.
  ///
  /// Only *other people's* listings qualify. They can only ever have arrived
  /// from a fetch, so their absence means the owner deleted them.
  ///
  /// Deliberately excluded:
  ///  * **your own listings** — a row created before this device ever had a
  ///    backend (or while signed out) exists only here, and reconcile must
  ///    never be the thing that destroys it. Your deletions go through
  ///    [delete], which removes both sides explicitly.
  ///  * **samples** — shared reference data this device does not own.
  bool _isServerOwned(Listing l) => !l.isMine && !l.isDemo;

  @override
  Future<void> put(Listing listing) async {
    // Photos upload first so the row we store already points at Storage.
    final photos = await remote.uploadPhotos(listing.id, listing.photos);
    final synced = listing.photos == photos
        ? listing
        : listing.copyWith(photos: photos);
    await remote.upsert(synced);
    await cache.put(synced);
  }

  @override
  Future<void> putAll(List<Listing> listings) async {
    await remote.upsertAll(listings);
    await cache.putAll(listings);
  }

  @override
  Future<void> delete(String id) async {
    await remote.delete(id);
    await cache.delete(id);
  }

  /// Local only — see the class doc.
  @override
  Future<void> clear() => cache.clear();
}

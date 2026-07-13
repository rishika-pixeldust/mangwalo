import 'dart:async';

import '../domain/listing.dart';
import 'listing_repository.dart';

/// Pure in-memory implementation. Used as the widget-test double and as the
/// runtime fallback when browser storage is unavailable (e.g. strict private
/// mode) so the app degrades gracefully instead of white-screening.
class InMemoryListingRepository implements ListingRepository {
  InMemoryListingRepository([List<Listing>? initial]) {
    if (initial != null) {
      for (final l in initial) {
        _store[l.id] = l;
      }
    }
  }

  final _store = <String, Listing>{};
  final _controller = StreamController<List<Listing>>.broadcast();

  List<Listing> get _snapshot => _store.values.toList();

  void _emit() => _controller.add(_snapshot);

  @override
  Future<List<Listing>> getAll() async => _snapshot;

  @override
  Stream<List<Listing>> watchAll() {
    late StreamController<List<Listing>> controller;
    StreamSubscription<List<Listing>>? subscription;
    controller = StreamController<List<Listing>>(
      onListen: () {
        controller.add(_snapshot);
        subscription = _controller.stream.listen(controller.add);
      },
      onCancel: () async {
        await subscription?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Listing?> getById(String id) async => _store[id];

  @override
  Future<void> put(Listing listing) async {
    _store[listing.id] = listing;
    _emit();
  }

  @override
  Future<void> putAll(List<Listing> listings) async {
    for (final l in listings) {
      _store[l.id] = l;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Future<void> clear() async {
    _store.clear();
    _emit();
  }
}

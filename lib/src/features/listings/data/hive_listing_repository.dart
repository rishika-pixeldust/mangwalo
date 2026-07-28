import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../core/validation/sanitizer.dart';
import '../../../core/validation/validators.dart';
import '../domain/listing.dart';
import 'listing_codec.dart';
import 'listing_repository.dart';

/// Hive CE implementation: a `Box<String>` of JSON blobs keyed by listing id
/// (IndexedDB on web). JSON-over-strings sidesteps Hive's dynamic-map cast
/// pitfalls and keeps schema evolution in one tolerant codec.
class HiveListingRepository implements ListingRepository {
  HiveListingRepository(this._box);

  final Box<String> _box;

  @override
  Future<List<Listing>> getAll() async => _decodeAll();

  @override
  Stream<List<Listing>> watchAll() {
    // Explicit controller instead of async* — an async* generator parked in
    // `await for` only honors cancellation at its next yield, which would
    // hang subscribers that cancel while the box is quiet.
    late StreamController<List<Listing>> controller;
    StreamSubscription<BoxEvent>? subscription;
    controller = StreamController<List<Listing>>(
      onListen: () {
        controller.add(_decodeAll());
        subscription =
            _box.watch().listen((_) => controller.add(_decodeAll()));
      },
      onCancel: () async {
        await subscription?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Listing?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  @override
  Future<void> put(Listing listing) async {
    await _box.put(listing.id, jsonEncode(ListingCodec.toJsonMap(_clean(listing))));
  }

  @override
  Future<void> putAll(List<Listing> listings) async {
    await _box.putAll({
      for (final l in listings)
        l.id: jsonEncode(ListingCodec.toJsonMap(_clean(l))),
    });
  }

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  /// Defense in depth: sanitize again at the storage boundary even though the
  /// form layer already did.
  Listing _clean(Listing l) => l.copyWith(
        title: sanitize(l.title, maxLength: Validators.titleMax),
        description: sanitize(l.description,
            maxLength: Validators.descriptionMax, multiline: true),
        area: sanitize(l.area, maxLength: Validators.areaMax),
        subCategory:
            sanitize(l.subCategory, maxLength: kMaxSubCategoryLength),
      );

  List<Listing> _decodeAll() =>
      _box.values.map(_decode).whereType<Listing>().toList();

  Listing? _decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return ListingCodec.fromJsonMap(map);
    } catch (_) {
      // Skip undecodable rows rather than breaking the whole feed.
      return null;
    }
  }
}

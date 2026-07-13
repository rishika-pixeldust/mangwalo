import '../domain/listing.dart';

/// Storage boundary for listings. The UI and application layers only ever see
/// this interface — Hive today, a synced backend (Supabase-style) in phase 2.
/// That swap is the primary change point recorded in ADR-0001.
abstract interface class ListingRepository {
  Future<List<Listing>> getAll();

  /// Emits the current list immediately on listen, then again on every change.
  Stream<List<Listing>> watchAll();

  Future<Listing?> getById(String id);

  /// Upsert by [Listing.id].
  Future<void> put(Listing listing);

  Future<void> putAll(List<Listing> listings);

  Future<void> delete(String id);

  /// Removes everything — backs the "Reset all local data" control.
  Future<void> clear();
}

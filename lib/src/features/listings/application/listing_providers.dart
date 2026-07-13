import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../ai/local_ai_service.dart';
import '../../ai/rule_based_listing_ai.dart';
import '../domain/listing.dart';
import '../data/listing_repository.dart';
import 'feed_filter_controller.dart';

/// Overridden in main() with the Hive-backed implementation (or the
/// in-memory fallback when browser storage is unavailable).
final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => throw UnimplementedError('Overridden at bootstrap'),
);

/// False when the app is running on the in-memory fallback — the UI shows a
/// "changes won't persist" banner.
final storageAvailableProvider = Provider<bool>((ref) => true);

/// ADR-0001 change point: swap the rule engine for an on-device model here,
/// in one line, without touching any call site.
final localAiServiceProvider =
    Provider<LocalAiService>((ref) => const RuleBasedListingAi());

final listingsProvider = StreamProvider<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).watchAll(),
);

/// Feed pipeline: repository stream + filter, filtered and sorted by the pure
/// FeedFilter.apply (overdue first, then due-soonest, then latest update).
final filteredListingsProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final listings = ref.watch(listingsProvider);
  final filter = ref.watch(feedFilterProvider);
  final now = ref.watch(nowProvider);
  return listings.whenData((list) => filter.apply(list, now()));
});

final listingByIdProvider = Provider.family<Listing?, String>((ref, id) {
  final listings = ref.watch(listingsProvider).value;
  if (listings == null) return null;
  for (final l in listings) {
    if (l.id == id) return l;
  }
  return null;
});

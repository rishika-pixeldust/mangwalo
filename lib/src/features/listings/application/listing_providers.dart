import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../ai/local_ai_service.dart';
import '../../ai/rule_based_listing_ai.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/feed_filter.dart';
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

/// True once Supabase initialised successfully. False means local-only mode:
/// everything on-device keeps working, and the social features say plainly
/// that they need the shared noticeboard rather than failing mid-action.
final backendReadyProvider = Provider<bool>((ref) => false);

/// ADR-0001 change point: swap the rule engine for an on-device model here,
/// in one line, without touching any call site.
final localAiServiceProvider =
    Provider<LocalAiService>((ref) => const RuleBasedListingAi());

final listingsProvider = StreamProvider<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).watchAll(),
);

/// The filter actually applied to the board: the user's filter-bar choices,
/// plus the two scoping rules that live in Settings rather than the filter bar
/// (active locality and whether samples are hidden).
///
/// Composing them here is what makes switching locality refresh the board —
/// this provider watches settings, so a new locality produces a new filter.
final effectiveFeedFilterProvider = Provider<FeedFilter>((ref) {
  final chosen = ref.watch(feedFilterProvider);
  final settings = ref.watch(settingsProvider);
  return chosen.copyWith(
    neighborhood: settings.showAllLocalities ? null : settings.neighborhood,
    hideSamples: settings.hideSamples,
  );
});

/// Feed pipeline: repository stream + filter, filtered and sorted by the pure
/// FeedFilter.apply (overdue first, then due-soonest, then latest update).
final filteredListingsProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final listings = ref.watch(listingsProvider);
  final filter = ref.watch(effectiveFeedFilterProvider);
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

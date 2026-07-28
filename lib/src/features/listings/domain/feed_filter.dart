import 'package:flutter/foundation.dart' hide Category;

import 'due_info.dart';
import 'listing.dart';

const Object _unset = Object();

/// Pure, immutable feed filter state. [apply] does all filtering and sorting
/// so the whole feed pipeline is unit-testable without widgets or providers.
@immutable
class FeedFilter {
  const FeedFilter({
    this.type,
    this.category,
    this.subCategory,
    this.query = '',
    this.showClosed = false,
    this.mineOnly = false,
    this.neighborhood,
    this.hideSamples = false,
  });

  /// null means both offers and requests.
  final ListingType? type;

  /// null means all categories.
  final Category? category;

  /// Second-level filter; only meaningful with [category] set. null = all.
  final String? subCategory;
  final String query;
  final bool showClosed;

  /// "Mine" chip: only listings created on this device.
  final bool mineOnly;

  /// Locality scope. null shows every locality ("Show all localities").
  /// Composed from settings rather than set by the filter bar, so switching
  /// locality in Settings genuinely re-scopes the board.
  final String? neighborhood;

  /// Drops the badged sample rows from the board.
  final bool hideSamples;

  /// Whether the user's own filter choices are untouched. Locality and sample
  /// scoping are settings, not filter-bar state, so they don't count here —
  /// otherwise the "clear filters" affordance would appear permanently.
  bool get isDefault =>
      type == null &&
      category == null &&
      subCategory == null &&
      query.isEmpty &&
      !showClosed;

  FeedFilter copyWith({
    Object? type = _unset,
    Object? category = _unset,
    Object? subCategory = _unset,
    String? query,
    bool? showClosed,
    bool? mineOnly,
    Object? neighborhood = _unset,
    bool? hideSamples,
  }) {
    return FeedFilter(
      type: identical(type, _unset) ? this.type : type as ListingType?,
      category:
          identical(category, _unset) ? this.category : category as Category?,
      subCategory: identical(subCategory, _unset)
          ? this.subCategory
          : subCategory as String?,
      query: query ?? this.query,
      showClosed: showClosed ?? this.showClosed,
      mineOnly: mineOnly ?? this.mineOnly,
      neighborhood: identical(neighborhood, _unset)
          ? this.neighborhood
          : neighborhood as String?,
      hideSamples: hideSamples ?? this.hideSamples,
    );
  }

  /// Filters then sorts: overdue first (most overdue at top), then lent-out
  /// items by soonest due date, then everything else by latest update.
  List<Listing> apply(List<Listing> listings, DateTime now) {
    final q = query.trim().toLowerCase();
    final filtered = listings.where((l) {
      if (mineOnly && !l.isMine) return false;
      // Your own listings stay visible even when browsing another locality —
      // losing sight of an item you have lent out would be alarming.
      if (neighborhood != null && l.neighborhood != neighborhood && !l.isMine) {
        return false;
      }
      if (hideSamples && l.isDemo) return false;
      if (type != null && l.type != type) return false;
      if (category != null && l.category != category) return false;
      if (subCategory != null && l.subCategory != subCategory) return false;
      if (!showClosed && l.status == InteractionStatus.closed) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${l.title}\n${l.description}\n${l.area}\n${l.subCategory}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    int rank(Listing l) {
      if (l.lendingState == LendingState.lentOut && l.dueDate != null) {
        return computeDueInfo(l.dueDate!, now).isOverdue ? 0 : 1;
      }
      return 2;
    }

    filtered.sort((a, b) {
      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      if (ra < 2) return a.dueDate!.compareTo(b.dueDate!);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return filtered;
  }

  @override
  bool operator ==(Object other) =>
      other is FeedFilter &&
      other.type == type &&
      other.category == category &&
      other.subCategory == subCategory &&
      other.query == query &&
      other.showClosed == showClosed &&
      other.mineOnly == mineOnly &&
      other.neighborhood == neighborhood &&
      other.hideSamples == hideSamples;

  @override
  int get hashCode => Object.hash(type, category, subCategory, query,
      showClosed, mineOnly, neighborhood, hideSamples);
}

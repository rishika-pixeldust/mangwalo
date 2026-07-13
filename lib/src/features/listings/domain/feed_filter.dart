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
    this.query = '',
    this.showClosed = false,
    this.mineOnly = false,
  });

  /// null means both offers and requests.
  final ListingType? type;

  /// null means all categories.
  final Category? category;
  final String query;
  final bool showClosed;

  /// "My items" view: only listings created on this device.
  final bool mineOnly;

  bool get isDefault =>
      type == null && category == null && query.isEmpty && !showClosed;

  FeedFilter copyWith({
    Object? type = _unset,
    Object? category = _unset,
    String? query,
    bool? showClosed,
    bool? mineOnly,
  }) {
    return FeedFilter(
      type: identical(type, _unset) ? this.type : type as ListingType?,
      category:
          identical(category, _unset) ? this.category : category as Category?,
      query: query ?? this.query,
      showClosed: showClosed ?? this.showClosed,
      mineOnly: mineOnly ?? this.mineOnly,
    );
  }

  /// Filters then sorts: overdue first (most overdue at top), then lent-out
  /// items by soonest due date, then everything else by latest update.
  List<Listing> apply(List<Listing> listings, DateTime now) {
    final q = query.trim().toLowerCase();
    final filtered = listings.where((l) {
      if (mineOnly && !l.isMine) return false;
      if (type != null && l.type != type) return false;
      if (category != null && l.category != category) return false;
      if (!showClosed && l.status == InteractionStatus.closed) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${l.title}\n${l.description}\n${l.area}'.toLowerCase();
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
      other.query == query &&
      other.showClosed == showClosed &&
      other.mineOnly == mineOnly;

  @override
  int get hashCode => Object.hash(type, category, query, showClosed, mineOnly);
}

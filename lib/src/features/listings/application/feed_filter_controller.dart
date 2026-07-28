import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_filter.dart';
import '../domain/listing.dart';

class FeedFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void setType(ListingType? type) => state = state.copyWith(type: type);

  /// Changing category clears any sub-category picked under the previous one.
  void setCategory(Category? category) =>
      state = state.copyWith(category: category, subCategory: null);

  void setSubCategory(String? subCategory) =>
      state = state.copyWith(subCategory: subCategory);

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleShowClosed() =>
      state = state.copyWith(showClosed: !state.showClosed);

  void setMineOnly(bool mineOnly) =>
      state = state.copyWith(mineOnly: mineOnly);

  void reset() => state = const FeedFilter();
}

/// Deliberately NOT autoDispose: filter state survives pushing into a
/// listing detail and coming back.
final feedFilterProvider =
    NotifierProvider<FeedFilterController, FeedFilter>(FeedFilterController.new);

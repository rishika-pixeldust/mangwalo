import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/local_ai_service.dart';
import '../domain/listing.dart';
import 'listing_providers.dart';

/// Debounced bridge between the description field and the LocalAiService.
/// A monotonic request id keeps the UI deterministic even though the
/// boundary is async (a slow future model can never clobber newer input).
class ListingSuggestionController extends Notifier<ListingSuggestion> {
  Timer? _debounce;
  int _requestId = 0;

  static const _minChars = 12;
  static const _debounceDelay = Duration(milliseconds: 450);

  @override
  ListingSuggestion build() {
    ref.onDispose(() => _debounce?.cancel());
    return ListingSuggestion.empty;
  }

  void onDescriptionChanged(String text, {ListingType? listingType}) {
    _debounce?.cancel();
    _requestId++;
    if (text.trim().length < _minChars) {
      state = ListingSuggestion.empty;
      return;
    }
    final id = _requestId;
    _debounce = Timer(_debounceDelay, () async {
      final suggestion = await ref.read(localAiServiceProvider).suggest(
            AiSuggestionInput(description: text, listingType: listingType),
          );
      if (id == _requestId) state = suggestion;
    });
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = ListingSuggestion.empty;
  }
}

final listingSuggestionProvider = NotifierProvider.autoDispose<
    ListingSuggestionController, ListingSuggestion>(
  ListingSuggestionController.new,
);

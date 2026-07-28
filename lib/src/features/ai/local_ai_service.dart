import 'package:flutter/foundation.dart' hide Category;

import '../listings/domain/listing.dart';

/// Condition of an item, extracted from how the owner describes it.
enum ConditionTag { likeNew, gentlyUsed, wellWorn, working }

extension ConditionTagLabel on ConditionTag {
  String get label => switch (this) {
        ConditionTag.likeNew => 'Like new',
        ConditionTag.gentlyUsed => 'Gently used',
        ConditionTag.wellWorn => 'Well-worn',
        ConditionTag.working => 'Working',
      };
}

enum SuggestionConfidence { none, low, medium, high }

@immutable
class LoanDuration {
  const LoanDuration({required this.days, required this.label});

  /// Prefills the return-date picker (today + days) when the item is lent.
  final int days;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is LoanDuration && other.days == days && other.label == label;

  @override
  int get hashCode => Object.hash(days, label);
}

@immutable
class AiSuggestionInput {
  const AiSuggestionInput({required this.description, this.listingType});

  /// Free text exactly as the user typed it.
  final String description;

  /// Affects title phrasing only ("Need: …" for requests).
  final ListingType? listingType;
}

@immutable
class ListingSuggestion {
  const ListingSuggestion({
    this.suggestedTitle,
    this.suggestedCategory,
    this.suggestedSubCategory,
    this.conditionTags = const <ConditionTag>[],
    this.suggestedLoanDuration,
    this.suggestedPricePerDayInr,
    this.confidence = SuggestionConfidence.none,
  });

  static const empty = ListingSuggestion();

  final String? suggestedTitle;
  final Category? suggestedCategory;

  /// Second-level guess, always a member of [suggestedCategory]'s own
  /// sub-category list — never a free-text invention.
  final String? suggestedSubCategory;

  /// Deduped, in enum declaration order.
  final List<ConditionTag> conditionTags;
  final LoanDuration? suggestedLoanDuration;

  /// Deterministic ₹/day rate suggestion (category base, doubled for a
  /// recognized premium brand). Always a suggestion — never auto-applied.
  final int? suggestedPricePerDayInr;
  final SuggestionConfidence confidence;

  bool get isEmpty =>
      suggestedTitle == null &&
      suggestedCategory == null &&
      suggestedSubCategory == null &&
      conditionTags.isEmpty &&
      suggestedLoanDuration == null &&
      suggestedPricePerDayInr == null;

  @override
  bool operator ==(Object other) =>
      other is ListingSuggestion &&
      other.suggestedTitle == suggestedTitle &&
      other.suggestedCategory == suggestedCategory &&
      other.suggestedSubCategory == suggestedSubCategory &&
      listEquals(other.conditionTags, conditionTags) &&
      other.suggestedLoanDuration == suggestedLoanDuration &&
      other.suggestedPricePerDayInr == suggestedPricePerDayInr &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(suggestedTitle, suggestedCategory,
      suggestedSubCategory, Object.hashAll(conditionTags),
      suggestedLoanDuration, suggestedPricePerDayInr, confidence);
}

/// Drives the in-app transparency disclosure — swapping the implementation
/// automatically updates what the user is told about where suggestions
/// come from.
@immutable
class AiEngineInfo {
  const AiEngineInfo({
    required this.name,
    required this.isOnDevice,
    required this.userFacingNote,
  });

  final String name;
  final bool isOnDevice;
  final String userFacingNote;
}

/// ADR-0001 change point: the ONLY seam the app knows about for AI.
///
/// Today the implementation is [a deterministic rule engine]; tomorrow an
/// on-device model can implement the same contract and be swapped in one
/// line at the provider. Implementations MUST NOT perform network I/O, MUST
/// be deterministic for a fixed engine version, and MUST tolerate empty or
/// garbage input by returning [ListingSuggestion.empty] — never throwing.
abstract interface class LocalAiService {
  Future<ListingSuggestion> suggest(AiSuggestionInput input);

  AiEngineInfo get engineInfo;
}

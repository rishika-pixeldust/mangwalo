import '../listings/domain/listing.dart';
import 'keyword_rules.dart';
import 'local_ai_service.dart';

/// Deterministic rule engine: the primary implementation AND the permanent
/// fallback. Pure Dart — no model, no network, no randomness, no clock — so
/// the same input always produces byte-identical suggestions, online or off.
class RuleBasedListingAi implements LocalAiService {
  const RuleBasedListingAi();

  @override
  AiEngineInfo get engineInfo => const AiEngineInfo(
        name: 'Rule engine v2 (luxe)',
        isOnDevice: true,
        userFacingNote:
            'Suggestions are generated on-device and work offline. '
            'Nothing you type leaves this device.',
      );

  @override
  Future<ListingSuggestion> suggest(AiSuggestionInput input) =>
      Future.value(_suggest(input));

  ListingSuggestion _suggest(AiSuggestionInput input) {
    final normalized = _normalize(input.description);
    if (normalized.length < 3) return ListingSuggestion.empty;
    final tokens = normalized.split(' ');
    final padded = ' $normalized ';

    final (category, score, matchedEntries) = _scoreCategories(tokens, padded);
    final title = _buildTitle(
      tokens: tokens,
      padded: padded,
      category: category,
      matchedEntries: matchedEntries,
      isRequest: input.listingType == ListingType.request,
    );
    final tags = _extractConditionTags(padded);
    final duration = category != null
        ? (KeywordRules.loanDurations[category] ??
            KeywordRules.defaultLoanDuration)
        : KeywordRules.defaultLoanDuration;
    final price = _suggestPrice(category, padded);

    return ListingSuggestion(
      suggestedTitle: title,
      suggestedCategory: category,
      conditionTags: tags,
      suggestedLoanDuration: duration,
      suggestedPricePerDayInr: price,
      confidence: switch (score) {
        0 => SuggestionConfidence.none,
        1 || 2 => SuggestionConfidence.low,
        3 || 4 => SuggestionConfidence.medium,
        _ => SuggestionConfidence.high,
      },
    );
  }

  /// Category base rate, doubled when a premium brand appears anywhere in
  /// the text. Deterministic: fixed tables, no market data.
  int? _suggestPrice(Category? category, String padded) {
    final base = KeywordRules.basePricePerDayInr[category];
    if (base == null) return null;
    final premium = KeywordRules.premiumBrands
        .any((brand) => padded.contains(' $brand '));
    return premium ? base * 2 : base;
  }

  static final _nonWord = RegExp(r'[^a-z0-9+&\s]');
  static final _whitespace = RegExp(r'\s+');

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(_nonWord, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();

  /// Light plural stemming so "textbooks" matches "textbook".
  String _singular(String token) {
    if (token.length > 3 && token.endsWith('s') && !token.endsWith('ss')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  bool _entryMatches(String entry, Set<String> unigrams, String padded) {
    if (entry.contains(' ')) return padded.contains(' $entry ');
    return unigrams.contains(entry);
  }

  /// Highest score wins; ties break to the earlier Category in declaration
  /// order. Each dictionary entry counts at most once ("drill drill drill"
  /// cannot game the score).
  (Category?, int, List<String>) _scoreCategories(
      List<String> tokens, String padded) {
    final unigrams = <String>{
      for (final t in tokens) ...[t, _singular(t)],
    };

    Category? best;
    var bestScore = 0;
    var bestEntries = const <String>[];
    for (final entry in KeywordRules.categoryKeywords.entries) {
      var score = 0;
      final matched = <String>[];
      for (final keyword in entry.value) {
        if (_entryMatches(keyword, unigrams, padded)) {
          score += keyword.contains(' ') ? 3 : 1;
          matched.add(keyword);
        }
      }
      if (score > bestScore) {
        best = entry.key;
        bestScore = score;
        bestEntries = matched;
      }
    }
    return (best, bestScore, bestEntries);
  }

  /// Core noun = the longest contiguous run of tokens covered by matched
  /// keywords of the winning category ("pressure cooker", "ncert textbooks").
  /// A recognized brand is prefixed with canonical casing unless it is
  /// already part of the run. Falls back to the first few non-stopword
  /// tokens when nothing matched.
  String? _buildTitle({
    required List<String> tokens,
    required String padded,
    required Category? category,
    required List<String> matchedEntries,
    required bool isRequest,
  }) {
    String? core;
    if (category != null && matchedEntries.isNotEmpty) {
      final matchedWords = <String>{
        for (final e in matchedEntries) ...e.split(' '),
      };
      final covered = [
        for (final t in tokens)
          matchedWords.contains(t) || matchedWords.contains(_singular(t)),
      ];
      var bestStart = -1, bestLen = 0, runStart = -1, runLen = 0;
      for (var i = 0; i <= tokens.length; i++) {
        if (i < tokens.length && covered[i]) {
          if (runLen == 0) runStart = i;
          runLen++;
        } else {
          if (runLen > bestLen) {
            bestLen = runLen;
            bestStart = runStart;
          }
          runLen = 0;
        }
      }
      if (bestLen > 0) {
        core = tokens.sublist(bestStart, bestStart + bestLen).join(' ');
      }
    }

    String? title;
    if (core != null) {
      var brand = '';
      var brandPos = -1;
      for (final entry in KeywordRules.brandCasing.entries) {
        final pos = padded.indexOf(' ${entry.key} ');
        if (pos >= 0 && (brandPos == -1 || pos < brandPos)) {
          // Skip if the brand word is already inside the core noun.
          if (' $core '.contains(' ${entry.key} ')) continue;
          brand = entry.value;
          brandPos = pos;
        }
      }
      final cased = _titleCase(core);
      title = brand.isEmpty ? cased : '$brand $cased';
    } else {
      final words = tokens
          .where((t) => !KeywordRules.stopwords.contains(t))
          .take(6)
          .toList();
      if (words.isEmpty) return null;
      title = _titleCase(words.join(' '));
      if (title.length > 40) title = title.substring(0, 40).trim();
    }

    if (isRequest && !title.toLowerCase().startsWith('need')) {
      title = 'Need: $title';
    }
    if (title.length > 60) title = title.substring(0, 60).trim();
    return title;
  }

  String _titleCase(String phrase) => phrase
      .split(' ')
      .map((w) =>
          KeywordRules.acronymCasing[w] ??
          (w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)))
      .join(' ');

  List<ConditionTag> _extractConditionTags(String padded) {
    final found = <ConditionTag>{};
    for (final entry in KeywordRules.conditionPhrases.entries) {
      if (padded.contains(' ${entry.key} ')) found.add(entry.value);
    }
    final ordered = found.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return ordered;
  }
}

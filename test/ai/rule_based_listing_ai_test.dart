import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/ai/local_ai_service.dart';
import 'package:mangwalo/src/features/ai/rule_based_listing_ai.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  const engine = RuleBasedListingAi();

  Future<ListingSuggestion> suggest(String text, {ListingType? type}) =>
      engine.suggest(AiSuggestionInput(description: text, listingType: type));

  group('RuleBasedListingAi', () {
    test('Hinglish tool description → tools category, brand title, tags',
        () async {
      final s = await suggest(
          'bosch ka drill machine hai, thoda purana but works fine');
      expect(s.suggestedCategory, Category.toolsRepair);
      expect(s.suggestedTitle, 'Bosch Drill Machine');
      expect(s.conditionTags,
          [ConditionTag.wellWorn, ConditionTag.working]);
      expect(s.suggestedLoanDuration?.days, 3);
      expect(
          s.confidence.index >= SuggestionConfidence.medium.index, isTrue);
    });

    test('kitchen appliance with brand', () async {
      final s =
          await suggest('prestige pressure cooker 5 litre, barely used');
      expect(s.suggestedCategory, Category.kitchenAppliances);
      expect(s.suggestedTitle, 'Prestige Pressure Cooker');
      expect(s.conditionTags, [ConditionTag.gentlyUsed]);
      expect(s.suggestedLoanDuration?.days, 7);
    });

    test('request phrasing gets "Need:" prefix', () async {
      final s = await suggest('need a badminton racket for the weekend',
          type: ListingType.request);
      expect(s.suggestedCategory, Category.sportsFitness);
      expect(s.suggestedTitle, 'Need: Badminton Racket');
      expect(s.suggestedLoanDuration?.days, 7);
    });

    test('acronym casing preserved in titles', () async {
      final s = await suggest('old ncert textbooks class 10');
      expect(s.suggestedCategory, Category.booksStudy);
      expect(s.suggestedTitle, 'NCERT Textbooks');
      expect(s.conditionTags, [ConditionTag.wellWorn]);
      expect(s.suggestedLoanDuration?.days, 14);
    });

    test('collision: casio keyboard is music, not electronics', () async {
      final s = await suggest('casio keyboard for music class');
      expect(s.suggestedCategory, Category.musicInstruments);
      expect(s.suggestedTitle, 'Casio Keyboard');
      expect(s.suggestedLoanDuration?.days, 14);
    });

    test('collision: bare keyboard stays electronics', () async {
      final s = await suggest('spare mechanical keyboard, good condition');
      expect(s.suggestedCategory, Category.electronics);
      expect(s.conditionTags, [ConditionTag.gentlyUsed]);
      expect(s.suggestedLoanDuration?.days, 3);
    });

    test('festival decor gets festival-specific duration copy', () async {
      final s = await suggest('diwali ki fairy lights 10 meter');
      expect(s.suggestedCategory, Category.festivalDecor);
      expect(s.suggestedTitle, 'Fairy Lights');
      expect(s.suggestedLoanDuration?.label, contains('festival'));
    });

    test('empty input → empty suggestion, no throw', () async {
      final s = await suggest('');
      expect(s, ListingSuggestion.empty);
      expect(s.confidence, SuggestionConfidence.none);
    });

    test('garbage input → fallback title, no category', () async {
      final s = await suggest('zzz qwerty asdf');
      expect(s.suggestedCategory, isNull);
      expect(s.suggestedTitle, 'Zzz Qwerty Asdf');
      expect(s.confidence, SuggestionConfidence.none);
    });

    test('deterministic: same input twice → identical output', () async {
      const input = 'bosch ka drill machine hai, thoda purana but works fine';
      final first = await suggest(input);
      final second = await suggest(input);
      expect(first, second);
    });

    test('anti-gaming: repeated keyword counts once', () async {
      final s = await suggest('drill drill drill drill');
      expect(s.suggestedCategory, Category.toolsRepair);
      expect(s.confidence, SuggestionConfidence.low);
    });
  });
}

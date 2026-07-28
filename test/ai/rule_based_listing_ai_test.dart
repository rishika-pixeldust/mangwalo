import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/features/ai/local_ai_service.dart';
import 'package:mangwalo/src/features/ai/rule_based_listing_ai.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';

void main() {
  const engine = RuleBasedListingAi();

  Future<ListingSuggestion> suggest(String text, {ListingType? type}) =>
      engine.suggest(AiSuggestionInput(description: text, listingType: type));

  group('RuleBasedListingAi (luxe)', () {
    test('Hinglish designer-bag description → bag suggestions', () async {
      final s = await suggest(
          'chanel ka flap bag hai, barely used, with dust bag');
      expect(s.suggestedCategory, Category.designerBags);
      expect(s.suggestedTitle, contains('Chanel'));
      expect(s.conditionTags,
          containsAll([ConditionTag.likeNew, ConditionTag.gentlyUsed]));
      expect(s.suggestedLoanDuration?.days, 7);
    });

    test('premium brand doubles the suggested rate', () async {
      final premium = await suggest('chanel flap bag, barely used');
      final plain = await suggest('leather sling bag, barely used');
      expect(premium.suggestedCategory, Category.designerBags);
      expect(plain.suggestedCategory, Category.designerBags);
      expect(premium.suggestedPricePerDayInr, 5000); // 2500 base × 2
      expect(plain.suggestedPricePerDayInr, 2500);
    });

    test('bridal lehenga → event wear with occasion window', () async {
      final s = await suggest(
          'sabyasachi bridal lehenga, worn once and dry cleaned');
      expect(s.suggestedCategory, Category.eventWear);
      expect(s.suggestedTitle, contains('Sabyasachi'));
      expect(s.conditionTags, contains(ConditionTag.gentlyUsed));
      expect(s.suggestedLoanDuration?.days, 3);
      expect(s.suggestedPricePerDayInr, 6000); // premium designer, 3000 × 2
    });

    test('request phrasing gets the Need prefix', () async {
      final s = await suggest('need a cocktail dress for new years party',
          type: ListingType.request);
      expect(s.suggestedCategory, Category.partyWear);
      expect(s.suggestedTitle, startsWith('Need:'));
    });

    test('cricket kit → sports kits with working tag', () async {
      final s = await suggest(
          'sg cricket kit with batting pads and helmet, works fine');
      expect(s.suggestedCategory, Category.sportsKits);
      expect(s.suggestedTitle, contains('Cricket Kit'));
      expect(s.conditionTags, contains(ConditionTag.working));
      expect(s.suggestedPricePerDayInr, 800);
    });

    test('kundan set → jewellery with box tag', () async {
      final s =
          await suggest('kundan necklace set with maang tikka, with box');
      expect(s.suggestedCategory, Category.jewellery);
      expect(s.conditionTags, contains(ConditionTag.likeNew));
      expect(s.suggestedLoanDuration?.days, 2);
    });

    test('collision: clutch bag stays accessories, not designer bags',
        () async {
      final s = await suggest('velvet clutch bag for the reception');
      expect(s.suggestedCategory, Category.accessories);
    });

    test('watch with premium brand doubles the watch base rate', () async {
      final s = await suggest('omega automatic watch, recently serviced');
      expect(s.suggestedCategory, Category.watches);
      expect(s.suggestedTitle, contains('Omega'));
      expect(s.suggestedPricePerDayInr, 3000); // 1500 × 2
    });

    test('LBD acronym casing survives title-casing', () async {
      final s = await suggest('classic lbd, worn twice, size small');
      expect(s.suggestedCategory, Category.partyWear);
      expect(s.suggestedTitle, contains('LBD'));
    });

    test('empty input returns empty suggestion, never throws', () async {
      final s = await suggest('');
      expect(s.isEmpty, isTrue);
      expect(s.confidence, SuggestionConfidence.none);
    });

    test('garbage input falls back without a category or price', () async {
      final s = await suggest('zzz qwerty asdf');
      expect(s.suggestedCategory, isNull);
      expect(s.suggestedPricePerDayInr, isNull);
      expect(s.suggestedTitle, isNotNull); // fallback title from tokens
    });

    test('deterministic: same input twice → identical output', () async {
      const text = 'gucci tote bag, gently used, with dust bag';
      final a = await suggest(text);
      final b = await suggest(text);
      expect(a, equals(b));
    });

    test('anti-gaming: repeated keyword counts once', () async {
      final s = await suggest('watch watch watch watch');
      expect(s.suggestedCategory, Category.watches);
      expect(s.confidence, SuggestionConfidence.low); // one entry, 1 point
    });

    group('sub-category suggestions', () {
      test('picks the sub-category within the winning category', () async {
        final s = await engine.suggest(const AiSuggestionInput(
            description: 'kundan necklace set with chandbali earrings'));
        expect(s.suggestedCategory, Category.jewellery);
        expect(s.suggestedSubCategory, 'Kundan');
      });

      test('Hinglish sub-category terms resolve', () async {
        final s = await engine.suggest(const AiSuggestionInput(
            description: 'sabyasachi lehenga, worn once, dry cleaned'));
        expect(s.suggestedCategory, Category.eventWear);
        expect(s.suggestedSubCategory, 'Lehenga');
      });

      test('same word means different things per category', () async {
        // "clutch" is an accessories sub-category here (see kSubCategories)
        // and must never leak into jewellery.
        final clutch = await engine.suggest(const AiSuggestionInput(
            description: 'satin clutch for a wedding reception'));
        expect(clutch.suggestedCategory, Category.accessories);
        expect(clutch.suggestedSubCategory, 'Clutch');

        final jewels = await engine.suggest(const AiSuggestionInput(
            description: 'polki jhumka pair, handled with care'));
        expect(jewels.suggestedCategory, Category.jewellery);
        expect(jewels.suggestedSubCategory, anyOf('Polki', 'Jhumkas'));
      });

      test('suggested sub-category is always valid for its category',
          () async {
        for (final text in [
          'chanel classic flap bag',
          'sg cricket bat and pads',
          'omega seamaster automatic watch',
          'ivory pashmina shawl',
          'emerald sequin gown for a gala',
        ]) {
          final s = await engine.suggest(AiSuggestionInput(description: text));
          if (s.suggestedSubCategory != null) {
            expect(s.suggestedCategory!.subCategories,
                contains(s.suggestedSubCategory),
                reason: 'invented sub-category for: $text');
          }
        }
      });

      test('no sub-category match yields null, not a guess', () async {
        final s = await engine.suggest(const AiSuggestionInput(
            description: 'some completely unremarkable object here'));
        expect(s.suggestedSubCategory, isNull);
      });

      test('sub-category suggestion is deterministic', () async {
        const input = AiSuggestionInput(
            description: 'louis vuitton neverfull tote, barely used');
        final a = await engine.suggest(input);
        final b = await engine.suggest(input);
        expect(a.suggestedSubCategory, b.suggestedSubCategory);
        expect(a, b);
      });
    });
  });
}

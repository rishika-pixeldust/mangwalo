import '../listings/domain/listing.dart';
import 'local_ai_service.dart';

/// Const data tables for the rule engine. Everything here is deterministic:
/// ordered lists, declaration-order iteration, no runtime construction.
///
/// Multi-word entries are matched as phrases against bigrams/trigrams and
/// score 3 points; single words score 1. Tuned for the luxury-rental domain
/// — designer bags, occasion wear, sports kits — Hinglish included.
abstract final class KeywordRules {
  static const categoryKeywords = <Category, List<String>>{
    Category.designerBags: [
      'handbag', 'hand bag', 'bag', 'purse', 'tote', 'tote bag', 'sling',
      'sling bag', 'shoulder bag', 'satchel', 'hobo bag', 'baguette bag',
      'crossbody', 'cross body', 'mini bag', 'flap bag', 'saddle bag',
      'bucket bag', 'chain bag', 'quilted bag', 'evening bag',
      'designer bag', 'vanity case', 'birkin', 'kelly bag', 'duffle',
    ],
    Category.eventWear: [
      'lehenga', 'lehnga', 'bridal lehenga', 'saree', 'sari', 'silk saree',
      'kanjeevaram', 'kanjivaram', 'banarasi', 'sherwani', 'bandhgala',
      'jodhpuri', 'achkan', 'gown', 'evening gown', 'ball gown',
      'reception gown', 'anarkali', 'wedding dress', 'engagement dress',
      'sangeet outfit', 'mehendi outfit', 'tuxedo', 'tux',
      'three piece suit', 'suit set', 'indo western', 'kurta set',
    ],
    Category.partyWear: [
      'party dress', 'cocktail dress', 'little black dress', 'lbd',
      'sequin dress', 'shimmer dress', 'bodycon', 'jumpsuit', 'party gown',
      'mini dress', 'midi dress', 'slip dress', 'party wear', 'club wear',
      'theme party', 'costume', 'party shirt', 'velvet blazer', 'blazer',
      'satin shirt', 'co ord set', 'coord set',
    ],
    Category.sportsKits: [
      'cricket kit', 'cricket bat', 'cricket', 'batting pads',
      'keeping gloves', 'helmet', 'golf set', 'golf clubs', 'golf',
      'tennis racket', 'badminton kit', 'badminton racket', 'badminton',
      'racket', 'racquet', 'football kit', 'football studs', 'studs',
      'jersey', 'ski suit', 'ski gear', 'skis', 'snowboard',
      'trekking gear', 'trek kit', 'camping kit', 'cycling helmet', 'cycle',
      'yoga kit', 'gym kit', 'skates', 'skateboard', 'swimming kit',
      'scuba', 'bowling kit',
    ],
    Category.jewellery: [
      'necklace', 'necklace set', 'jhumka', 'jhumkas', 'earrings',
      'chandbali', 'maang tikka', 'maang teeka', 'mangtika', 'kada',
      'bangle', 'bangles', 'choker', 'polki', 'polki set', 'kundan',
      'kundan set', 'diamond set', 'temple jewellery', 'jewellery set',
      'jewelry set', 'haar', 'rani haar', 'nath', 'nose ring', 'payal',
      'anklet', 'bracelet', 'pendant', 'cocktail ring',
    ],
    Category.watches: [
      'watch', 'watches', 'wrist watch', 'wristwatch', 'chronograph',
      'luxury watch', 'automatic watch', 'dive watch', 'dress watch',
      'pocket watch', 'gold watch', 'rose gold watch', 'skeleton watch',
      'swiss watch', 'smartwatch', 'smart watch',
    ],
    Category.accessories: [
      'clutch', 'clutch bag', 'potli', 'potli bag', 'stole', 'shawl',
      'pashmina', 'scarf', 'belt', 'designer belt', 'sunglasses', 'shades',
      'tie', 'silk tie', 'bow tie', 'bowtie', 'pocket square', 'cufflinks',
      'cuff links', 'brooch', 'tiara', 'evening gloves', 'juti', 'jutti',
      'mojari', 'safa', 'pagdi', 'turban', 'kamarbandh', 'waist belt',
      'hair accessories',
    ],
  };

  /// Canonical casing for recognized brands (lowercased key as it appears
  /// in normalized text).
  static const brandCasing = <String, String>{
    'gucci': 'Gucci', 'louis vuitton': 'Louis Vuitton', 'lv': 'LV',
    'chanel': 'Chanel', 'dior': 'Dior', 'prada': 'Prada',
    'hermes': 'Hermès', 'coach': 'Coach', 'michael kors': 'Michael Kors',
    'kate spade': 'Kate Spade', 'fendi': 'Fendi', 'burberry': 'Burberry',
    'ysl': 'YSL', 'saint laurent': 'Saint Laurent',
    'bottega': 'Bottega Veneta', 'sabyasachi': 'Sabyasachi',
    'manish malhotra': 'Manish Malhotra', 'anita dongre': 'Anita Dongre',
    'tarun tahiliani': 'Tarun Tahiliani', 'ritu kumar': 'Ritu Kumar',
    'rolex': 'Rolex', 'omega': 'Omega', 'tag heuer': 'TAG Heuer',
    'tissot': 'Tissot', 'rado': 'Rado', 'seiko': 'Seiko', 'casio': 'Casio',
    'titan': 'Titan', 'fossil': 'Fossil',
    'daniel wellington': 'Daniel Wellington', 'cartier': 'Cartier',
    'tanishq': 'Tanishq', 'amrapali': 'Amrapali', 'swarovski': 'Swarovski',
    'yonex': 'Yonex', 'li ning': 'Li-Ning', 'sg': 'SG', 'ss': 'SS',
    'mrf': 'MRF', 'kookaburra': 'Kookaburra', 'gray nicolls': 'Gray-Nicolls',
    'callaway': 'Callaway', 'taylormade': 'TaylorMade', 'wilson': 'Wilson',
    'babolat': 'Babolat', 'decathlon': 'Decathlon', 'nike': 'Nike',
    'adidas': 'Adidas', 'puma': 'Puma',
  };

  /// Brands that double the suggested rate — the premium tier.
  static const premiumBrands = <String>{
    'louis vuitton', 'lv', 'chanel', 'dior', 'hermes', 'gucci', 'prada',
    'bottega', 'fendi', 'burberry', 'ysl', 'saint laurent', 'cartier',
    'rolex', 'omega', 'tag heuer', 'sabyasachi', 'manish malhotra',
    'tarun tahiliani',
  };

  /// Words that keep their special casing inside titles.
  static const acronymCasing = <String, String>{
    'lv': 'LV', 'ysl': 'YSL', 'lbd': 'LBD', 'sg': 'SG', 'ss': 'SS',
    'mrf': 'MRF', 'tt': 'TT',
  };

  /// Phrase → condition tag. Longest-phrase entries listed first for
  /// readability; matching itself is per-entry and order-independent.
  static const conditionPhrases = <String, ConditionTag>{
    'brand new': ConditionTag.likeNew,
    'bilkul naya': ConditionTag.likeNew,
    'ekdum naya': ConditionTag.likeNew,
    'naya hai': ConditionTag.likeNew,
    'unused': ConditionTag.likeNew,
    'never used': ConditionTag.likeNew,
    'never worn': ConditionTag.likeNew,
    'seal pack': ConditionTag.likeNew,
    'box packed': ConditionTag.likeNew,
    'almost new': ConditionTag.likeNew,
    'with box': ConditionTag.likeNew,
    'with dust bag': ConditionTag.likeNew,
    'with authenticity card': ConditionTag.likeNew,
    'dry cleaned': ConditionTag.likeNew,
    'barely used': ConditionTag.gentlyUsed,
    'hardly used': ConditionTag.gentlyUsed,
    'lightly used': ConditionTag.gentlyUsed,
    'sparingly used': ConditionTag.gentlyUsed,
    'gently used': ConditionTag.gentlyUsed,
    'gently loved': ConditionTag.gentlyUsed,
    'good condition': ConditionTag.gentlyUsed,
    'achhi condition': ConditionTag.gentlyUsed,
    'well maintained': ConditionTag.gentlyUsed,
    'used once': ConditionTag.gentlyUsed,
    'used twice': ConditionTag.gentlyUsed,
    'worn once': ConditionTag.gentlyUsed,
    'worn twice': ConditionTag.gentlyUsed,
    'old': ConditionTag.wellWorn,
    'purana': ConditionTag.wellWorn,
    'thoda purana': ConditionTag.wellWorn,
    'worn out': ConditionTag.wellWorn,
    'well used': ConditionTag.wellWorn,
    'scratches': ConditionTag.wellWorn,
    'dents': ConditionTag.wellWorn,
    'many years old': ConditionTag.wellWorn,
    'works fine': ConditionTag.working,
    'working condition': ConditionTag.working,
    'fully functional': ConditionTag.working,
    'no issues': ConditionTag.working,
    'chalta hai': ConditionTag.working,
    'chalu condition': ConditionTag.working,
    'running condition': ConditionTag.working,
    'works well': ConditionTag.working,
    'in working order': ConditionTag.working,
  };

  /// Suggested rental window per category — prefills the return-date picker.
  static const loanDurations = <Category, LoanDuration>{
    Category.designerBags: LoanDuration(days: 7, label: '1 week'),
    Category.eventWear:
        LoanDuration(days: 3, label: '3 days — covers the occasion'),
    Category.partyWear:
        LoanDuration(days: 2, label: '2 days — party and back'),
    Category.sportsKits:
        LoanDuration(days: 14, label: '2 weeks — a season taste'),
    Category.jewellery:
        LoanDuration(days: 2, label: '2 days — the event and a buffer'),
    Category.watches: LoanDuration(days: 3, label: '3 days'),
    Category.accessories: LoanDuration(days: 3, label: '3 days'),
  };

  static const defaultLoanDuration = LoanDuration(days: 3, label: '3 days');

  /// Base rate suggestion per category in whole ₹/day. A recognized premium
  /// brand doubles it. Deterministic — no market lookup.
  static const basePricePerDayInr = <Category, int>{
    Category.designerBags: 2500,
    Category.eventWear: 3000,
    Category.partyWear: 1500,
    Category.sportsKits: 800,
    Category.jewellery: 2000,
    Category.watches: 1500,
    Category.accessories: 600,
  };

  /// Keywords that pin a listing to a SUB-category, keyed by the exact label
  /// used in [kSubCategories] so a match can be applied to the form directly.
  ///
  /// Only consulted once a category has won, so the same word can safely mean
  /// different things in different categories ("clutch" is a bag sub-category
  /// and never a jewellery one).
  static const subCategoryKeywords =
      <Category, Map<String, List<String>>>{
    Category.designerBags: {
      'Tote': ['tote', 'neverfull', 'shopper', 'work bag'],
      'Shoulder bag': ['shoulder bag', 'flap bag', 'classic flap', 'hobo',
          'baguette', 'marmont'],
      'Clutch': ['clutch', 'minaudiere', 'envelope bag'],
      'Potli': ['potli', 'batua', 'drawstring bag'],
      'Sling': ['sling', 'crossbody', 'cross body', 'belt bag'],
      'Backpack': ['backpack', 'rucksack', 'bagpack'],
      'Duffle': ['duffle', 'duffel', 'weekender', 'keepall'],
    },
    Category.eventWear: {
      'Lehenga': ['lehenga', 'lehnga', 'ghagra', 'chaniya choli'],
      'Saree': ['saree', 'sari', 'kanjeevaram', 'kanjivaram', 'banarasi'],
      'Sherwani': ['sherwani', 'achkan'],
      'Bandhgala': ['bandhgala', 'jodhpuri', 'bandh gala'],
      'Gown': ['gown', 'ball gown', 'evening gown', 'trail gown'],
      'Anarkali': ['anarkali', 'salwar', 'sharara', 'gharara'],
      'Suit': ['tuxedo', 'tux', 'three piece', 'dinner suit'],
    },
    Category.partyWear: {
      'Cocktail dress': ['cocktail dress', 'cocktail', 'bodycon'],
      'Shimmer dress': ['shimmer', 'sequin', 'sequinned', 'glitter dress',
          'metallic dress'],
      'Jumpsuit': ['jumpsuit', 'playsuit', 'romper'],
      'Blazer': ['blazer', 'dinner jacket'],
      'Co-ord set': ['co ord', 'coord set', 'crop set', 'two piece'],
    },
    Category.sportsKits: {
      'Cricket': ['cricket', 'bat', 'pads', 'wicket', 'kashmir willow',
          'batting gloves'],
      'Golf': ['golf', 'clubs', 'driver', 'putter', 'half set', 'caddy'],
      'Tennis': ['tennis', 'racquet', 'racket'],
      'Badminton': ['badminton', 'shuttle', 'shuttlecock'],
      'Football': ['football', 'soccer', 'studs', 'shin guards'],
      'Cycling': ['cycle', 'cycling', 'bicycle', 'helmet and cycle'],
      'Skating': ['skates', 'skating', 'rollerblades', 'skateboard'],
    },
    Category.jewellery: {
      'Kundan': ['kundan'],
      'Polki': ['polki'],
      'Temple': ['temple jewellery', 'temple set', 'nakshi'],
      'Diamond': ['diamond', 'solitaire', 'american diamond', 'cz'],
      'Pearl': ['pearl', 'moti'],
      'Jhumkas': ['jhumka', 'jhumkas', 'chandbali', 'chand bali'],
      'Maang tikka': ['maang tikka', 'matha patti', 'tikka', 'nath'],
    },
    Category.watches: {
      'Automatic': ['automatic', 'self winding', 'seamaster', 'submariner'],
      'Chronograph': ['chronograph', 'chrono', 'speedmaster'],
      'Dress watch': ['dress watch', 'leather strap watch', 'slim watch'],
      'Smart watch': ['smart watch', 'smartwatch', 'apple watch', 'fitbit'],
    },
    Category.accessories: {
      'Clutch': ['clutch', 'minaudiere', 'envelope bag'],
      'Potli': ['potli', 'batua', 'drawstring bag'],
      'Stole': ['stole', 'dupatta', 'scarf'],
      'Pashmina': ['pashmina', 'cashmere', 'shawl'],
      'Heels': ['heels', 'stiletto', 'pumps', 'juttis', 'kolhapuri'],
      'Sunglasses': ['sunglasses', 'shades', 'goggles'],
      'Belt': ['belt', 'kamarbandh', 'waist chain'],
      'Turban': ['turban', 'safa', 'pagdi', 'saafa'],
      'Brooch': ['brooch', 'kalgi', 'lapel pin'],
    },
  };

  static const stopwords = <String>{
    'the', 'a', 'an', 'hai', 'ka', 'ki', 'ke', 'for', 'my', 'hi', 'hello',
    'i', 'need', 'want', 'have', 'and', 'or', 'to', 'of', 'in', 'on',
  };
}

import '../listings/domain/listing.dart';
import 'local_ai_service.dart';

/// Const data tables for the rule engine. Everything here is deterministic:
/// ordered lists, declaration-order iteration, no runtime construction.
///
/// Multi-word entries are matched as phrases against bigrams/trigrams and
/// score 3 points; single words score 1. Tuned for the Mumbai borrow-lend
/// domain, Hinglish included.
abstract final class KeywordRules {
  static const categoryKeywords = <Category, List<String>>{
    Category.toolsRepair: [
      'drill', 'drill machine', 'hammer', 'hathoda', 'screwdriver',
      'screw driver', 'pechkas', 'spanner', 'wrench', 'pliers', 'toolkit',
      'tool kit', 'tool box', 'ladder', 'sidi', 'step ladder', 'saw',
      'hacksaw', 'allen key', 'glue gun', 'soldering iron', 'multimeter',
      'measuring tape', 'inch tape', 'paint roller', 'tile cutter',
      'car jack', 'air pump',
    ],
    Category.kitchenAppliances: [
      'mixer', 'mixie', 'mixer grinder', 'grinder', 'blender', 'hand blender',
      'kadhai', 'kadai', 'wok', 'cooker', 'pressure cooker', 'tawa', 'tava',
      'idli stand', 'idli maker', 'dosa tawa', 'otg', 'oven', 'microwave',
      'air fryer', 'airfryer', 'toaster', 'sandwich maker', 'juicer',
      'chopper', 'kettle', 'casserole', 'patila', 'chakla belan', 'appe pan',
      'gas stove', 'induction',
    ],
    Category.booksStudy: [
      'book', 'books', 'novel', 'novels', 'textbook', 'text book', 'kitab',
      'comics', 'magazine', 'magazines', 'encyclopedia', 'dictionary',
      'atlas', 'study material', 'ncert', 'jee', 'neet', 'upsc',
      'sample papers', 'question bank', 'storybook', 'story book',
      'biography', 'manga',
    ],
    Category.sportsFitness: [
      'cycle', 'bicycle', 'badminton', 'racket', 'racquet', 'shuttlecock',
      'tt', 'table tennis', 'tt bat', 'cricket', 'cricket bat', 'bat',
      'stumps', 'wickets', 'football', 'basketball', 'volleyball', 'carrom',
      'chess', 'skates', 'skateboard', 'yoga mat', 'dumbbell', 'dumbbells',
      'kettlebell', 'treadmill', 'exercise cycle', 'frisbee',
      'swimming goggles',
    ],
    Category.outdoorsTravel: [
      'tent', 'sleeping bag', 'trekking pole', 'trekking', 'camping',
      'camp stove', 'icebox', 'ice box', 'esky', 'cooler box', 'suitcase',
      'trolley bag', 'strolley', 'duffel', 'backpack', 'rucksack',
      'haversack', 'travel adapter', 'neck pillow', 'luggage', 'binoculars',
      'headlamp', 'hammock', 'picnic mat', 'raincoat',
    ],
    Category.electronics: [
      'projector', 'tripod', 'camera', 'dslr', 'gopro', 'action camera',
      'speaker', 'bluetooth speaker', 'soundbar', 'mic', 'microphone',
      'extension board', 'extension cord', 'power bank', 'powerbank',
      'router', 'monitor', 'keyboard', 'mouse', 'laptop', 'tablet', 'ipad',
      'kindle', 'headphones', 'earphones', 'drone', 'printer', 'hard disk',
      'pen drive', 'hdmi cable', 'charger', 'webcam', 'gimbal',
    ],
    Category.musicInstruments: [
      'guitar', 'ukulele', 'casio', 'casio keyboard', 'music keyboard',
      'keyboard piano', 'synthesizer', 'synth', 'piano', 'harmonium',
      'tabla', 'dholak', 'dhol', 'flute', 'bansuri', 'violin', 'drums',
      'drum kit', 'bongo', 'cajon', 'mouth organ', 'harmonica',
      'karaoke machine', 'amplifier', 'capo', 'guitar strings', 'sitar',
      'shruti box',
    ],
    Category.kidsToys: [
      'pram', 'stroller', 'walker', 'baby walker', 'cradle', 'jhula',
      'palna', 'car seat', 'baby carrier', 'high chair', 'highchair',
      'toys', 'lego', 'tricycle', 'kids cycle', 'training wheels',
      'bouncer', 'dollhouse', 'doll house', 'board game', 'board games',
      'remote control car', 'rc car', 'soft toys', 'puzzle', 'playpen',
      'play mat', 'ludo', 'carrom board',
    ],
    Category.festivalDecor: [
      'diwali lights', 'fairy lights', 'string lights', 'led strip',
      'rangoli', 'rangoli stencil', 'diya', 'diyas', 'diya stand', 'ganpati',
      'ganpati decoration', 'makhar', 'toran', 'garland', 'kandil',
      'akash kandil', 'lantern', 'lanterns', 'christmas tree', 'xmas tree',
      'santa costume', 'birthday banner', 'balloon pump', 'balloons',
      'party lights', 'disco light', 'dandiya', 'dandiya sticks', 'garba',
      'aarti thali', 'mandap',
    ],
    Category.homeFurniture: [
      'folding table', 'folding chair', 'chair', 'chairs', 'table',
      'mattress', 'gadda', 'cot', 'iron', 'istri', 'steam iron',
      'sewing machine', 'silai machine', 'silai', 'vacuum', 'vacuum cleaner',
      'fan', 'pedestal fan', 'table fan', 'air cooler', 'heater',
      'room heater', 'blower', 'bucket', 'stool', 'chatai', 'razai',
      'blanket', 'quilt', 'inverter', 'shoe rack', 'drying stand',
    ],
    // Category.other has no keywords — it is the null result, never scored.
  };

  /// Canonical casing for brands commonly lent around Mumbai households.
  static const brandCasing = <String, String>{
    'bosch': 'Bosch', 'stanley': 'Stanley', 'prestige': 'Prestige',
    'hawkins': 'Hawkins', 'philips': 'Philips', 'bajaj': 'Bajaj',
    'butterfly': 'Butterfly', 'preethi': 'Preethi', 'sujata': 'Sujata',
    'usha': 'Usha', 'singer': 'Singer', 'godrej': 'Godrej', 'kent': 'Kent',
    'havells': 'Havells', 'ifb': 'IFB', 'lg': 'LG', 'samsung': 'Samsung',
    'sony': 'Sony', 'jbl': 'JBL', 'boat': 'boAt', 'canon': 'Canon',
    'nikon': 'Nikon', 'gopro': 'GoPro', 'dji': 'DJI', 'casio': 'Casio',
    'yamaha': 'Yamaha', 'fender': 'Fender', 'yonex': 'Yonex', 'sg': 'SG',
    'mrf': 'MRF', 'cosco': 'Cosco', 'nivia': 'Nivia', 'hero': 'Hero',
    'atlas': 'Atlas', 'bsa': 'BSA', 'firefox': 'Firefox', 'btwin': 'Btwin',
    'decathlon': 'Decathlon', 'quechua': 'Quechua', 'wildcraft': 'Wildcraft',
    'vip': 'VIP', 'safari': 'Safari', 'skybags': 'Skybags',
    'milton': 'Milton', 'borosil': 'Borosil', 'pigeon': 'Pigeon',
  };

  /// Acronyms that must keep their casing inside generated titles.
  static const acronymCasing = <String, String>{
    'tt': 'TT', 'ncert': 'NCERT', 'dslr': 'DSLR', 'otg': 'OTG', 'led': 'LED',
    'rc': 'RC', 'jee': 'JEE', 'neet': 'NEET', 'upsc': 'UPSC', 'hdmi': 'HDMI',
  };

  /// Longest-phrase-first condition extraction; multiple tags may apply
  /// ("purana hai par chalta hai" → well-worn AND working).
  static const conditionPhrases = <String, ConditionTag>{
    'brand new': ConditionTag.likeNew,
    'bilkul naya': ConditionTag.likeNew,
    'ekdum naya': ConditionTag.likeNew,
    'naya hai': ConditionTag.likeNew,
    'unused': ConditionTag.likeNew,
    'never used': ConditionTag.likeNew,
    'seal pack': ConditionTag.likeNew,
    'box packed': ConditionTag.likeNew,
    'almost new': ConditionTag.likeNew,
    'like new': ConditionTag.likeNew,
    'barely used': ConditionTag.gentlyUsed,
    'hardly used': ConditionTag.gentlyUsed,
    'lightly used': ConditionTag.gentlyUsed,
    'sparingly used': ConditionTag.gentlyUsed,
    'gently used': ConditionTag.gentlyUsed,
    'good condition': ConditionTag.gentlyUsed,
    'achhi condition': ConditionTag.gentlyUsed,
    'well maintained': ConditionTag.gentlyUsed,
    'used once': ConditionTag.gentlyUsed,
    'used twice': ConditionTag.gentlyUsed,
    'thoda purana': ConditionTag.wellWorn,
    'worn out': ConditionTag.wellWorn,
    'well used': ConditionTag.wellWorn,
    'scratches': ConditionTag.wellWorn,
    'dents': ConditionTag.wellWorn,
    'many years old': ConditionTag.wellWorn,
    'purana': ConditionTag.wellWorn,
    'old': ConditionTag.wellWorn,
    'works fine': ConditionTag.working,
    'working condition': ConditionTag.working,
    'fully functional': ConditionTag.working,
    'no issues': ConditionTag.working,
    'chalta hai': ConditionTag.working,
    'chalu condition': ConditionTag.working,
    'running condition': ConditionTag.working,
    'works well': ConditionTag.working,
    'in working order': ConditionTag.working,
    'works': ConditionTag.working,
  };

  /// Suggested lending window per category. Fixed labels — the engine never
  /// reads the clock; the lending feature applies `today + days` later.
  static const loanDurations = <Category, LoanDuration>{
    Category.toolsRepair:
        LoanDuration(days: 3, label: '3 days — most repairs are quick'),
    Category.kitchenAppliances: LoanDuration(days: 7, label: '1 week'),
    Category.booksStudy: LoanDuration(days: 14, label: '2 weeks'),
    Category.sportsFitness: LoanDuration(days: 7, label: '1 week'),
    Category.outdoorsTravel:
        LoanDuration(days: 10, label: '10 days — covers a trip'),
    Category.electronics: LoanDuration(days: 3, label: '3 days'),
    Category.musicInstruments: LoanDuration(days: 14, label: '2 weeks'),
    Category.kidsToys: LoanDuration(days: 14, label: '2 weeks'),
    Category.festivalDecor: LoanDuration(
        days: 7, label: 'About a week — return after the festival'),
    Category.homeFurniture: LoanDuration(days: 30, label: '1 month'),
  };

  static const defaultLoanDuration = LoanDuration(days: 7, label: '1 week');

  /// Stopwords skipped by the fallback title generator.
  static const stopwords = <String>{
    'the', 'a', 'an', 'hai', 'ka', 'ki', 'ke', 'for', 'my', 'hi', 'hello',
    'i', 'need', 'want', 'have', 'and', 'or', 'to', 'of', 'in', 'on',
  };
}

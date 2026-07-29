import '../domain/listing.dart';

/// Clearly-fake sample listings, seeded so the board is never empty. Reviewer
/// names are first names only, imagery is generated illustrative art (category
/// glyph + serif monogram, 3–4 "angles" per item — no real products), and every
/// row is flagged [Listing.isDemo] so it carries a "Sample" badge and can be
/// hidden in one tap.
///
/// Between them the rows cover every state the UI can render: both listing
/// types, all three lending states, an overdue rental and a due-soon one,
/// reviewed and unreviewed items, and the full price/deposit range. See
/// docs/sample-data.md.
///
/// Due dates are relative to [now] so the overdue and due-soon badges always
/// demonstrate correctly: one rental overdue by 5 days, one due in 2 days.
///
/// [photoLoader] resolves a bundled asset path to a base64 JPEG (null =
/// skip images — used by pure-VM tests).
Future<List<Listing>> buildSampleListings({
  required String neighborhood,
  required DateTime now,
  Future<String?> Function(String assetPath)? photoLoader,
}) async {
  final today = DateTime(now.year, now.month, now.day);
  // Deterministic ids make seeding naturally idempotent: re-seeding
  // overwrites the same rows instead of duplicating them.
  var sampleIndex = 0;

  Future<List<String>> photos(List<String> names) async {
    if (photoLoader == null) return const [];
    final out = <String>[];
    for (final name in names) {
      final b64 = await photoLoader('assets/seed/$name.jpg');
      if (b64 != null) out.add(b64);
    }
    return out;
  }

  Review review(int rating, String text, String name, int daysAgo) => Review(
        rating: rating,
        text: text,
        reviewerName: name,
        createdAt: today.subtract(Duration(days: daysAgo)),
      );

  Future<Listing> sample({
    required ListingType type,
    required String title,
    required String description,
    required Category category,
    String subCategory = '',
    List<String> conditionTags = const [],
    required String area,
    ContactChannel contactChannel = ContactChannel.societyBoard,
    required int pricePerDayInr,
    int? depositInr,
    InteractionStatus status = InteractionStatus.saved,
    LendingState lendingState = LendingState.available,
    DateTime? dueDate,
    DateTime? returnedAt,
    String borrowerName = '',
    List<String> photoAssets = const [],
    List<Review> reviews = const [],
    required int ageDays,
  }) async {
    final created = today.subtract(Duration(days: ageDays));
    sampleIndex++;
    return Listing(
      id: 'sample-$sampleIndex',
      type: type,
      title: title,
      description: description,
      category: category,
      subCategory: subCategory,
      conditionTags: conditionTags,
      area: area,
      neighborhood: neighborhood,
      contactChannel: contactChannel,
      pricePerDayInr: pricePerDayInr,
      depositInr: depositInr,
      status: status,
      lendingState: lendingState,
      dueDate: dueDate,
      returnedAt: returnedAt,
      borrowerName: borrowerName,
      photos: await photos(photoAssets),
      reviews: reviews,
      createdAt: created,
      updatedAt: created,
      isDemo: true,
    );
  }

  return [
    await sample(
      type: ListingType.offer,
      title: 'Chanel Classic Flap bag',
      description: 'Timeless black caviar leather, gold hardware. Comes '
          'with dust bag and authenticity card. Perfect for weddings '
          'and big evenings.',
      category: Category.designerBags,
      subCategory: 'Shoulder bag',
      conditionTags: const ['Like new'],
      area: 'Near Carter Road promenade',
      pricePerDayInr: 4800,
      depositInr: 25000,
      lendingState: LendingState.lentOut,
      dueDate: today.subtract(const Duration(days: 5)), // overdue demo
      borrowerName: 'Kiara',
      photoAssets: const [
        'bag_chanel',
        'bag_chanel_2',
        'bag_chanel_3',
        'bag_chanel_4'
      ],
      reviews: [
        review(5, 'Bag was pristine — dust bag, card, everything. And the '
            'owner was so gracious about my late evening pickup.', 'Meher', 21),
        review(5, 'Exactly as pictured. Smooth handover both ways.', 'Ira', 40),
        review(4, 'Gorgeous bag; one tiny scuff inside. Owner flagged it '
            'upfront, which I appreciated.', 'Tanya', 62),
      ],
      ageDays: 90,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Sabyasachi bridal lehenga',
      contactChannel: ContactChannel.buildingWhatsApp,
      description: 'Deep red silk with hand embroidery, worn once and dry '
          'cleaned. Blouse alterable. For the sangeet or the big day itself.',
      category: Category.eventWear,
      subCategory: 'Lehenga',
      conditionTags: const ['Gently used'],
      area: 'Opposite Jogger\'s Park',
      pricePerDayInr: 9500,
      depositInr: 30000,
      lendingState: LendingState.lentOut,
      dueDate: today.add(const Duration(days: 2)), // due-soon demo
      borrowerName: 'Meher',
      photoAssets: const ['lehenga', 'lehenga_2', 'lehenga_3', 'lehenga_4'],
      reviews: [
        review(5, 'Fit like a dream after minor pinning. R. was endlessly '
            'patient with my hundred questions.', 'Zoya', 30),
        review(5, 'The photos don\'t do it justice. Returned it wishing I '
            'hadn\'t to.', 'Ananya', 75),
      ],
      ageDays: 120,
    ),
    await sample(
      type: ListingType.offer,
      title: 'LV Neverfull tote',
      description: 'Louis Vuitton Neverfull MM in monogram canvas. Barely '
          'used, with box. Ideal for brunches and travel days.',
      category: Category.designerBags,
      subCategory: 'Tote',
      conditionTags: const ['Gently used'],
      area: 'Near Bandstand amphitheatre',
      pricePerDayInr: 3500,
      depositInr: 15000,
      photoAssets: const ['bag_lv', 'bag_lv_2', 'bag_lv_3'],
      reviews: [
        review(5, 'Carried it for a week of client meetings — flawless. '
            'J. is a delight to rent from.', 'Priya', 12),
        review(4, 'Great condition, easy pickup near Bandstand.', 'Sana', 55),
      ],
      ageDays: 60,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Emerald sequin gown',
      description: 'Floor-length sequin gown, size M, worn twice and dry '
          'cleaned. Turns heads at cocktail nights and award dinners.',
      category: Category.partyWear,
      subCategory: 'Shimmer dress',
      conditionTags: const ['Gently used'],
      area: 'Near Mehboob Studio lane',
      pricePerDayInr: 2200,
      depositInr: 5000,
      status: InteractionStatus.contacted,
      photoAssets: const ['gown', 'gown_2', 'gown_3'],
      reviews: [
        review(5, 'Showstopper. True to size and immaculately kept — and '
            'N. even lent me a matching stole.', 'Ritika', 18),
      ],
      ageDays: 45,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Midnight bandhgala set',
      description: 'Tailored jodhpuri bandhgala with trousers, 40R. Worn '
          'once at a reception. Sharp, classic, comfortable.',
      category: Category.eventWear,
      subCategory: 'Bandhgala',
      conditionTags: const ['Like new'],
      area: 'Behind National College',
      pricePerDayInr: 3800,
      depositInr: 8000,
      photoAssets: const ['sherwani', 'sherwani_2', 'sherwani_3'],
      reviews: [
        review(5, 'Wore it to my engagement — countless compliments. '
            'K. had it pressed and ready.', 'Arjun', 25),
        review(4, 'Excellent fit for a rental. Punctual handover.', 'Dev', 70),
      ],
      ageDays: 100,
    ),
    await sample(
      type: ListingType.offer,
      title: 'SG full cricket kit',
      description: 'SG bat, pads, gloves, helmet and kit bag. Adult size. '
          'Well maintained — great for weekend tournaments.',
      category: Category.sportsKits,
      subCategory: 'Cricket',
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Lucky Restaurant junction',
      pricePerDayInr: 900,
      depositInr: 3000,
      photoAssets: const [
        'cricket_kit',
        'cricket_kit_2',
        'cricket_kit_3',
        'cricket_kit_4'
      ],
      reviews: [
        review(5, 'Kit was complete and clean. M. even threw in spare '
            'grip tape. Returned on time, no fuss.', 'Rohan', 9),
        review(4, 'Solid gear for a society tournament.', 'Vikram', 34),
        review(5, 'Second time renting — reliable as always.', 'Rohan', 80),
      ],
      ageDays: 140,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Kundan bridal set',
      description: 'Kundan necklace set with chandbali earrings and maang '
          'tikka. With box. For weddings and receptions only.',
      category: Category.jewellery,
      subCategory: 'Kundan',
      conditionTags: const ['Like new'],
      area: 'Near St. Andrew\'s school gate',
      pricePerDayInr: 5500,
      depositInr: 40000,
      photoAssets: const [
        'jewellery',
        'jewellery_2',
        'jewellery_3',
        'jewellery_4'
      ],
      reviews: [
        review(5, 'Photographed beautifully at the reception. V. was very '
            'careful and professional about the handover.', 'Ishita', 15),
        review(5, 'Heirloom-level pieces. Handle with love.', 'Nandini', 58),
      ],
      ageDays: 85,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Omega Seamaster',
      description: 'Steel automatic on a leather strap, recently serviced. '
          'For interviews, shoots and evenings that matter.',
      category: Category.watches,
      subCategory: 'Automatic',
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Hill Road market',
      pricePerDayInr: 4000,
      depositInr: 50000,
      lendingState: LendingState.returned, // shows the returned state
      returnedAt: today.subtract(const Duration(days: 1)),
      photoAssets: const ['watch', 'watch_2', 'watch_3'],
      reviews: [
        review(5, 'Kept perfect time all weekend. S. checked it back in '
            'with white gloves — literally.', 'Aditya', 6),
      ],
      ageDays: 110,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Velvet potli & clutch duo',
      description: 'Embroidered velvet potli plus a satin clutch — covers '
          'both the mehendi and the after-party.',
      category: Category.accessories,
      subCategory: 'Potli',
      conditionTags: const ['Gently used'],
      area: 'Near Bandra Talao',
      pricePerDayInr: 700,
      depositInr: 1500,
      photoAssets: const ['clutch', 'clutch_2', 'clutch_3'],
      reviews: [
        review(4, 'Pretty pieces, generous rental window.', 'Simran', 28),
      ],
      ageDays: 50,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Rose shimmer party dress',
      description: 'Knee-length shimmer dress, size S. Worn twice, dry '
          'cleaned, photographs like a dream under party lights.',
      category: Category.partyWear,
      subCategory: 'Shimmer dress',
      conditionTags: const ['Gently used'],
      area: 'Near Pali Naka market',
      pricePerDayInr: 1800,
      depositInr: 4000,
      photoAssets: const ['party_dress', 'party_dress_2', 'party_dress_3'],
      reviews: [
        review(5, 'Wore it to a rooftop birthday — perfect fit, and P. was '
            'sweet about extending pickup by an hour.', 'Ayesha', 11),
        review(4, 'Sparkles exactly as pictured.', 'Mira', 42),
      ],
      ageDays: 55,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Callaway half set with bag',
      contactChannel: ContactChannel.inPerson,
      description: 'Right-handed Callaway half set, stand bag included. '
          'Regripped this season — ready for the fairway.',
      category: Category.sportsKits,
      subCategory: 'Golf',
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Otters Club',
      pricePerDayInr: 1400,
      depositInr: 10000,
      photoAssets: const ['golf_set', 'golf_set_2', 'golf_set_3', 'golf_set_4'],
      reviews: [
        review(5, 'Clubs were immaculate and R. even shared a range tip. '
            'Returned same day, no drama.', 'Kabir', 8),
      ],
      ageDays: 70,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Pashmina stole, ivory',
      description: 'Genuine soft pashmina, dry cleaned and folded with '
          'care. Elevates any evening outfit instantly.',
      category: Category.accessories,
      subCategory: 'Pashmina',
      conditionTags: const ['Like new'],
      area: 'Near Mount Mary steps',
      pricePerDayInr: 500,
      depositInr: 2000,
      photoAssets: const ['pashmina', 'pashmina_2', 'pashmina_3'],
      reviews: [
        review(5, 'Impossibly soft and spotless. Z. wrapped it in tissue for '
            'the handover — a class act.', 'Naina', 22),
      ],
      ageDays: 25,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Polki jhumka duo',
      description: 'Statement polki jhumkas with a matching nath. For '
          'sangeets and receptions — handled with white gloves only.',
      category: Category.jewellery,
      subCategory: 'Jhumkas',
      conditionTags: const ['Like new'],
      area: 'Near St. Andrew\'s school gate',
      pricePerDayInr: 1600,
      depositInr: 12000,
      photoAssets: const ['jhumka', 'jhumka_2', 'jhumka_3'],
      reviews: [
        review(5, 'Photographed beautifully; V. is meticulous and kind.',
            'Ishita', 19),
      ],
      ageDays: 33,
    ),
    await sample(
      type: ListingType.request,
      title: 'Need: golf half set for corporate weekend',
      description: 'Looking for a golf half set (right-handed) for a '
          'company offsite, Friday to Sunday. Will treat it like my own.',
      category: Category.sportsKits,
      subCategory: 'Golf',
      area: 'Near Otters Club',
      pricePerDayInr: 1200,
      ageDays: 2,
    ),
    await sample(
      type: ListingType.request,
      title: 'Need: cocktail dress for New Year\'s Eve',
      description: 'Size S, something shimmery for a rooftop NYE party. '
          'One night plus fittings.',
      category: Category.partyWear,
      subCategory: 'Cocktail dress',
      area: 'Near Hill Road market',
      pricePerDayInr: 1500,
      status: InteractionStatus.closed, // shows the lifecycle end state
      ageDays: 30,
    ),
  ];
}

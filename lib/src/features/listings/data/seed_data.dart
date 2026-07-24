import '../domain/listing.dart';

/// Clearly-fake sample listings, seeded on onboarding so the board is never
/// empty. Names are first names / initials + common surnames, contact notes
/// contain no digits, imagery is generated monogram art (no real products),
/// and every row is flagged [Listing.isDemo] so it carries a "Sample" badge
/// and can be removed in one tap.
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
    List<String> conditionTags = const [],
    required String area,
    ContactChannel contactChannel = ContactChannel.societyBoard,
    String contactNote = '',
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
      conditionTags: conditionTags,
      area: area,
      neighborhood: neighborhood,
      contactChannel: contactChannel,
      contactNote: contactNote,
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
      conditionTags: const ['Like new'],
      area: 'Near Carter Road promenade',
      contactNote: 'A. Sharma — ask via society board',
      pricePerDayInr: 4800,
      depositInr: 25000,
      lendingState: LendingState.lentOut,
      dueDate: today.subtract(const Duration(days: 5)), // overdue demo
      borrowerName: 'Kiara',
      photoAssets: const ['bag_chanel'],
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
      description: 'Deep red silk with hand embroidery, worn once and dry '
          'cleaned. Blouse alterable. For the sangeet or the big day itself.',
      category: Category.eventWear,
      conditionTags: const ['Gently used'],
      area: 'Opposite Jogger\'s Park',
      contactChannel: ContactChannel.buildingWhatsApp,
      contactNote: 'R. Nair — building group',
      pricePerDayInr: 9500,
      depositInr: 30000,
      lendingState: LendingState.lentOut,
      dueDate: today.add(const Duration(days: 2)), // due-soon demo
      borrowerName: 'Meher',
      photoAssets: const ['lehenga'],
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
      conditionTags: const ['Gently used'],
      area: 'Near Bandstand amphitheatre',
      contactNote: 'J. Mehta — society board',
      pricePerDayInr: 3500,
      depositInr: 15000,
      photoAssets: const ['bag_lv'],
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
      conditionTags: const ['Gently used'],
      area: 'Near Mehboob Studio lane',
      contactNote: 'N. Kapoor — flat notice board',
      pricePerDayInr: 2200,
      depositInr: 5000,
      status: InteractionStatus.contacted,
      photoAssets: const ['gown'],
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
      conditionTags: const ['Like new'],
      area: 'Behind National College',
      contactNote: 'K. Iyer — ask via society board',
      pricePerDayInr: 3800,
      depositInr: 8000,
      photoAssets: const ['sherwani'],
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
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Lucky Restaurant junction',
      contactNote: 'M. Kulkarni — society board',
      pricePerDayInr: 900,
      depositInr: 3000,
      photoAssets: const ['cricket_kit'],
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
      conditionTags: const ['Like new'],
      area: 'Near St. Andrew\'s school gate',
      contactNote: 'V. Rao — building intercom',
      pricePerDayInr: 5500,
      depositInr: 40000,
      photoAssets: const ['jewellery'],
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
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Hill Road market',
      contactNote: 'S. Fernandes — secretary\'s office',
      pricePerDayInr: 4000,
      depositInr: 50000,
      lendingState: LendingState.returned, // shows the returned state
      returnedAt: today.subtract(const Duration(days: 1)),
      photoAssets: const ['watch'],
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
      conditionTags: const ['Gently used'],
      area: 'Near Bandra Talao',
      contactNote: 'F. Khan — society board',
      pricePerDayInr: 700,
      depositInr: 1500,
      photoAssets: const ['clutch'],
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
      conditionTags: const ['Gently used'],
      area: 'Near Pali Naka market',
      contactNote: 'P. D\'Souza — flat notice board',
      pricePerDayInr: 1800,
      depositInr: 4000,
      photoAssets: const ['party_dress'],
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
      description: 'Right-handed Callaway half set, stand bag included. '
          'Regripped this season — ready for the fairway.',
      category: Category.sportsKits,
      conditionTags: const ['Gently used', 'Working'],
      area: 'Near Otters Club',
      contactChannel: ContactChannel.inPerson,
      contactNote: 'R. Singhania — clubhouse desk',
      pricePerDayInr: 1400,
      depositInr: 10000,
      photoAssets: const ['golf_set'],
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
      conditionTags: const ['Like new'],
      area: 'Near Mount Mary steps',
      contactNote: 'Z. Merchant — society board',
      pricePerDayInr: 500,
      depositInr: 2000,
      ageDays: 25,
    ),
    await sample(
      type: ListingType.offer,
      title: 'Polki jhumka duo',
      description: 'Statement polki jhumkas with a matching nath. For '
          'sangeets and receptions — handled with white gloves only.',
      category: Category.jewellery,
      conditionTags: const ['Like new'],
      area: 'Near St. Andrew\'s school gate',
      contactNote: 'V. Rao — building intercom',
      pricePerDayInr: 1600,
      depositInr: 12000,
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
      area: 'Near Otters Club',
      contactChannel: ContactChannel.inPerson,
      contactNote: 'D. Batra — clubhouse desk',
      pricePerDayInr: 1200,
      ageDays: 2,
    ),
    await sample(
      type: ListingType.request,
      title: 'Need: cocktail dress for New Year\'s Eve',
      description: 'Size S, something shimmery for a rooftop NYE party. '
          'One night plus fittings.',
      category: Category.partyWear,
      area: 'Near Hill Road market',
      contactNote: 'T. Shah — ask via society board',
      pricePerDayInr: 1500,
      status: InteractionStatus.closed, // shows the lifecycle end state
      ageDays: 30,
    ),
  ];
}

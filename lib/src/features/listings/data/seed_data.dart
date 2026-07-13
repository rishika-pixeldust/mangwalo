import '../domain/listing.dart';

/// Clearly-fake sample listings, loaded only when the user opts in
/// ("Explore with sample listings"). Names are initials + common surnames,
/// contact notes contain no digits, and every row is flagged [Listing.isDemo]
/// so it carries a "Sample" badge and can be removed in one tap.
///
/// Due dates are relative to [now] so the overdue and due-soon badges always
/// demonstrate correctly: one item overdue by 5 days, one due in 2 days.
List<Listing> buildSampleListings({
  required String neighborhood,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  // Deterministic ids make seeding naturally idempotent: re-seeding
  // overwrites the same rows instead of duplicating them.
  var sampleIndex = 0;

  Listing sample({
    required ListingType type,
    required String title,
    required String description,
    required Category category,
    List<String> conditionTags = const [],
    required String area,
    ContactChannel contactChannel = ContactChannel.societyBoard,
    String contactNote = '',
    InteractionStatus status = InteractionStatus.saved,
    LendingState lendingState = LendingState.available,
    DateTime? dueDate,
    DateTime? returnedAt,
    String borrowerName = '',
    required int ageDays,
  }) {
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
      status: status,
      lendingState: lendingState,
      dueDate: dueDate,
      returnedAt: returnedAt,
      borrowerName: borrowerName,
      createdAt: created,
      updatedAt: created,
      isDemo: true,
    );
  }

  return [
    sample(
      type: ListingType.offer,
      title: 'Steel pressure cooker (5L)',
      description: 'Sturdy cooker, gasket replaced recently. '
          'Happy to lend for festival cooking.',
      category: Category.kitchenAppliances,
      conditionTags: const ['Working'],
      area: 'Near Carter Road promenade',
      contactNote: 'A. Sharma — ask via society board',
      lendingState: LendingState.lentOut,
      dueDate: today.subtract(const Duration(days: 5)), // overdue badge demo
      borrowerName: 'Sneha',
      ageDays: 12,
    ),
    sample(
      type: ListingType.offer,
      title: 'Cricket bat, size 6',
      description: 'Kids\' Kashmir-willow bat, lightly taped handle. '
          'Weekend lends preferred.',
      category: Category.sportsFitness,
      conditionTags: const ['Gently used'],
      area: 'Opposite Jogger\'s Park',
      contactChannel: ContactChannel.buildingWhatsApp,
      contactNote: 'R. Nair — building group',
      lendingState: LendingState.lentOut,
      dueDate: today.add(const Duration(days: 2)), // due-soon badge demo
      borrowerName: 'Rahul',
      ageDays: 9,
    ),
    sample(
      type: ListingType.request,
      title: 'Need: aluminium ladder',
      description: 'Need a six-foot ladder for one afternoon to fix a '
          'curtain rod. Will return the same day.',
      category: Category.toolsRepair,
      area: 'Near Mehboob Studio lane',
      contactNote: 'P. D\'Souza — flat notice board',
      ageDays: 3,
    ),
    sample(
      type: ListingType.offer,
      title: 'Board game bundle (Ludo + Carrom)',
      description: 'Carrom board with coins and a ludo set. '
          'Great for society game nights.',
      category: Category.kidsToys,
      conditionTags: const ['Gently used'],
      area: 'Behind National College',
      contactNote: 'K. Iyer — ask via society board',
      ageDays: 6,
    ),
    sample(
      type: ListingType.request,
      title: 'Need: badminton net for society tournament',
      description: 'Our building is running a Sunday tournament and we '
          'need a net for one weekend.',
      category: Category.sportsFitness,
      area: 'Near Bandra Talao',
      contactChannel: ContactChannel.inPerson,
      contactNote: 'S. Fernandes — secretary\'s office',
      status: InteractionStatus.contacted,
      ageDays: 4,
    ),
    sample(
      type: ListingType.offer,
      title: 'Tool kit (screwdrivers + drill bits)',
      description: 'Basic toolkit, no power drill. Borrow for small jobs, '
          'return within a week.',
      category: Category.toolsRepair,
      conditionTags: const ['Working'],
      area: 'Near Lucky Restaurant junction',
      contactNote: 'M. Kulkarni — society board',
      ageDays: 8,
    ),
    sample(
      type: ListingType.offer,
      title: 'Stack of NCERT Class 10 guides',
      description: 'Last year\'s board-exam guides in good condition. '
          'Long lend is fine for students.',
      category: Category.booksStudy,
      conditionTags: const ['Gently used'],
      area: 'Near St. Andrew\'s school gate',
      contactNote: 'V. Rao — building intercom',
      ageDays: 15,
    ),
    sample(
      type: ListingType.request,
      title: 'Need: extra plastic chairs (x6)',
      description: 'Hosting a small pooja at home and need six chairs '
          'for one evening.',
      category: Category.homeFurniture,
      area: 'Near Hill Road market',
      contactNote: 'A. Sharma — ask via society board',
      status: InteractionStatus.closed, // shows the lifecycle end state
      ageDays: 20,
    ),
    sample(
      type: ListingType.offer,
      title: 'Camping tent (2-person)',
      description: 'Pop-up tent, used twice. Lend for up to two weeks.',
      category: Category.outdoorsTravel,
      conditionTags: const ['Like new'],
      area: 'Near Bandstand amphitheatre',
      contactNote: 'J. Mehta — society board',
      lendingState: LendingState.returned, // shows the returned state
      returnedAt: today.subtract(const Duration(days: 1)),
      ageDays: 18,
    ),
  ];
}

import 'package:flutter/foundation.dart';

/// Whether a listing offers an item for rent or asks for one.
enum ListingType { offer, request }

extension ListingTypeLabel on ListingType {
  String get label => switch (this) {
        ListingType.offer => 'For rent',
        ListingType.request => 'Wanted',
      };
}

/// The luxury rental catalog: bags, occasion wear, and sports kits — plus
/// the pieces that complete a look. [Category.other] is the escape hatch so
/// nothing a neighbour owns is unpostable.
enum Category {
  designerBags,
  eventWear,
  partyWear,
  sportsKits,
  jewellery,
  watches,
  accessories,
  other,
}

extension CategoryLabel on Category {
  String get label => switch (this) {
        Category.designerBags => 'Designer bags',
        Category.eventWear => 'Event wear',
        Category.partyWear => 'Party wear',
        Category.sportsKits => 'Sports kits',
        Category.jewellery => 'Jewellery',
        Category.watches => 'Watches',
        Category.accessories => 'Accessories',
        Category.other => 'Others',
      };

  /// Second-level options offered for this category. Empty for
  /// [Category.other], which takes a short free-text label instead.
  List<String> get subCategories => kSubCategories[this] ?? const [];

  /// True when the sub-category is typed by the user rather than picked.
  bool get takesCustomSubCategory => this == Category.other;
}

/// Predefined sub-categories, ordered most-common-first so the dropdown's
/// top entries are the likely answers. Kept in the domain (not the UI) so the
/// AI engine, the filter bar, and the form all agree on one list.
const Map<Category, List<String>> kSubCategories = {
  Category.designerBags: [
    'Tote', 'Shoulder bag', 'Clutch', 'Potli', 'Sling', 'Backpack', 'Duffle',
  ],
  Category.eventWear: [
    'Lehenga', 'Saree', 'Sherwani', 'Bandhgala', 'Gown', 'Anarkali', 'Suit',
  ],
  Category.partyWear: [
    'Cocktail dress', 'Shimmer dress', 'Jumpsuit', 'Blazer', 'Co-ord set',
  ],
  Category.sportsKits: [
    'Cricket', 'Golf', 'Tennis', 'Badminton', 'Football', 'Cycling', 'Skating',
  ],
  Category.jewellery: [
    'Kundan', 'Polki', 'Temple', 'Diamond', 'Pearl', 'Jhumkas', 'Maang tikka',
  ],
  Category.watches: [
    'Automatic', 'Chronograph', 'Dress watch', 'Smart watch',
  ],
  // Clutches and potlis live here, not under Designer bags: the category
  // dictionary reads them as occasion accessories, and the sample board
  // ("Velvet potli & clutch duo") is filed that way too.
  Category.accessories: [
    'Clutch', 'Potli', 'Stole', 'Pashmina', 'Heels', 'Sunglasses', 'Belt',
    'Turban', 'Brooch',
  ],
};

/// Free-text sub-category cap (only reachable via [Category.other]).
const int kMaxSubCategoryLength = 30;

/// Homework-mandated conversation lifecycle: saved → contacted → closed.
enum InteractionStatus { saved, contacted, closed }

extension InteractionStatusLabel on InteractionStatus {
  String get label => switch (this) {
        InteractionStatus.saved => 'Saved',
        InteractionStatus.contacted => 'Contacted',
        InteractionStatus.closed => 'Closed',
      };
}

/// Physical item lifecycle, independent of the conversation status.
enum LendingState { available, lentOut, returned }

extension LendingStateLabel on LendingState {
  String get label => switch (this) {
        LendingState.available => 'Available',
        LendingState.lentOut => 'Rented out',
        LendingState.returned => 'Returned',
      };
}

/// How the owner prefers to be approached for the handover.
///
/// A closed set of options, never free text. The earlier design also had a
/// free-text "contact note", which was removed and stays removed: it was the
/// single field most likely to carry a phone number, and the privacy scanner
/// existed largely to police it. A preference expresses the same intent
/// without ever holding a digit.
enum ContactChannel { inPerson, societyBoard, buildingWhatsApp }

extension ContactChannelLabel on ContactChannel {
  String get label => switch (this) {
        ContactChannel.inPerson => 'In person',
        ContactChannel.societyBoard => 'Society notice board',
        ContactChannel.buildingWhatsApp => 'Building WhatsApp group',
      };

  String get hint => switch (this) {
        ContactChannel.inPerson => 'Meet to hand over directly',
        ContactChannel.societyBoard => 'Leave a note on the board',
        ContactChannel.buildingWhatsApp => 'Ask in the building group',
      };
}

/// A renter's feedback on a listing: one 5-star rating plus text that can
/// speak to the item ("pristine, exactly as pictured") and the person
/// ("returned on time, lovely to deal with"). First names only.
@immutable
class Review {
  const Review({
    required this.rating,
    required this.text,
    required this.reviewerName,
    required this.createdAt,
  }) : assert(rating >= 1 && rating <= 5, 'rating must be 1..5');

  final int rating;
  final String text;
  final String reviewerName;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.rating == rating &&
      other.text == text &&
      other.reviewerName == reviewerName &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(rating, text, reviewerName, createdAt);
}

const Object _unset = Object();

/// Maximum photos a listing can carry (cover + gallery).
const int kMaxListingPhotos = 5;

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.subCategory = '',
    this.conditionTags = const <String>[],
    required this.area,
    required this.neighborhood,
    this.contactChannel = ContactChannel.societyBoard,
    required this.pricePerDayInr,
    this.depositInr,
    this.status = InteractionStatus.saved,
    this.lendingState = LendingState.available,
    this.dueDate,
    this.returnedAt,
    this.borrowerName = '',
    this.suggestedDurationDays,
    this.photos = const <String>[],
    this.reviews = const <Review>[],
    required this.createdAt,
    required this.updatedAt,
    this.isMine = false,
    this.isDemo = false,
  }) : assert(
          (lendingState == LendingState.lentOut) == (dueDate != null),
          'dueDate must be set if and only if the item is rented out',
        );

  final String id;
  final ListingType type;
  final String title;
  final String description;
  final Category category;

  /// Optional second level: a value from [Category.subCategories], or a short
  /// free-text label when the category is [Category.other]. Empty = unset.
  final String subCategory;
  final List<String> conditionTags;

  /// Landmark-level location only — never an exact address.
  final String area;
  final String neighborhood;

  /// How the owner prefers to be approached. An enum, never free text.
  final ContactChannel contactChannel;

  /// Rental rate in whole rupees per day — bold on every card.
  final int pricePerDayInr;

  /// Optional refundable security deposit in whole rupees.
  final int? depositInr;
  final InteractionStatus status;
  final LendingState lendingState;

  /// Expected return date; non-null iff [lendingState] is [LendingState.lentOut].
  final DateTime? dueDate;
  final DateTime? returnedAt;

  /// First name of the renter (optional, set when marking rented out).
  /// First name only — data minimization by design.
  final String borrowerName;
  final int? suggestedDurationDays;

  /// Item photos, stored on-device as base64 JPEG (downscaled, EXIF
  /// stripped). First photo is the cover. Max [kMaxListingPhotos].
  final List<String> photos;

  /// Renter feedback, newest first.
  final List<Review> reviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Created on this device by the user (vs sample/board data) — powers the
  /// "My items" view.
  final bool isMine;

  /// Sample data flag: shown with a "Sample" badge and removable in one tap.
  final bool isDemo;

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  /// "Jewellery · Kundan", falling back to the bare category when unset.
  String get categoryLabel =>
      subCategory.isEmpty ? category.label : '${category.label} · $subCategory';

  /// Average star rating across reviews, or null when unreviewed.
  double? get averageRating => reviews.isEmpty
      ? null
      : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

  Listing copyWith({
    ListingType? type,
    String? title,
    String? description,
    Category? category,
    String? subCategory,
    List<String>? conditionTags,
    String? area,
    String? neighborhood,
    ContactChannel? contactChannel,
    int? pricePerDayInr,
    Object? depositInr = _unset,
    InteractionStatus? status,
    LendingState? lendingState,
    Object? dueDate = _unset,
    Object? returnedAt = _unset,
    String? borrowerName,
    Object? suggestedDurationDays = _unset,
    List<String>? photos,
    List<Review>? reviews,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      conditionTags: conditionTags ?? this.conditionTags,
      area: area ?? this.area,
      neighborhood: neighborhood ?? this.neighborhood,
      contactChannel: contactChannel ?? this.contactChannel,
      pricePerDayInr: pricePerDayInr ?? this.pricePerDayInr,
      depositInr:
          identical(depositInr, _unset) ? this.depositInr : depositInr as int?,
      status: status ?? this.status,
      lendingState: lendingState ?? this.lendingState,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
      returnedAt:
          identical(returnedAt, _unset) ? this.returnedAt : returnedAt as DateTime?,
      borrowerName: borrowerName ?? this.borrowerName,
      suggestedDurationDays: identical(suggestedDurationDays, _unset)
          ? this.suggestedDurationDays
          : suggestedDurationDays as int?,
      photos: photos ?? this.photos,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMine: isMine,
      isDemo: isDemo,
    );
  }

  /// The only way rental transitions happen — keeps the dueDate invariant.
  Listing markLentOut(DateTime due, DateTime now, {String borrowerName = ''}) =>
      copyWith(
        lendingState: LendingState.lentOut,
        dueDate: due,
        returnedAt: null,
        borrowerName: borrowerName,
        updatedAt: now,
      );

  Listing markReturned(DateTime now) => copyWith(
        lendingState: LendingState.returned,
        dueDate: null,
        returnedAt: now,
        borrowerName: '',
        updatedAt: now,
      );

  Listing markAvailable(DateTime now) => copyWith(
        lendingState: LendingState.available,
        dueDate: null,
        returnedAt: null,
        borrowerName: '',
        updatedAt: now,
      );

  Listing addReview(Review review, DateTime now) => copyWith(
        reviews: [review, ...reviews],
        updatedAt: now,
      );

  @override
  bool operator ==(Object other) {
    return other is Listing &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.subCategory == subCategory &&
        listEquals(other.conditionTags, conditionTags) &&
        other.area == area &&
        other.neighborhood == neighborhood &&
        other.contactChannel == contactChannel &&
        other.pricePerDayInr == pricePerDayInr &&
        other.depositInr == depositInr &&
        other.status == status &&
        other.lendingState == lendingState &&
        other.dueDate == dueDate &&
        other.returnedAt == returnedAt &&
        other.borrowerName == borrowerName &&
        other.suggestedDurationDays == suggestedDurationDays &&
        listEquals(other.photos, photos) &&
        listEquals(other.reviews, reviews) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isMine == isMine &&
        other.isDemo == isDemo;
  }

  @override
  int get hashCode => Object.hash(id, title, description, category, status,
      lendingState, dueDate, pricePerDayInr, updatedAt, isDemo);
}

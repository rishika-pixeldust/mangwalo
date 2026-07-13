import 'package:flutter/foundation.dart';

/// Whether a listing offers an item to lend or requests one to borrow.
enum ListingType { offer, request }

extension ListingTypeLabel on ListingType {
  String get label => switch (this) {
        ListingType.offer => 'Offer',
        ListingType.request => 'Request',
      };
}

enum Category {
  toolsRepair,
  kitchenAppliances,
  booksStudy,
  sportsFitness,
  outdoorsTravel,
  electronics,
  musicInstruments,
  kidsToys,
  festivalDecor,
  homeFurniture,
  other,
}

extension CategoryLabel on Category {
  String get label => switch (this) {
        Category.toolsRepair => 'Tools & Repair',
        Category.kitchenAppliances => 'Kitchen & Appliances',
        Category.booksStudy => 'Books & Study',
        Category.sportsFitness => 'Sports & Fitness',
        Category.outdoorsTravel => 'Outdoors & Travel',
        Category.electronics => 'Electronics',
        Category.musicInstruments => 'Music Instruments',
        Category.kidsToys => 'Kids & Toys',
        Category.festivalDecor => 'Festival & Decor',
        Category.homeFurniture => 'Home & Furniture',
        Category.other => 'Other',
      };
}

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
        LendingState.lentOut => 'Lent out',
        LendingState.returned => 'Returned',
      };
}

/// Privacy-first contact options: no free-text phone numbers required.
enum ContactChannel { inPerson, societyBoard, buildingWhatsApp }

extension ContactChannelLabel on ContactChannel {
  String get label => switch (this) {
        ContactChannel.inPerson => 'In person',
        ContactChannel.societyBoard => 'Society notice board',
        ContactChannel.buildingWhatsApp => 'Building WhatsApp group',
      };
}

const Object _unset = Object();

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.conditionTags = const <String>[],
    required this.area,
    required this.neighborhood,
    this.contactChannel = ContactChannel.societyBoard,
    this.contactNote = '',
    this.status = InteractionStatus.saved,
    this.lendingState = LendingState.available,
    this.dueDate,
    this.returnedAt,
    this.borrowerName = '',
    this.suggestedDurationDays,
    this.photoBase64,
    required this.createdAt,
    required this.updatedAt,
    this.isMine = false,
    this.isDemo = false,
  }) : assert(
          (lendingState == LendingState.lentOut) == (dueDate != null),
          'dueDate must be set if and only if the item is lent out',
        );

  final String id;
  final ListingType type;
  final String title;
  final String description;
  final Category category;
  final List<String> conditionTags;

  /// Landmark-level location only — never an exact address.
  final String area;
  final String neighborhood;
  final ContactChannel contactChannel;

  /// Optional note ("evenings only", "ring flat via intercom"). Stored only
  /// on this device.
  final String contactNote;
  final InteractionStatus status;
  final LendingState lendingState;

  /// Expected return date; non-null iff [lendingState] is [LendingState.lentOut].
  final DateTime? dueDate;
  final DateTime? returnedAt;

  /// First name of the neighbor who borrowed the item (optional, set when
  /// marking lent out). First name only — data minimization by design.
  final String borrowerName;
  final int? suggestedDurationDays;

  /// Optional item photo, stored on-device as base64 JPEG (downscaled).
  final String? photoBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Created on this device by the user (vs sample/board data) — powers the
  /// "My items" view.
  final bool isMine;

  /// Sample data flag: shown with a "Sample" badge and removable in one tap.
  final bool isDemo;

  Listing copyWith({
    ListingType? type,
    String? title,
    String? description,
    Category? category,
    List<String>? conditionTags,
    String? area,
    String? neighborhood,
    ContactChannel? contactChannel,
    String? contactNote,
    InteractionStatus? status,
    LendingState? lendingState,
    Object? dueDate = _unset,
    Object? returnedAt = _unset,
    String? borrowerName,
    Object? suggestedDurationDays = _unset,
    Object? photoBase64 = _unset,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      conditionTags: conditionTags ?? this.conditionTags,
      area: area ?? this.area,
      neighborhood: neighborhood ?? this.neighborhood,
      contactChannel: contactChannel ?? this.contactChannel,
      contactNote: contactNote ?? this.contactNote,
      status: status ?? this.status,
      lendingState: lendingState ?? this.lendingState,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
      returnedAt:
          identical(returnedAt, _unset) ? this.returnedAt : returnedAt as DateTime?,
      borrowerName: borrowerName ?? this.borrowerName,
      suggestedDurationDays: identical(suggestedDurationDays, _unset)
          ? this.suggestedDurationDays
          : suggestedDurationDays as int?,
      photoBase64: identical(photoBase64, _unset)
          ? this.photoBase64
          : photoBase64 as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMine: isMine,
      isDemo: isDemo,
    );
  }

  /// The only way lending transitions happen — keeps the dueDate invariant.
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

  @override
  bool operator ==(Object other) {
    return other is Listing &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        listEquals(other.conditionTags, conditionTags) &&
        other.area == area &&
        other.neighborhood == neighborhood &&
        other.contactChannel == contactChannel &&
        other.contactNote == contactNote &&
        other.status == status &&
        other.lendingState == lendingState &&
        other.dueDate == dueDate &&
        other.returnedAt == returnedAt &&
        other.borrowerName == borrowerName &&
        other.suggestedDurationDays == suggestedDurationDays &&
        other.photoBase64 == photoBase64 &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isMine == isMine &&
        other.isDemo == isDemo;
  }

  @override
  int get hashCode => Object.hash(id, title, description, category, status,
      lendingState, dueDate, updatedAt, isDemo);
}

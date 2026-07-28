import '../../features/listings/domain/listing.dart';
import 'privacy_scanner.dart';
import 'sanitizer.dart';

/// Pure field validators shaped for TextFormField.validator.
///
/// Every validator checks the SANITIZED form of the input — the exact string
/// that would be stored — so sanitization can never turn passing input into
/// a value the validator would have rejected (e.g. a phone number written
/// with double spaces collapsing into a matchable one).
///
/// Hard errors block saving; privacy WARNINGS (see PrivacyScanner) do not —
/// except in the area field, whose whole contract is "landmark only", where
/// any privacy signal is a hard error.
abstract final class Validators {
  static const titleMin = 3;
  static const titleMax = 60;
  static const descriptionMin = 10;
  static const descriptionMax = 500;
  static const areaMin = 3;
  static const areaMax = 60;

  static final _hasLetter = RegExp(r'[a-zA-Z]');

  static String? title(String? value) {
    final v = sanitize(value ?? '');
    if (v.isEmpty) return 'Give your listing a short title.';
    if (v.length < titleMin) return 'Title needs at least $titleMin characters.';
    if (v.length > titleMax) return 'Keep the title under $titleMax characters.';
    if (!_hasLetter.hasMatch(v)) return 'Title should contain some letters.';
    return null;
  }

  static String? description(String? value) {
    final v = sanitize(value ?? '', multiline: true);
    if (v.isEmpty) return 'Describe the item in a line or two.';
    if (v.length < descriptionMin) {
      return 'Description needs at least $descriptionMin characters.';
    }
    if (v.length > descriptionMax) {
      return 'Keep the description under $descriptionMax characters.';
    }
    return null;
  }

  /// Landmark-level only. ANY privacy signal — phone number, PIN code, unit
  /// number, wing-flat shorthand plus society vocabulary — or digit-heavy
  /// text is a HARD error here.
  static String? area(String? value) {
    final v = sanitize(value ?? '');
    if (v.isEmpty) return 'Add a nearby landmark, e.g. "Near Joggers Park".';
    if (v.length < areaMin) return 'Landmark needs at least $areaMin characters.';
    if (v.length > areaMax) return 'Keep the landmark under $areaMax characters.';
    if (PrivacyScanner.scan(v).isNotEmpty) {
      return 'Use a landmark, not an exact address or number — '
          'e.g. "Near Joggers Park gate".';
    }
    final digits = v.replaceAll(RegExp(r'\D'), '').length;
    if (digits / v.length > 0.4) {
      return 'That looks like an address or code. A landmark is enough.';
    }
    return null;
  }

  static const priceMin = 50;
  static const priceMax = 100000;
  static const depositMax = 500000;

  /// Rental rate in whole ₹/day. Required for offers AND requests (where it
  /// reads as the budget).
  static String? pricePerDay(String? value) {
    final v = sanitize(value ?? '').replaceAll(',', '');
    if (v.isEmpty) return 'Set a daily rate in rupees.';
    final n = int.tryParse(v);
    if (n == null) return 'Whole rupees only, e.g. 2500.';
    if (n < priceMin) return 'Rate must be at least ₹$priceMin/day.';
    if (n > priceMax) return 'Keep the rate under ₹$priceMax/day.';
    return null;
  }

  /// Optional refundable deposit in whole ₹.
  static String? deposit(String? value) {
    final v = sanitize(value ?? '').replaceAll(',', '');
    if (v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null) return 'Whole rupees only, e.g. 15000.';
    if (n < 0) return 'Deposit cannot be negative.';
    if (n > depositMax) return 'Keep the deposit under ₹$depositMax.';
    return null;
  }

  /// Free-text sub-category, only reachable when the category is "Others".
  static String? subCategory(String? value) {
    final v = sanitize(value ?? '');
    if (v.length > kMaxSubCategoryLength) {
      return 'Keep it under $kMaxSubCategoryLength characters.';
    }
    return null;
  }

  /// Expected return date must be today or later, within a year.
  static String? returnDate(DateTime? value, DateTime now) {
    if (value == null) return 'Pick an expected return date.';
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(value.year, value.month, value.day);
    if (due.isBefore(today)) return 'Return date must be today or later.';
    if (due.isAfter(today.add(const Duration(days: 365)))) {
      return 'Return date must be within a year.';
    }
    return null;
  }
}

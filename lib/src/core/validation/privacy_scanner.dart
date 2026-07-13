import 'package:flutter/foundation.dart';

/// Deterministic PII heuristics. This is SECURITY, deliberately separate from
/// the AI feature: the listing helper never sees contact or area fields, and
/// privacy scanning works even if the AI engine were removed.
abstract final class PrivacyPatterns {
  /// Indian mobile: optional +91 / 91 / 0 prefix, 10 digits starting 6-9,
  /// tolerating single space/dash/dot separators. Digit-boundary guards stop
  /// matches inside longer digit runs (order ids, prices).
  static final indianPhone = RegExp(
      r'(?<!\d)(?:\+?91[\s.\-]{0,2}|0)?[6-9](?:[\s.\-]?\d){9}(?!\d)');

  /// Mumbai-region PIN, contiguous or spaced ("400 076") — strong signal,
  /// precise because the app is Mumbai-only.
  static final mumbaiPin = RegExp(r'(?<!\d)400\s?\d{3}(?!\d)');

  /// Any 6 contiguous digits not starting with 0 — weak PIN signal.
  static final genericPin = RegExp(r'(?<!\d)[1-9]\d{5}(?!\d)');

  /// Unit numbers: "flat no 402", "apt #12", "house no. B-3", "gala 7".
  static final unitNumber = RegExp(
      r'\b(?:flat|flt|apt|apartment|room|rm|house|shop|gala|office|bungalow|row\s*house)'
      r'\s*(?:no\.?|number|#)?\s*[-:]?\s*[a-z]?\s?\d{1,4}\b',
      caseSensitive: false);

  /// Wing-unit shorthand: "B-402", "a/1203". Needs 2-4 digits and a separator
  /// so model names like "R15" don't match. Weak signal.
  static final wingUnit =
      RegExp(r'\b[a-z]\s*[-/]\s*\d{2,4}\b', caseSensitive: false);

  /// Floor mentions: "3rd floor", "ground floor". Weak signal.
  static final floor = RegExp(
      r'\b(?:\d{1,2}\s*(?:st|nd|rd|th)?|ground|first|second|third)\s*floor\b',
      caseSensitive: false);

  /// Society/building vocabulary. Weak signal.
  static final societyWords = RegExp(
      r'\b(?:chs|c\.h\.s\.?|housing\s+society|society|soc\.|building|bldg|'
      r'tower|wing|plot\s*(?:no\.?)?|sector|lane\s*(?:no\.?)?|galli|gully)\b',
      caseSensitive: false);
}

enum PrivacyWarningType { phoneNumber, exactAddress, pinCode }

@immutable
class PrivacyWarning {
  const PrivacyWarning({
    required this.type,
    required this.matchedText,
    required this.message,
  });

  final PrivacyWarningType type;

  /// Shown to the user so they know exactly what to remove.
  final String matchedText;
  final String message;
}

abstract final class PrivacyScanner {
  /// Pure and deterministic; returns warnings in fixed type order.
  ///
  /// Strong signals (phone, Mumbai PIN, unit number) warn on their own.
  /// Weak signals (generic PIN, wing-unit, floor, society words) score 1
  /// each and warn when the total reaches 2 — a single "society WhatsApp
  /// group" or "worth 500000" is common benign text.
  static List<PrivacyWarning> scan(String text) {
    final warnings = <PrivacyWarning>[];
    if (text.trim().isEmpty) return warnings;

    final phone = PrivacyPatterns.indianPhone.firstMatch(text);
    if (phone != null) {
      warnings.add(PrivacyWarning(
        type: PrivacyWarningType.phoneNumber,
        matchedText: phone.group(0)!.trim(),
        message:
            'This looks like a phone number. For your safety, keep contact '
            'details in the contact field — not in free text.',
      ));
    }

    final pin = PrivacyPatterns.mumbaiPin.firstMatch(text);
    if (pin != null) {
      warnings.add(PrivacyWarning(
        type: PrivacyWarningType.pinCode,
        matchedText: pin.group(0)!.trim(),
        message: 'This looks like a PIN code. A landmark is enough — '
            'exact locations stay private.',
      ));
    }

    String? addressMatch;
    final unit = PrivacyPatterns.unitNumber.firstMatch(text);
    if (unit != null) {
      addressMatch = unit.group(0);
    } else {
      var score = 0;
      String? firstWeak;
      for (final pattern in [
        PrivacyPatterns.genericPin,
        PrivacyPatterns.wingUnit,
        PrivacyPatterns.floor,
        PrivacyPatterns.societyWords,
      ]) {
        final m = pattern.firstMatch(text);
        if (m != null) {
          score++;
          firstWeak ??= m.group(0);
        }
      }
      if (score >= 2) addressMatch = firstWeak;
    }
    if (addressMatch != null) {
      warnings.add(PrivacyWarning(
        type: PrivacyWarningType.exactAddress,
        matchedText: addressMatch.trim(),
        message: 'This looks like an exact address. Use a landmark instead — '
            'e.g. "Near Joggers Park gate".',
      ));
    }

    return warnings;
  }
}

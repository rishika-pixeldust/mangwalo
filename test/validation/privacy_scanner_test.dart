import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/validation/privacy_scanner.dart';

void main() {
  group('PrivacyScanner', () {
    test('detects Indian phone number with spaces', () {
      final warnings = PrivacyScanner.scan('call me on 98765 43210');
      expect(warnings, hasLength(1));
      expect(warnings.single.type, PrivacyWarningType.phoneNumber);
      expect(warnings.single.matchedText, contains('98765 43210'));
    });

    test('detects +91-prefixed phone number', () {
      final warnings = PrivacyScanner.scan('whatsapp +91 98200 12345 anytime');
      expect(
          warnings.map((w) => w.type), contains(PrivacyWarningType.phoneNumber));
    });

    test('unit number alone is a strong address signal', () {
      final warnings = PrivacyScanner.scan('flat no 402, silver oaks chs');
      expect(warnings.map((w) => w.type),
          contains(PrivacyWarningType.exactAddress));
    });

    test('multiple weak signals combine into an address warning', () {
      final warnings = PrivacyScanner.scan('B-1204, 12th floor, oberoi tower');
      expect(warnings.map((w) => w.type),
          contains(PrivacyWarningType.exactAddress));
    });

    test('Mumbai PIN code warns on its own', () {
      final warnings = PrivacyScanner.scan('drop it at 400076');
      expect(warnings.map((w) => w.type),
          contains(PrivacyWarningType.pinCode));
    });

    test('benign digits and model names do not warn', () {
      final warnings =
          PrivacyScanner.scan('deposit 500, order #12345, model R15');
      expect(warnings, isEmpty);
    });

    test('single weak signal does not warn', () {
      final warnings =
          PrivacyScanner.scan('message our society whatsapp group');
      expect(warnings, isEmpty);
    });

    test('deterministic: same input → same warnings', () {
      const input = 'flat no 402 near 400076';
      final a = PrivacyScanner.scan(input);
      final b = PrivacyScanner.scan(input);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].type, b[i].type);
        expect(a[i].matchedText, b[i].matchedText);
      }
    });
  });
}

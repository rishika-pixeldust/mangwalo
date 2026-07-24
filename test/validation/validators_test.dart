import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/validation/sanitizer.dart';
import 'package:mangwalo/src/core/validation/validators.dart';

void main() {
  group('Validators.title', () {
    test('too short is rejected', () {
      expect(Validators.title('ab'), isNotNull);
    });

    test('valid title passes', () {
      expect(Validators.title('Bosch Drill Machine'), isNull);
    });

    test('digits-only title rejected', () {
      expect(Validators.title('12345'), isNotNull);
    });
  });

  group('Validators.area (landmark only — hard errors)', () {
    test('PIN code in area is a hard error', () {
      expect(Validators.area('near 400076 powai'), isNotNull);
    });

    test('phone number in area is a hard error', () {
      expect(Validators.area('call 9820012345'), isNotNull);
    });

    test('unit number in area is a hard error', () {
      expect(Validators.area('flat no 12, hill road'), isNotNull);
    });

    test('digit-heavy area is a hard error', () {
      expect(Validators.area('12/345 6789'), isNotNull);
    });

    test('classic wing-flat address is a hard error', () {
      expect(Validators.area('B-402 Sunshine CHS'), isNotNull);
    });

    test('floor + society vocabulary combo is a hard error', () {
      expect(Validators.area('3rd floor, oberoi tower'), isNotNull);
    });

    test('double-spaced phone digits cannot sneak past validation', () {
      // Sanitization collapses the spacing, and validators check the
      // sanitized form — so what would be stored is what gets validated.
      expect(Validators.area('9  8  2  0  0  1  2  3  4  5'), isNotNull);
    });

    test('landmark passes', () {
      expect(Validators.area('Near Powai Lake'), isNull);
    });
  });

  group('Validators.pricePerDay / deposit', () {
    test('price is required and numeric', () {
      expect(Validators.pricePerDay(''), isNotNull);
      expect(Validators.pricePerDay('abc'), isNotNull);
      expect(Validators.pricePerDay('2500'), isNull);
      expect(Validators.pricePerDay('2,500'), isNull); // commas tolerated
    });

    test('price bounds enforced', () {
      expect(Validators.pricePerDay('10'), isNotNull); // below ₹50 floor
      expect(Validators.pricePerDay('999999'), isNotNull); // above cap
      expect(Validators.pricePerDay('100000'), isNull);
    });

    test('deposit is optional but bounded when present', () {
      expect(Validators.deposit(''), isNull);
      expect(Validators.deposit(null), isNull);
      expect(Validators.deposit('15000'), isNull);
      expect(Validators.deposit('abc'), isNotNull);
      expect(Validators.deposit('999999'), isNotNull);
    });
  });

  group('Validators.returnDate', () {
    final now = DateTime(2026, 7, 13, 15, 30);

    test('yesterday is rejected', () {
      expect(
          Validators.returnDate(DateTime(2026, 7, 12), now), isNotNull);
    });

    test('today is accepted', () {
      expect(Validators.returnDate(DateTime(2026, 7, 13), now), isNull);
    });

    test('more than a year away is rejected', () {
      expect(
          Validators.returnDate(DateTime(2027, 8, 1), now), isNotNull);
    });
  });

  group('sanitize', () {
    test('strips control chars and collapses whitespace', () {
      expect(sanitize('  hello\u0000  world  '), 'hello world');
    });

    test('clamps to max length', () {
      expect(sanitize('abcdef', maxLength: 3), 'abc');
    });

    test('multiline mode preserves user line breaks, max one blank line', () {
      expect(
        sanitize('line one\n\n\n\nline   two', multiline: true),
        'line one\n\nline two',
      );
    });

    test('single-line mode flattens newlines', () {
      expect(sanitize('line one\nline two'), 'line one line two');
    });

    test('removes zero-width and bidi characters without splitting words', () {
      expect(sanitize('he\u200Bllo \u202Eworld\uFEFF'), 'hello world');
    });
  });
}

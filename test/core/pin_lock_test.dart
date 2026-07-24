import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/security/pin.dart';
import 'package:mangwalo/src/features/settings/domain/app_settings.dart';

void main() {
  group('PinLock', () {
    test('verify accepts the right PIN and rejects the wrong one', () {
      final salt = PinLock.newSalt();
      final hash = PinLock.hash('4321', salt);
      expect(PinLock.verify('4321', salt, hash), isTrue);
      expect(PinLock.verify('1234', salt, hash), isFalse);
    });

    test('same PIN with different salts produces different hashes', () {
      final a = PinLock.hash('4321', PinLock.newSalt());
      final b = PinLock.hash('4321', PinLock.newSalt());
      expect(a, isNot(b));
    });

    test('isValidPin enforces 4–6 digits', () {
      expect(PinLock.isValidPin('1234'), isTrue);
      expect(PinLock.isValidPin('123456'), isTrue);
      expect(PinLock.isValidPin('123'), isFalse);
      expect(PinLock.isValidPin('1234567'), isFalse);
      expect(PinLock.isValidPin('12ab'), isFalse);
    });
  });

  group('AppSettings json', () {
    test('profile, PIN, and intro flags round-trip', () {
      const settings = AppSettings(
        neighborhood: 'Bandra West',
        displayName: 'Rishika',
        pinSalt: 'c2FsdA==',
        pinHash: 'abc123',
        introSeen: true,
        seedVersion: 1,
      );
      final decoded = AppSettings.fromJsonMap(settings.toJsonMap());
      expect(decoded, settings);
      expect(decoded.pinEnabled, isTrue);
    });

    test('legacy map without new fields decodes with safe defaults', () {
      final decoded = AppSettings.fromJsonMap({
        'neighborhood': 'Powai',
        'themeMode': 'dark',
        'seedVersion': 1,
      });
      expect(decoded.displayName, isEmpty);
      expect(decoded.pinEnabled, isFalse);
      expect(decoded.introSeen, isFalse);
    });
  });
}

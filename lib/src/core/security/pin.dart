import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// App-lock PIN hashing. The PIN is never stored — only a random salt and
/// the SHA-256 of salt+PIN. Honest scope (documented in
/// docs/security-baseline.md): this gates the UI against casual snooping on
/// a shared device; local data is not additionally encrypted at rest.
abstract final class PinLock {
  static final _rng = Random.secure();

  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return base64Encode(bytes);
  }

  static String hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool verify(String pin, String salt, String expectedHash) =>
      hash(pin, salt) == expectedHash;

  static bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);
}

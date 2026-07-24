import 'package:flutter/material.dart';

const Object _unset = Object();

/// Locally stored app preferences. `neighborhood == null` means onboarding
/// has not been completed yet.
@immutable
class AppSettings {
  const AppSettings({
    this.neighborhood,
    this.displayName = '',
    this.pinSalt,
    this.pinHash,
    this.introSeen = false,
    this.themeMode = ThemeMode.system,
    this.seedVersion = 0,
  });

  final String? neighborhood;

  /// The local profile: a first name used for "your" listings and as the
  /// default reviewer name. No account, no server — just a name.
  final String displayName;

  /// Optional app lock. The PIN itself is never stored — only a salted
  /// SHA-256 hash. Honest scope: it gates the UI against casual snooping on
  /// a shared device; it is not at-rest encryption.
  final String? pinSalt;
  final String? pinHash;

  /// Whether the first-launch concept intro has been viewed (or skipped).
  final bool introSeen;
  final ThemeMode themeMode;

  /// Highest sample-data version ever loaded; keeps sample loading idempotent.
  final int seedVersion;

  bool get onboardingDone => neighborhood != null;
  bool get pinEnabled => pinHash != null && pinSalt != null;

  AppSettings copyWith({
    String? neighborhood,
    String? displayName,
    Object? pinSalt = _unset,
    Object? pinHash = _unset,
    bool? introSeen,
    ThemeMode? themeMode,
    int? seedVersion,
  }) {
    return AppSettings(
      neighborhood: neighborhood ?? this.neighborhood,
      displayName: displayName ?? this.displayName,
      pinSalt: identical(pinSalt, _unset) ? this.pinSalt : pinSalt as String?,
      pinHash: identical(pinHash, _unset) ? this.pinHash : pinHash as String?,
      introSeen: introSeen ?? this.introSeen,
      themeMode: themeMode ?? this.themeMode,
      seedVersion: seedVersion ?? this.seedVersion,
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'neighborhood': neighborhood,
        'displayName': displayName,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'introSeen': introSeen,
        'themeMode': themeMode.name,
        'seedVersion': seedVersion,
      };

  factory AppSettings.fromJsonMap(Map<String, dynamic> map) {
    final themeName = map['themeMode'] as String?;
    return AppSettings(
      neighborhood: map['neighborhood'] as String?,
      displayName: map['displayName'] as String? ?? '',
      pinSalt: map['pinSalt'] as String?,
      pinHash: map['pinHash'] as String?,
      introSeen: map['introSeen'] as bool? ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      seedVersion: (map['seedVersion'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.neighborhood == neighborhood &&
      other.displayName == displayName &&
      other.pinSalt == pinSalt &&
      other.pinHash == pinHash &&
      other.introSeen == introSeen &&
      other.themeMode == themeMode &&
      other.seedVersion == seedVersion;

  @override
  int get hashCode => Object.hash(neighborhood, displayName, pinSalt, pinHash,
      introSeen, themeMode, seedVersion);
}

import 'package:flutter/material.dart';

import '../../../theme/dark_variant.dart';

/// Locally stored app preferences. `neighborhood == null` means onboarding
/// has not been completed yet.
@immutable
class AppSettings {
  const AppSettings({
    this.neighborhood,
    this.displayName = '',
    this.introSeen = false,
    this.tutorialSeen = false,
    this.themeMode = ThemeMode.system,
    this.darkVariant = DarkVariant.warmCharcoal,
    this.hideSamples = false,
    this.showAllLocalities = false,
    this.seedVersion = 0,
  });

  final String? neighborhood;

  /// The local profile: a first name used for "your" listings and as the
  /// default reviewer name.
  final String displayName;

  /// Whether the first-launch concept intro has been viewed (or skipped).
  final bool introSeen;

  /// Whether the on-board coach-mark tour has been completed (or skipped).
  /// Replayable from the avatar menu, which just flips this back to false.
  final bool tutorialSeen;

  final ThemeMode themeMode;

  /// Which dark palette to use when dark is active. Light is fixed — it's the
  /// one people liked.
  final DarkVariant darkVariant;

  /// Hides the badged sample listings from the board without deleting rows
  /// other people's boards depend on.
  final bool hideSamples;

  /// Escape hatch from locality scoping: show every locality's listings.
  final bool showAllLocalities;

  /// Highest sample-data version ever loaded; keeps sample loading idempotent.
  final int seedVersion;

  bool get onboardingDone => neighborhood != null;

  AppSettings copyWith({
    String? neighborhood,
    String? displayName,
    bool? introSeen,
    bool? tutorialSeen,
    ThemeMode? themeMode,
    DarkVariant? darkVariant,
    bool? hideSamples,
    bool? showAllLocalities,
    int? seedVersion,
  }) {
    return AppSettings(
      neighborhood: neighborhood ?? this.neighborhood,
      displayName: displayName ?? this.displayName,
      introSeen: introSeen ?? this.introSeen,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      themeMode: themeMode ?? this.themeMode,
      darkVariant: darkVariant ?? this.darkVariant,
      hideSamples: hideSamples ?? this.hideSamples,
      showAllLocalities: showAllLocalities ?? this.showAllLocalities,
      seedVersion: seedVersion ?? this.seedVersion,
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'neighborhood': neighborhood,
        'displayName': displayName,
        'introSeen': introSeen,
        'tutorialSeen': tutorialSeen,
        'themeMode': themeMode.name,
        'darkVariant': darkVariant.name,
        'hideSamples': hideSamples,
        'showAllLocalities': showAllLocalities,
        'seedVersion': seedVersion,
      };

  /// Tolerant decode: missing keys take defaults, and the retired PIN fields
  /// (`pinSalt`/`pinHash`) are simply ignored — dropping them is the whole
  /// point of the migration.
  factory AppSettings.fromJsonMap(Map<String, dynamic> map) {
    final themeName = map['themeMode'] as String?;
    final variantName = map['darkVariant'] as String?;
    return AppSettings(
      neighborhood: map['neighborhood'] as String?,
      displayName: map['displayName'] as String? ?? '',
      introSeen: map['introSeen'] as bool? ?? false,
      tutorialSeen: map['tutorialSeen'] as bool? ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      darkVariant: DarkVariant.values.firstWhere(
        (v) => v.name == variantName,
        orElse: () => DarkVariant.warmCharcoal,
      ),
      hideSamples: map['hideSamples'] as bool? ?? false,
      showAllLocalities: map['showAllLocalities'] as bool? ?? false,
      seedVersion: (map['seedVersion'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.neighborhood == neighborhood &&
      other.displayName == displayName &&
      other.introSeen == introSeen &&
      other.tutorialSeen == tutorialSeen &&
      other.themeMode == themeMode &&
      other.darkVariant == darkVariant &&
      other.hideSamples == hideSamples &&
      other.showAllLocalities == showAllLocalities &&
      other.seedVersion == seedVersion;

  @override
  int get hashCode => Object.hash(neighborhood, displayName, introSeen,
      tutorialSeen, themeMode, darkVariant, hideSamples, showAllLocalities,
      seedVersion);
}

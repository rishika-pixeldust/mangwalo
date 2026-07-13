import 'package:flutter/material.dart';

/// Locally stored app preferences. `neighborhood == null` means onboarding
/// has not been completed yet.
@immutable
class AppSettings {
  const AppSettings({
    this.neighborhood,
    this.themeMode = ThemeMode.system,
    this.seedVersion = 0,
  });

  final String? neighborhood;
  final ThemeMode themeMode;

  /// Highest sample-data version ever loaded; keeps sample loading idempotent.
  final int seedVersion;

  bool get onboardingDone => neighborhood != null;

  AppSettings copyWith({
    String? neighborhood,
    ThemeMode? themeMode,
    int? seedVersion,
  }) {
    return AppSettings(
      neighborhood: neighborhood ?? this.neighborhood,
      themeMode: themeMode ?? this.themeMode,
      seedVersion: seedVersion ?? this.seedVersion,
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'neighborhood': neighborhood,
        'themeMode': themeMode.name,
        'seedVersion': seedVersion,
      };

  factory AppSettings.fromJsonMap(Map<String, dynamic> map) {
    final themeName = map['themeMode'] as String?;
    return AppSettings(
      neighborhood: map['neighborhood'] as String?,
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
      other.themeMode == themeMode &&
      other.seedVersion == seedVersion;

  @override
  int get hashCode => Object.hash(neighborhood, themeMode, seedVersion);
}

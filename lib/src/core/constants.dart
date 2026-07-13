/// App-wide constants. No secrets live here — or anywhere in this repo.
abstract final class AppConstants {
  static const appName = 'MangWalo';
  static const tagline = 'Maang lo — your neighborhood lends a hand.';

  /// Single-neighborhood scope: the user picks one at first launch.
  static const neighborhoods = <String>[
    'Bandra West',
    'Andheri East',
    'Powai',
    'Dadar',
    'Ghatkopar West',
    'Malad West',
    'Chembur',
    'Vile Parle East',
  ];

  static const listingsBox = 'listings';
  static const settingsBox = 'settings';
  static const settingsKey = 'appSettings';

  /// Version stamped into every persisted listing for tolerant migration.
  static const schemaVersion = 1;
}

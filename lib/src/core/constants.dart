/// App-wide constants. No secrets live here — or anywhere in this repo.
abstract final class AppConstants {
  static const appName = 'MangWalo';
  static const tagline = 'Maang lo — luxury from your locality.';

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
  // v2: the luxury-rental pivot — pricing, deposits, multi-photo galleries,
  // reviews, and the new catalog categories.
  /// v3: sub-categories added, `contactChannel`/`contactNote` retired.
  static const schemaVersion = 3;

  /// Bumped whenever the sample set itself changes. Sample ids are
  /// deterministic ('sample-N'), so re-seeding overwrites the old rows in
  /// place — existing users pick up refreshed samples with no duplicates.
  /// v2: sub-categories, multi-photo galleries, contact fields gone.
  static const seedVersion = 2;
}

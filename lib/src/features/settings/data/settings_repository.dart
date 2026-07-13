import '../domain/app_settings.dart';

/// Storage boundary for app settings, mirroring ListingRepository so the
/// whole persistence layer stays swappable.
abstract interface class SettingsRepository {
  /// Synchronous: settings must be available before the first frame.
  AppSettings load();

  Future<void> save(AppSettings settings);

  /// Backs "Reset all local data".
  Future<void> clear();
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../listings/application/feed_filter_controller.dart';
import '../../listings/application/listing_providers.dart';
import '../../listings/data/seed_data.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Overridden in main() with the Hive-backed implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('Overridden at bootstrap'),
);

class SettingsController extends Notifier<AppSettings> {
  bool _seeding = false;

  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  /// Completes setup and loads the sample noticeboard so the first feed is
  /// never empty. Samples are clearly badged and removable in Settings.
  Future<void> completeOnboarding(String neighborhood) async {
    await _update(state.copyWith(neighborhood: neighborhood));
    await loadSamples();
  }

  Future<void> changeNeighborhood(String neighborhood) =>
      _update(state.copyWith(neighborhood: neighborhood));

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  /// Idempotent: the in-flight guard stops double-taps racing the await, and
  /// sample ids are deterministic so a second putAll could only overwrite.
  Future<void> loadSamples() async {
    if (_seeding || state.seedVersion >= 1) return;
    final neighborhood = state.neighborhood;
    if (neighborhood == null) return;
    _seeding = true;
    try {
      final now = ref.read(nowProvider)();
      await ref.read(listingRepositoryProvider).putAll(
            buildSampleListings(neighborhood: neighborhood, now: now),
          );
      await _update(state.copyWith(seedVersion: 1));
    } finally {
      _seeding = false;
    }
  }

  /// Removes only sample rows; the user's own listings are untouched.
  Future<void> removeSamples() async {
    final repo = ref.read(listingRepositoryProvider);
    final all = await repo.getAll();
    for (final l in all.where((l) => l.isDemo)) {
      await repo.delete(l.id);
    }
    await _update(state.copyWith(seedVersion: 0));
  }

  /// Wipes everything — listings, settings, AND in-memory UI state like the
  /// feed filter — and returns the app to onboarding. The homework's
  /// mandated data-deletion control must leave no stale state behind.
  Future<void> resetAll() async {
    await ref.read(listingRepositoryProvider).clear();
    await ref.read(settingsRepositoryProvider).clear();
    ref.invalidate(feedFilterProvider);
    state = const AppSettings();
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

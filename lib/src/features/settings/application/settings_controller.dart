import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/constants.dart';
import '../../../theme/dark_variant.dart';
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
  /// never empty. Samples are clearly badged and hideable in Settings.
  Future<void> completeOnboarding(
    String neighborhood, {
    String displayName = '',
  }) async {
    await _update(state.copyWith(
      neighborhood: neighborhood,
      displayName: displayName,
    ));
    await loadSamples();
  }

  Future<void> markIntroSeen() => _update(state.copyWith(introSeen: true));

  Future<void> markTutorialSeen() =>
      _update(state.copyWith(tutorialSeen: true));

  /// Re-arms the coach-mark tour ("How it works" in the avatar menu).
  Future<void> replayTutorial() =>
      _update(state.copyWith(tutorialSeen: false));

  Future<void> setDisplayName(String name) =>
      _update(state.copyWith(displayName: name));

  /// Switching locality re-scopes the board, so clear the "show everything"
  /// escape hatch — otherwise the new locality appears to change nothing,
  /// which is exactly the confusion this whole change set fixes.
  Future<void> changeNeighborhood(String neighborhood) => _update(state.copyWith(
        neighborhood: neighborhood,
        showAllLocalities: false,
      ));

  Future<void> setShowAllLocalities(bool value) =>
      _update(state.copyWith(showAllLocalities: value));

  Future<void> setHideSamples(bool value) =>
      _update(state.copyWith(hideSamples: value));

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setDarkVariant(DarkVariant variant) =>
      _update(state.copyWith(darkVariant: variant));

  /// Seeds the local sample board.
  ///
  /// Idempotent: the in-flight guard stops double-taps racing the await, and
  /// sample ids are deterministic so a second putAll could only overwrite.
  ///
  /// Skipped entirely once the shared noticeboard is configured. Writes go
  /// through the synced repository there, so seeding locally would upload 15
  /// sample listings owned by whoever happened to open the app — and then
  /// again for the next visitor. Samples are ONE shared server-side set
  /// (see docs/product-roadmap.md), seeded once by an operator, never by a
  /// client.
  Future<void> loadSamples() async {
    if (ref.read(backendReadyProvider)) return;
    if (_seeding || state.seedVersion >= AppConstants.seedVersion) return;
    final neighborhood = state.neighborhood;
    if (neighborhood == null) return;
    _seeding = true;
    try {
      final now = ref.read(nowProvider)();
      final samples = await buildSampleListings(
        neighborhood: neighborhood,
        now: now,
        photoLoader: _loadSeedPhoto,
      );
      await ref.read(listingRepositoryProvider).putAll(samples);
      await _update(state.copyWith(seedVersion: AppConstants.seedVersion));
    } finally {
      _seeding = false;
    }
  }

  /// Bundled sample imagery → base64, same storage shape as user photos.
  /// A missing asset just means that sample ships without a picture.
  static Future<String?> _loadSeedPhoto(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return base64Encode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return null;
    }
  }

  /// Drops legacy local sample rows. Samples are shared reference data now,
  /// so the user-facing control is "Hide sample listings" ([setHideSamples])
  /// rather than a delete — this exists only for the one-time migration off
  /// per-device seeding.
  Future<void> purgeLocalSamples() async {
    final repo = ref.read(listingRepositoryProvider);
    final all = await repo.getAll();
    for (final l in all.where((l) => l.isDemo)) {
      await repo.delete(l.id);
    }
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

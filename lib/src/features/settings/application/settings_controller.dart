import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/security/pin.dart';
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
  Future<void> completeOnboarding(
    String neighborhood, {
    String displayName = '',
    String? pin,
  }) async {
    var next = state.copyWith(
      neighborhood: neighborhood,
      displayName: displayName,
    );
    if (pin != null && PinLock.isValidPin(pin)) {
      final salt = PinLock.newSalt();
      next = next.copyWith(pinSalt: salt, pinHash: PinLock.hash(pin, salt));
    }
    await _update(next);
    await loadSamples();
  }

  Future<void> markIntroSeen() => _update(state.copyWith(introSeen: true));

  Future<void> setDisplayName(String name) =>
      _update(state.copyWith(displayName: name));

  Future<void> setPin(String pin) async {
    final salt = PinLock.newSalt();
    await _update(
        state.copyWith(pinSalt: salt, pinHash: PinLock.hash(pin, salt)));
  }

  Future<void> removePin() =>
      _update(state.copyWith(pinSalt: null, pinHash: null));

  bool verifyPin(String pin) {
    final salt = state.pinSalt;
    final hash = state.pinHash;
    if (salt == null || hash == null) return true;
    return PinLock.verify(pin, salt, hash);
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
      final samples = await buildSampleListings(
        neighborhood: neighborhood,
        now: now,
        photoLoader: _loadSeedPhoto,
      );
      await ref.read(listingRepositoryProvider).putAll(samples);
      await _update(state.copyWith(seedVersion: 1));
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

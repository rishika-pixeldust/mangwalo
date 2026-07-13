import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../core/constants.dart';
import '../domain/app_settings.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  final Box<String> _box;

  @override
  AppSettings load() {
    final raw = _box.get(AppConstants.settingsKey);
    if (raw == null) return const AppSettings();
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return const AppSettings();
      return AppSettings.fromJsonMap(map);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) =>
      _box.put(AppConstants.settingsKey, jsonEncode(settings.toJsonMap()));

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

/// Runtime fallback when browser storage is unavailable.
class InMemorySettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;

  @override
  Future<void> clear() async => _settings = const AppSettings();
}

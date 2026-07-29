import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/constants.dart';
import 'src/features/listings/application/listing_providers.dart';
import 'src/features/listings/data/cached_synced_listing_repository.dart';
import 'src/features/listings/data/hive_listing_repository.dart';
import 'src/features/listings/data/in_memory_listing_repository.dart';
import 'src/features/listings/data/listing_repository.dart';
import 'src/features/listings/data/supabase_listing_source.dart';
import 'src/features/settings/application/settings_controller.dart';
import 'src/features/settings/data/hive_settings_repository.dart';
import 'src/features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boxes open before the first frame; providers receive them via overrides
  // so there are no async-bootstrap races. If browser storage is unavailable
  // (e.g. strict private mode), fall back to in-memory repositories and let
  // the UI show a "changes won't persist" banner instead of crashing.
  ListingRepository listingRepository;
  SettingsRepository settingsRepository;
  var storageAvailable = true;
  try {
    await Hive.initFlutter();
    final listingsBox = await Hive.openBox<String>(AppConstants.listingsBox);
    final settingsBox = await Hive.openBox<String>(AppConstants.settingsBox);
    listingRepository = HiveListingRepository(listingsBox);
    settingsRepository = HiveSettingsRepository(settingsBox);
  } catch (_) {
    storageAvailable = false;
    listingRepository = InMemoryListingRepository();
    settingsRepository = InMemorySettingsRepository();
  }

  // The shared noticeboard is opt-in at build time: with no credentials the
  // app stays entirely local, which keeps `flutter run` useful for anyone who
  // clones the repo. A failure to reach Supabase must also degrade to local
  // rather than block the board behind an error screen.
  var backendReady = false;
  if (AppConfig.hasBackend) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      backendReady = true;
    } catch (_) {
      backendReady = false;
    }
  }

  if (backendReady) {
    final client = Supabase.instance.client;

    // Give the app an identity before the first frame, without asking anything
    // of the user. Anonymous is a real auth.users row with a working
    // auth.uid(), so RLS and every foreign key behave exactly as they will
    // once a stronger provider is added — nothing downstream changes.
    if (client.auth.currentSession == null) {
      try {
        await client.auth.signInAnonymously();
      } catch (_) {
        // Provider disabled or offline: fall through to the local board rather
        // than blocking behind an error screen.
      }
    }

    // Only now swap the seam. Hive stays the read path — the board paints from
    // cache and works offline — while the remote handles writes and refresh.
    if (client.auth.currentSession != null) {
      listingRepository = CachedSyncedListingRepository(
        cache: listingRepository,
        remote: SupabaseListingSource(client),
      );
    } else {
      backendReady = false;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        listingRepositoryProvider.overrideWithValue(listingRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        storageAvailableProvider.overrideWithValue(storageAvailable),
        backendReadyProvider.overrideWithValue(backendReady),
      ],
      child: const MangWaloApp(),
    ),
  );
}

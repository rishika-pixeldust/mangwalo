// Demo/preview frame capture. NOT part of the regular test suite (lives
// outside test/), run explicitly:
//
//   flutter test tool/demo/capture_screens_test.dart --update-goldens
//
// Renders real app screens at 3x phone resolution with real fonts and
// writes them to tool/demo/goldens/*.png for the demo video + preview
// gallery pipeline.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/clock.dart';
import 'package:mangwalo/src/features/home/home_shell.dart';
import 'package:mangwalo/src/features/listings/application/listing_providers.dart';
import 'package:mangwalo/src/features/listings/data/in_memory_listing_repository.dart';
import 'package:mangwalo/src/features/listings/data/seed_data.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';
import 'package:mangwalo/src/features/listings/ui/feed_screen.dart';
import 'package:mangwalo/src/features/listings/ui/listing_detail_screen.dart';
import 'package:mangwalo/src/features/listings/ui/listing_form_screen.dart';
import 'package:mangwalo/src/features/onboarding/intro_screen.dart';
import 'package:mangwalo/src/features/onboarding/onboarding_screen.dart';
import 'package:mangwalo/src/features/settings/application/settings_controller.dart';
import 'package:mangwalo/src/features/settings/data/hive_settings_repository.dart';
import 'package:mangwalo/src/features/settings/domain/app_settings.dart';
import 'package:mangwalo/src/theme/app_theme.dart';

const _sdkFonts =
    '/Users/rishika/Documents/development/flutter/bin/cache/artifacts/material_fonts';
const _appFonts = '/Users/rishika/StudioProjects/mal/assets/fonts';

Future<void> _loadFonts() async {
  Future<ByteData> read(String path) async {
    final bytes = await File(path).readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  final jakarta = FontLoader('PlusJakartaSans')
    ..addFont(read('$_appFonts/PlusJakartaSans-Regular.ttf'))
    ..addFont(read('$_appFonts/PlusJakartaSans-Medium.ttf'))
    ..addFont(read('$_appFonts/PlusJakartaSans-SemiBold.ttf'))
    ..addFont(read('$_appFonts/PlusJakartaSans-Bold.ttf'))
    ..addFont(read('$_appFonts/PlusJakartaSans-ExtraBold.ttf'));
  await jakarta.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(read('$_sdkFonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

final _now = DateTime(2026, 7, 13, 10, 0);

Future<String?> _filePhotoLoader(String assetPath) async {
  try {
    final bytes =
        await File('/Users/rishika/StudioProjects/mal/$assetPath').readAsBytes();
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}

Future<Listing> _mine() async => Listing(
      id: 'mine-1',
      type: ListingType.offer,
      title: 'Gucci Marmont shoulder bag',
      description:
          'gucci marmont shoulder bag, barely used, with dust bag. '
          'weekends only.',
      category: Category.designerBags,
      conditionTags: const ['Gently used'],
      area: 'Near Bandra Talao',
      neighborhood: 'Bandra West',
      pricePerDayInr: 5000,
      depositInr: 20000,
      lendingState: LendingState.lentOut,
      dueDate: DateTime(2026, 7, 18),
      borrowerName: 'Priya',
      suggestedDurationDays: 7,
      photos: [(await _filePhotoLoader('assets/seed/bag_lv.jpg')) ?? ''],
      reviews: [
        Review(
          rating: 5,
          text: 'Gorgeous bag, pickup was effortless.',
          reviewerName: 'Meher',
          createdAt: DateTime(2026, 7, 2),
        ),
      ],
      createdAt: _now,
      updatedAt: _now,
      isMine: true,
    );

Widget _app(
  Widget home, {
  required InMemoryListingRepository repo,
  double textScale = 1.0,
  ThemeMode mode = ThemeMode.light,
}) {
  final settingsRepo = InMemorySettingsRepository();
  settingsRepo.save(const AppSettings(
      neighborhood: 'Bandra West',
      displayName: 'Rishika',
      introSeen: true,
      seedVersion: 1));
  return ProviderScope(
    overrides: [
      listingRepositoryProvider.overrideWithValue(repo),
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      nowProvider.overrideWithValue(() => _now),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

Future<InMemoryListingRepository> _board({bool withMine = true}) async =>
    InMemoryListingRepository([
      ...await buildSampleListings(
          neighborhood: 'Bandra West',
          now: _now,
          photoLoader: _filePhotoLoader),
      if (withMine) await _mine(),
    ]);

void main() {
  setUpAll(_loadFonts);

  void frame(WidgetTester tester) {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester, {int pumps = 3}) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 140));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

  testWidgets('00 intro', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const IntroScreen(), repo: await _board()));
    await settle(tester);
    await shoot(tester, '00_intro');
  });

  testWidgets('01 onboarding', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const OnboardingScreen(), repo: await _board()));
    await settle(tester);
    await shoot(tester, '01_onboarding');
  });

  testWidgets('02 board feed', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const HomeShell(), repo: await _board()));
    await settle(tester);
    await shoot(tester, '02_feed');
  });

  testWidgets('03 my items + hero', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const HomeShell(), repo: await _board()));
    await settle(tester);
    await tester.tap(find.text('My items'));
    await settle(tester);
    await shoot(tester, '03_myitems');
  });

  testWidgets('04 AI suggestions', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const ListingFormScreen(), repo: await _board()));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first,
        'chanel ka flap bag hai, barely used, with dust bag. weekends only');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    await shoot(tester, '04_ai_suggestions');
  });

  testWidgets('05 privacy warnings', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const ListingFormScreen(), repo: await _board()));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first,
        'kundan necklace set for rent, call me on 98200 12345, flat no 402');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    await shoot(tester, '05_privacy_warning');
  });

  testWidgets('06 lending detail', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(
        const ListingDetailScreen(listingId: 'mine-1'),
        repo: await _board()));
    await settle(tester);
    await shoot(tester, '06_detail_lending');
  });

  testWidgets('07 text scale', (tester) async {
    frame(tester);
    await tester.pumpWidget(
        _app(const FeedScreen(), repo: await _board(), textScale: 1.8));
    await settle(tester);
    await shoot(tester, '07_a11y_scale');
  });

  testWidgets('08 settings', (tester) async {
    frame(tester);
    await tester.pumpWidget(_app(const HomeShell(), repo: await _board()));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    await shoot(tester, '08_settings');
  });

  testWidgets('09 board feed dark', (tester) async {
    frame(tester);
    await tester.pumpWidget(
        _app(const HomeShell(), repo: await _board(), mode: ThemeMode.dark));
    await settle(tester);
    await shoot(tester, '09_feed_dark');
  });
}

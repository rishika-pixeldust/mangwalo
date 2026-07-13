// Demo-video frame capture. NOT part of the regular test suite (lives
// outside test/), run explicitly:
//
//   flutter test tool/demo/capture_screens_test.dart --update-goldens
//
// Renders real app screens at 3x phone resolution with real fonts and
// writes them to tool/demo/goldens/*.png for the demo video pipeline.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/clock.dart';
import 'package:mangwalo/src/features/listings/application/listing_providers.dart';
import 'package:mangwalo/src/features/listings/data/in_memory_listing_repository.dart';
import 'package:mangwalo/src/features/listings/data/seed_data.dart';
import 'package:mangwalo/src/features/listings/domain/listing.dart';
import 'package:mangwalo/src/features/listings/ui/feed_screen.dart';
import 'package:mangwalo/src/features/listings/ui/listing_detail_screen.dart';
import 'package:mangwalo/src/features/listings/ui/listing_form_screen.dart';
import 'package:mangwalo/src/features/onboarding/onboarding_screen.dart';
import 'package:mangwalo/src/features/settings/application/settings_controller.dart';
import 'package:mangwalo/src/features/settings/data/hive_settings_repository.dart';
import 'package:mangwalo/src/features/settings/domain/app_settings.dart';
import 'package:mangwalo/src/features/settings/ui/settings_screen.dart';
import 'package:mangwalo/src/theme/app_theme.dart';

const _fontDir =
    '/Users/rishika/Documents/development/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  Future<ByteData> read(String file) async {
    final bytes = await File('$_fontDir/$file').readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'))
    ..addFont(read('Roboto-Light.ttf'));
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

final _now = DateTime(2026, 7, 13, 10, 0);

Listing _mine() => Listing(
      id: 'mine-1',
      type: ListingType.offer,
      title: 'Yonex Badminton Racket',
      description:
          'yonex badminton racket, barely used, happy to lend on weekends',
      category: Category.sportsFitness,
      conditionTags: const ['Gently used'],
      area: 'Near Bandra Talao',
      neighborhood: 'Bandra West',
      lendingState: LendingState.lentOut,
      dueDate: DateTime(2026, 7, 20),
      borrowerName: 'Priya',
      suggestedDurationDays: 7,
      createdAt: _now,
      updatedAt: _now,
      isMine: true,
    );

Widget _app(Widget home,
    {required InMemoryListingRepository repo, double textScale = 1.0}) {
  final settingsRepo = InMemorySettingsRepository();
  settingsRepo.save(
      const AppSettings(neighborhood: 'Bandra West', seedVersion: 1));
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
      themeMode: ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

InMemoryListingRepository _board({bool withMine = false}) =>
    InMemoryListingRepository([
      ...buildSampleListings(neighborhood: 'Bandra West', now: _now),
      if (withMine) _mine(),
    ]);

void main() {
  setUpAll(_loadFonts);

  Future<void> capture(WidgetTester tester, Widget widget, String name,
      {int settles = 3}) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    for (var i = 0; i < settles; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('01 onboarding', (tester) async {
    await capture(
        tester, _app(const OnboardingScreen(), repo: _board()), '01_onboarding');
  });

  testWidgets('02 feed', (tester) async {
    await capture(
        tester, _app(const FeedScreen(), repo: _board(withMine: true)),
        '02_feed');
  });

  testWidgets('03 my items', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        _app(const FeedScreen(), repo: _board(withMine: true)));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('My items'));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/03_myitems.png'));
  });

  testWidgets('04 AI suggestions', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ListingFormScreen(), repo: _board()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.enterText(find.byType(TextFormField).first,
        'bosch ka drill machine, thoda purana but works fine, weekends only');
    // Ride out the 450 ms suggestion debounce.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/04_ai_suggestions.png'));
  });

  testWidgets('05 privacy warnings', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ListingFormScreen(), repo: _board()));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.enterText(find.byType(TextFormField).first,
        'mixer grinder available, call me on 98200 12345, flat no 402');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/05_privacy_warning.png'));
  });

  testWidgets('06 lending detail', (tester) async {
    await capture(
        tester,
        _app(const ListingDetailScreen(listingId: 'mine-1'),
            repo: _board(withMine: true)),
        '06_detail_lending');
  });

  testWidgets('07 text scale 2x', (tester) async {
    await capture(
        tester,
        _app(const FeedScreen(), repo: _board(withMine: true),
            textScale: 1.8),
        '07_a11y_scale');
  });

  testWidgets('08 settings / data control', (tester) async {
    await capture(
        tester, _app(const SettingsScreen(), repo: _board()), '08_settings');
  });
}

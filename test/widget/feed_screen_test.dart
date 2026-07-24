import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangwalo/src/core/clock.dart';
import 'package:mangwalo/src/features/listings/application/listing_providers.dart';
import 'package:mangwalo/src/features/listings/data/in_memory_listing_repository.dart';
import 'package:mangwalo/src/features/listings/data/seed_data.dart';
import 'package:mangwalo/src/features/listings/ui/feed_screen.dart';
import 'package:mangwalo/src/features/settings/application/settings_controller.dart';
import 'package:mangwalo/src/features/settings/data/hive_settings_repository.dart';
import 'package:mangwalo/src/features/settings/domain/app_settings.dart';

void main() {
  final pinnedNow = DateTime(2026, 7, 13, 10, 0);

  Future<InMemorySettingsRepository> settingsRepo() async {
    final repo = InMemorySettingsRepository();
    await repo.save(
        const AppSettings(neighborhood: 'Bandra West', seedVersion: 1));
    return repo;
  }

  Widget app(InMemoryListingRepository listings,
      InMemorySettingsRepository settings,
      {double textScale = 1.0}) {
    return ProviderScope(
      overrides: [
        listingRepositoryProvider.overrideWithValue(listings),
        settingsRepositoryProvider.overrideWithValue(settings),
        nowProvider.overrideWithValue(() => pinnedNow),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const FeedScreen(),
      ),
    );
  }

  testWidgets('renders seeded listings with prices and due badges',
      (tester) async {
    final listings = InMemoryListingRepository(await buildSampleListings(
        neighborhood: 'Bandra West', now: pinnedNow));
    await tester.pumpWidget(app(listings, await settingsRepo()));
    await tester.pumpAndSettle();

    // Overdue rental sorts to the very top; price pill is bold on the card.
    expect(find.text('Chanel Classic Flap bag'), findsOneWidget);
    expect(find.textContaining('₹4,800'), findsWidgets);
    expect(find.textContaining('Overdue by 5 days'), findsOneWidget);
    expect(find.textContaining('Bandra West'), findsOneWidget);
  });

  testWidgets('each listing card is one merged semantics node',
      (tester) async {
    final handle = tester.ensureSemantics();
    final listings = InMemoryListingRepository(await buildSampleListings(
        neighborhood: 'Bandra West', now: pinnedNow));
    await tester.pumpWidget(app(listings, await settingsRepo()));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(
          r'For rent: Chanel Classic Flap bag, ₹4,800/day.*'
          r'rented out, rented by Kiara, overdue by 5 days')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('empty feed offers sample-data action', (tester) async {
    final settings = InMemorySettingsRepository();
    await settings.save(const AppSettings(neighborhood: 'Powai'));
    await tester.pumpWidget(app(InMemoryListingRepository(), settings));
    await tester.pumpAndSettle();

    expect(find.text('Your noticeboard is waiting'), findsOneWidget);
    expect(find.text('Load sample listings'), findsOneWidget);
  });

  testWidgets('feed survives 200% text scale without overflow',
      (tester) async {
    final listings = InMemoryListingRepository(await buildSampleListings(
        neighborhood: 'Bandra West', now: pinnedNow));
    await tester.pumpWidget(
        app(listings, await settingsRepo(), textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

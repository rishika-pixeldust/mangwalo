import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';
import '../../settings/application/settings_controller.dart';
import '../application/feed_filter_controller.dart';
import '../application/listing_providers.dart';
import 'listing_card.dart';
import 'listing_detail_screen.dart';
import 'widgets/filter_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final filtered = ref.watch(filteredListingsProvider);
    final all = ref.watch(listingsProvider);
    final filter = ref.watch(feedFilterProvider);
    final storageAvailable = ref.watch(storageAvailableProvider);
    final now = ref.watch(nowProvider)();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!storageAvailable)
              Container(
                width: double.infinity,
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Browser storage unavailable — changes will not '
                        'survive a refresh.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filter.mineOnly ? 'My items' : 'Noticeboard',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${settings.neighborhood ?? 'Your neighborhood'}'
                                ' · maang lo, luxury nearby',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _SquareIconBadge(
                    icon: Icons.storefront_outlined,
                    semanticLabel: 'MangWalo — ${settings.neighborhood ?? ''}',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: TextField(
                onChanged: ref.read(feedFilterProvider.notifier).setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title, description, or landmark',
                  isDense: true,
                ),
              ),
            ),
            const FilterBar(),
            if (filter.mineOnly)
              _LendingHeroCard(listings: all.value ?? const [], now: now),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load listings',
                  message: 'Something went wrong reading local storage. '
                      'Try Settings → Reset all local data.',
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    if (filter.mineOnly &&
                        !(all.value ?? []).any((l) => l.isMine)) {
                      return const EmptyState(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Nothing of yours here yet',
                        message:
                            'Add something you can lend, or ask for what '
                            'you need — your padosi will thank you.',
                      );
                    }
                    final nothingAtAll = (all.value ?? []).isEmpty;
                    if (nothingAtAll) {
                      return EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'Your noticeboard is waiting',
                        message: 'Maang lo! Ask for what you need, or lend a '
                            'hand — start with the orange button below.',
                        actionLabel: settings.seedVersion == 0
                            ? 'Load sample listings'
                            : null,
                        onAction: settings.seedVersion == 0
                            ? () => ref
                                .read(settingsProvider.notifier)
                                .loadSamples()
                            : null,
                      );
                    }
                    return EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No matches',
                      message:
                          'Nothing matches the current search and filters.',
                      actionLabel: filter.isDefault ? null : 'Clear filters',
                      onAction: filter.isDefault
                          ? null
                          : () =>
                              ref.read(feedFilterProvider.notifier).reset(),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return ListingCard(
                        listing: listing,
                        now: now,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailScreen(listingId: listing.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44px white rounded-square icon — the Warm Ledger top-bar accessory.
class _SquareIconBadge extends StatelessWidget {
  const _SquareIconBadge({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 22, color: scheme.primary),
        ),
      ),
    );
  }
}

/// Hero stat card on the My-items view: big numeral + segmented meter,
/// the Warm Ledger take on "1250 kcal · goal 2000".
class _LendingHeroCard extends StatelessWidget {
  const _LendingHeroCard({required this.listings, required this.now});

  final List<Listing> listings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = listings.where((l) => l.isMine).toList();
    if (mine.isEmpty) return const SizedBox.shrink();
    final lentOut =
        mine.where((l) => l.lendingState == LendingState.lentOut).toList();
    final overdue = lentOut
        .where((l) =>
            l.dueDate != null && computeDueInfo(l.dueDate!, now).isOverdue)
        .length;

    final caption = lentOut.isEmpty
        ? 'everything is home'
        : overdue > 0
            ? '$overdue overdue · ${lentOut.length - overdue} on track'
            : 'all on track';

    const segments = 10;
    final lentFrac = lentOut.length / mine.length;
    final overdueFrac = lentOut.isEmpty ? 0.0 : overdue / mine.length;
    final overdueSegs = (overdueFrac * segments).ceil();
    final lentSegs =
        (lentFrac * segments).ceil().clamp(overdueSegs, segments);

    return Semantics(
      label: '${lentOut.length} of ${mine.length} items lent out, $caption.',
      container: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${lentOut.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, height: 1.0),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'of ${mine.length} items out',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      overdue > 0
                          ? Icons.warning_amber_rounded
                          : Icons.swap_horiz,
                      size: 20,
                      color: overdue > 0 ? scheme.error : scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      caption,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: overdue > 0 ? scheme.error : scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < segments; i++) ...[
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: i < overdueSegs
                                ? scheme.error
                                : i < lentSegs
                                    ? scheme.primary
                                    : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      if (i != segments - 1) const SizedBox(width: 5),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

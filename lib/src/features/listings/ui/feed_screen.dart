import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/ui/settings_screen.dart';
import '../application/feed_filter_controller.dart';
import '../application/listing_providers.dart';
import 'listing_card.dart';
import 'listing_detail_screen.dart';
import 'listing_form_screen.dart';
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
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ListingFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
      ),
      body: Column(
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
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${settings.neighborhood ?? 'Your'} noticeboard',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Noticeboard'),
                    icon: Icon(Icons.storefront_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('My items'),
                    icon: Icon(Icons.person_outline),
                  ),
                ],
                selected: {filter.mineOnly},
                onSelectionChanged: (selection) => ref
                    .read(feedFilterProvider.notifier)
                    .setMineOnly(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              onChanged:
                  ref.read(feedFilterProvider.notifier).setQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title, description, or landmark',
                isDense: true,
              ),
            ),
          ),
          const FilterBar(),
          if (filter.mineOnly)
            _LendingSummary(listings: all.value ?? const [], now: now),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                      message: 'Add something you can lend, or ask for what '
                          'you need — your padosi will thank you.',
                    );
                  }
                  final nothingAtAll = (all.value ?? []).isEmpty;
                  if (nothingAtAll) {
                    return EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Your noticeboard is waiting',
                      message: 'Maang lo! Ask for what you need, or lend a '
                          'hand — start with the button below.',
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
                  padding: const EdgeInsets.only(bottom: 96),
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
    );
  }
}

/// "You've lent 2 items · 1 overdue" strip shown on the My-items view.
class _LendingSummary extends StatelessWidget {
  const _LendingSummary({required this.listings, required this.now});

  final List<Listing> listings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lentOut = listings
        .where((l) => l.isMine && l.lendingState == LendingState.lentOut)
        .toList();
    if (lentOut.isEmpty) return const SizedBox.shrink();
    final overdue = lentOut
        .where((l) =>
            l.dueDate != null && computeDueInfo(l.dueDate!, now).isOverdue)
        .length;

    final text = overdue > 0
        ? 'You\'ve lent ${lentOut.length} '
            '${lentOut.length == 1 ? 'item' : 'items'} · '
            '$overdue overdue'
        : 'You\'ve lent ${lentOut.length} '
            '${lentOut.length == 1 ? 'item' : 'items'} — all on track';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: overdue > 0
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              overdue > 0 ? Icons.warning_amber_rounded : Icons.swap_horiz,
              size: 18,
              color: overdue > 0
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: overdue > 0
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

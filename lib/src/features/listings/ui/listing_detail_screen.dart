import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/widgets/due_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/listing_providers.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';
import 'listing_form_screen.dart';
import 'widgets/lend_out_dialog.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('"${listing.title}" will be removed from this device. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(listingRepositoryProvider).delete(listing.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listing = ref.watch(listingByIdProvider(listingId));
    final now = ref.watch(nowProvider)();

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This listing no longer exists.')),
      );
    }

    final repo = ref.read(listingRepositoryProvider);
    final due = listing.dueDate == null
        ? null
        : computeDueInfo(listing.dueDate!, now);
    final dateFormat = DateFormat('d MMM yyyy');

    Widget infoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
            ),
            Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing'),
        actions: [
          IconButton(
            tooltip: 'Edit listing',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingFormScreen(listingId: listing.id),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete listing',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, listing),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (listing.photoBase64 != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Semantics(
                label: 'Photo of ${listing.title}',
                image: true,
                child: Image.memory(
                  base64Decode(listing.photoBase64!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge.type(listing.type),
              if (listing.isDemo) const StatusBadge.sample(),
              StatusBadge.lending(listing.lendingState),
              if (due != null) DueBadge(info: due, compact: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            listing.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(listing.description, style: theme.textTheme.bodyLarge),
          if (listing.conditionTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in listing.conditionTags)
                  Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  infoRow(Icons.category_outlined, 'Category',
                      listing.category.label),
                  infoRow(Icons.place_outlined, 'Landmark', listing.area),
                  infoRow(Icons.location_city_outlined, 'Neighborhood',
                      listing.neighborhood),
                  infoRow(Icons.forum_outlined, 'Contact',
                      listing.contactChannel.label),
                  if (listing.contactNote.isNotEmpty)
                    infoRow(Icons.sticky_note_2_outlined, 'Note',
                        listing.contactNote),
                  infoRow(Icons.calendar_today_outlined, 'Posted',
                      dateFormat.format(listing.createdAt)),
                  if (listing.borrowerName.isNotEmpty)
                    infoRow(Icons.person_outline, 'Borrowed by',
                        listing.borrowerName),
                  if (listing.dueDate != null)
                    infoRow(Icons.event_outlined, 'Return by',
                        dateFormat.format(listing.dueDate!)),
                  if (listing.returnedAt != null)
                    infoRow(Icons.keyboard_return, 'Returned',
                        dateFormat.format(listing.returnedAt!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<InteractionStatus>(
              segments: [
                for (final s in InteractionStatus.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {listing.status},
              // The clock is read inside every action callback — a detail
              // screen can sit open for hours, so build-time `now` is only
              // for display.
              onSelectionChanged: (selection) => repo.put(
                listing.copyWith(
                  status: selection.first,
                  updatedAt: ref.read(nowProvider)(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Lending', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (listing.lendingState != LendingState.lentOut)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Mark as lent out'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final actionNow = ref.read(nowProvider)();
                final result = await showLendOutDialog(
                  context,
                  now: actionNow,
                  suggestedDays: listing.suggestedDurationDays,
                );
                if (result != null) {
                  await repo.put(listing.markLentOut(
                    result.dueDate,
                    ref.read(nowProvider)(),
                    borrowerName: result.borrowerName,
                  ));
                }
              },
            )
          else ...[
            FilledButton.icon(
              icon: const Icon(Icons.keyboard_return),
              label: const Text('Mark as returned'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () =>
                  repo.put(listing.markReturned(ref.read(nowProvider)())),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: const Text('Update lending details'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final actionNow = ref.read(nowProvider)();
                final result = await showLendOutDialog(
                  context,
                  now: actionNow,
                  suggestedDays: due?.days.clamp(0, 365),
                  initialBorrowerName: listing.borrowerName,
                );
                if (result != null) {
                  await repo.put(listing.markLentOut(
                    result.dueDate,
                    ref.read(nowProvider)(),
                    borrowerName: result.borrowerName,
                  ));
                }
              },
            ),
          ],
          if (listing.lendingState == LendingState.returned) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Mark as available again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () =>
                  repo.put(listing.markAvailable(ref.read(nowProvider)())),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

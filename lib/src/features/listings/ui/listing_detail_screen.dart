import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/due_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../settings/application/settings_controller.dart';
import '../application/listing_providers.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';
import 'listing_form_screen.dart';
import 'widgets/add_review_sheet.dart';
import 'widgets/lend_out_dialog.dart';
import 'widgets/photo_gallery.dart';
import 'widgets/star_row.dart';

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
    final scheme = theme.colorScheme;
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
    final rating = listing.averageRating;

    Widget infoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    Widget sectionCard(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        );

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
          if (listing.photos.isNotEmpty) ...[
            PhotoGallery(
              photos: listing.photos,
              title: listing.title,
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge.type(listing.type),
              if (listing.isDemo) const StatusBadge.sample(),
              if (listing.lendingState != LendingState.available)
                StatusBadge.lending(listing.lendingState),
              if (listing.status != InteractionStatus.saved)
                StatusBadge.status(listing.status),
              if (due != null) DueBadge(info: due, compact: false),
            ],
          ),
          const SizedBox(height: 10),
          Text(listing.title, style: theme.textTheme.headlineSmall),
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: StarRow(
                rating: rating,
                caption: '${rating.toStringAsFixed(1)} · '
                    '${listing.reviews.length} '
                    '${listing.reviews.length == 1 ? 'review' : 'reviews'}',
              ),
            ),
          const SizedBox(height: 8),
          Text(listing.description, style: theme.textTheme.bodyMedium),
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
          // Price block — the headline number of a rental listing.
          Semantics(
            container: true,
            label: listing.type == ListingType.request
                ? 'Budget ${formatInrPerDay(listing.pricePerDayInr)}.'
                : 'Rate ${formatInrPerDay(listing.pricePerDayInr)}'
                    '${listing.depositInr != null ? ', refundable deposit '
                        '${formatInr(listing.depositInr!)}' : ''}.',
            child: ExcludeSemantics(
              child: sectionCard(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatInr(listing.pricePerDayInr),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        listing.type == ListingType.request
                            ? '/day budget'
                            : 'per day',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    if (listing.depositInr != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatInr(listing.depositInr!),
                              style: theme.textTheme.titleMedium),
                          Text('refundable deposit',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          sectionCard(
            Column(
              children: [
                infoRow(listing.category.icon, 'Category',
                    listing.categoryLabel),
                infoRow(Icons.place_outlined, 'Landmark', listing.area),
                infoRow(Icons.location_city_outlined, 'Locality',
                    listing.neighborhood),
                infoRow(Icons.event_outlined, 'Posted',
                    dateFormat.format(listing.createdAt)),
                if (listing.borrowerName.isNotEmpty)
                  infoRow(Icons.person_outline, 'Rented by',
                      listing.borrowerName),
                if (listing.dueDate != null)
                  infoRow(Icons.event_repeat_outlined, 'Return by',
                      dateFormat.format(listing.dueDate!)),
              ],
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
          Text('Rental', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (listing.lendingState != LendingState.lentOut)
            FilledButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Mark as rented out'),
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
              onPressed: () =>
                  repo.put(listing.markReturned(ref.read(nowProvider)())),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: const Text('Update rental details'),
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
              onPressed: () =>
                  repo.put(listing.markAvailable(ref.read(nowProvider)())),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Reviews', style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Add a review'),
                onPressed: () async {
                  final review = await showAddReviewSheet(
                    context,
                    now: ref.read(nowProvider)(),
                    initialName: ref.read(settingsProvider).displayName,
                  );
                  if (review != null) {
                    await repo.put(
                        listing.addReview(review, ref.read(nowProvider)()));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (listing.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No reviews yet — the first renter\'s feedback will '
                'appear here.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final review in listing.reviews) ...[
              Semantics(
                container: true,
                label: '${review.rating} of 5 stars by '
                    '${review.reviewerName.isEmpty ? 'a renter' : review.reviewerName}: '
                    '${review.text}',
                child: ExcludeSemantics(
                  child: sectionCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRow(rating: review.rating.toDouble()),
                        const SizedBox(height: 6),
                        Text(review.text,
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text(
                          '— ${review.reviewerName.isEmpty ? 'A renter' : review.reviewerName}'
                          ' · ${dateFormat.format(review.createdAt)}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

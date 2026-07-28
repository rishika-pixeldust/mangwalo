import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../listings/application/listing_providers.dart';
import '../../listings/domain/due_info.dart';
import '../../listings/domain/listing.dart';
import '../../listings/ui/listing_detail_screen.dart';
import '../../listings/ui/widgets/star_row.dart';
import '../application/settings_controller.dart';

/// Who you are on the board: your name, the reputation neighbours have given
/// you, and what's currently out on loan.
///
/// Reputation matters more here than in most apps — a stranger decides whether
/// to hand over a ₹4,800/day bag based on it, so it gets a real screen rather
/// than a line in Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final all = ref.watch(listingsProvider).value ?? const <Listing>[];
    final now = ref.watch(nowProvider)();

    final mine = all.where((l) => l.isMine).toList();
    // Reviews left on your listings are, in effect, reviews of you.
    final aboutMe = [
      for (final l in mine)
        for (final r in l.reviews) (listing: l, review: r),
    ]..sort((a, b) => b.review.createdAt.compareTo(a.review.createdAt));
    final rating = aboutMe.isEmpty
        ? null
        : aboutMe.map((e) => e.review.rating).reduce((a, b) => a + b) /
            aboutMe.length;

    final onLoan = mine
        .where((l) => l.lendingState == LendingState.lentOut && l.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final name = settings.displayName.isEmpty ? 'You' : settings.displayName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    if (rating != null)
                      Row(
                        children: [
                          StarRow(rating: rating, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${rating.toStringAsFixed(1)} · '
                            '${aboutMe.length} review'
                            '${aboutMe.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No reviews yet',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Honest about the current stage: identity is local-only until the
          // account layer lands.
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.mail_outline, color: scheme.primary),
              title: const Text('Not signed in'),
              subtitle: const Text('Your profile lives on this device. '
                  'Signing in will let neighbours reach you.'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Out on loan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (onLoan.isEmpty)
            Text(
              'Nothing of yours is rented out right now.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            for (final l in onLoan)
              _LoanRow(listing: l, due: computeDueInfo(l.dueDate!, now)),
          const SizedBox(height: 24),
          Text('What neighbours say about you',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (aboutMe.isEmpty)
            const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              message: 'Once someone rents from you and leaves feedback, '
                  'it shows up here.',
            )
          else
            for (final entry in aboutMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StarRow(rating: entry.review.rating.toDouble(), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.review.reviewerName} · on '
                            '${entry.listing.title}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(entry.review.text, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.listing, required this.due});

  final Listing listing;
  final DueInfo due;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          due.isOverdue ? Icons.warning_amber_rounded : Icons.swap_horiz,
          color: due.isOverdue ? scheme.error : scheme.primary,
        ),
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          listing.borrowerName.isEmpty
              ? due.label
              : '${listing.borrowerName} · ${due.label}',
          style: due.isOverdue ? TextStyle(color: scheme.error) : null,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ListingDetailScreen(listingId: listing.id),
        )),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/due_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';
import '../../../theme/night_tokens.dart';

/// Feed card, Velvet Ledger style: cover photo with a price pill when the
/// listing has imagery, serif title, star rating, and state badges. The
/// entire card is ONE semantics node with a composed label.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.now,
    required this.onTap,
  });

  final Listing listing;
  final DateTime now;
  final VoidCallback onTap;

  String _semanticLabel(DueInfo? due) {
    final rating = listing.averageRating;
    final parts = <String>[
      '${listing.type.label}: ${listing.title}',
      listing.type == ListingType.request
          ? '${formatInrPerDay(listing.pricePerDayInr)} budget'
          : formatInrPerDay(listing.pricePerDayInr),
      if (rating != null)
        'rated ${rating.toStringAsFixed(1)} of 5 from '
            '${listing.reviews.length} '
            '${listing.reviews.length == 1 ? 'review' : 'reviews'}',
      listing.category.label,
      listing.area,
    ];
    if (listing.photos.isNotEmpty) {
      parts.add('${listing.photos.length} '
          '${listing.photos.length == 1 ? 'photo' : 'photos'}');
    }
    if (listing.lendingState != LendingState.available) {
      parts.add(listing.lendingState.label.toLowerCase());
    }
    if (listing.borrowerName.isNotEmpty) {
      parts.add('rented by ${listing.borrowerName}');
    }
    if (due != null) parts.add(due.label.toLowerCase());
    if (listing.status != InteractionStatus.saved) {
      parts.add(listing.status.label.toLowerCase());
    }
    if (listing.isMine) parts.add('your listing');
    if (listing.isDemo) parts.add('sample listing');
    return '${parts.join(', ')}.';
  }

  Widget _pricePill(BuildContext context) {
    final night = nightTokensOf(context);
    final theme = Theme.of(context);
    final isRequest = listing.type == ListingType.request;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: night.night.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: formatInr(listing.pricePerDayInr),
            style: theme.textTheme.titleSmall?.copyWith(
                color: night.onNight, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: isRequest ? '/day budget' : '/day',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: night.onNight.withValues(alpha: 0.8)),
          ),
        ]),
      ),
    );
  }

  Widget _stars(ThemeData theme) {
    final rating = listing.averageRating;
    if (rating == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 3),
          Text(
            '${rating.toStringAsFixed(1)} · ${listing.reviews.length} '
            '${listing.reviews.length == 1 ? 'review' : 'reviews'}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final due = listing.dueDate == null
        ? null
        : computeDueInfo(listing.dueDate!, now);
    final cover = listing.coverPhoto;
    final showBadges = listing.isDemo ||
        listing.lendingState != LendingState.available ||
        listing.status != InteractionStatus.saved ||
        due != null;

    return Semantics(
      button: true,
      label: _semanticLabel(due),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cover != null)
                  Stack(
                    children: [
                      Image.memory(
                        base64Decode(cover),
                        height: 172,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                      Positioned(left: 12, bottom: 12, child: _pricePill(context)),
                      if (listing.photos.length > 1)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${listing.photos.length}',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cover == null) ...[
                            CategoryAvatar(category: listing.category),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.type.label.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    fontSize: 10.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  listing.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 19, height: 1.15),
                                ),
                                _stars(theme),
                              ],
                            ),
                          ),
                          if (cover == null) ...[
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatInr(listing.pricePerDayInr),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontFamily: 'PlusJakartaSans',
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  listing.type == ListingType.request
                                      ? '/day budget'
                                      : 'per day',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(listing.category.icon,
                              size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              listing.category.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.place_outlined,
                              size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              listing.area,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (showBadges) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (listing.isDemo) const StatusBadge.sample(),
                            if (listing.lendingState !=
                                LendingState.available)
                              StatusBadge.lending(listing.lendingState),
                            if (listing.status != InteractionStatus.saved)
                              StatusBadge.status(listing.status),
                            if (due != null) DueBadge(info: due),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

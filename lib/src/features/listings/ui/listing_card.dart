import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';

/// Feed card, Warm Ledger style: thumbnail left, orange type eyebrow +
/// bold title in the middle, bold due-value column on the right ("kcal
/// slot"). The entire card is ONE semantics node with a composed label.
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
    final parts = <String>[
      '${listing.type.label}: ${listing.title}',
      listing.category.label,
      listing.area,
    ];
    if (listing.photoBase64 != null) parts.add('has photo');
    if (listing.lendingState != LendingState.available) {
      parts.add(listing.lendingState.label.toLowerCase());
    }
    if (listing.borrowerName.isNotEmpty) {
      parts.add('borrowed by ${listing.borrowerName}');
    }
    if (due != null) parts.add(due.label.toLowerCase());
    if (listing.status != InteractionStatus.saved) {
      parts.add(listing.status.label.toLowerCase());
    }
    if (listing.isMine) parts.add('your listing');
    if (listing.isDemo) parts.add('sample listing');
    // No activation instruction in the label: button semantics already give
    // each platform's screen reader its own, correctly localized hint.
    return '${parts.join(', ')}.';
  }

  Widget _leading(ThemeData theme) {
    if (listing.photoBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          base64Decode(listing.photoBase64!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return CategoryAvatar(category: listing.category, size: 56);
  }

  /// The bold right-hand value column — due information when lent out.
  Widget? _valueColumn(ThemeData theme, DueInfo? due) {
    if (due == null) return null;
    final scheme = theme.colorScheme;
    final color = due.needsAttention ? scheme.error : scheme.primary;
    final big = due.isDueToday
        ? 'Today'
        : due.isOverdue
            ? '${due.days.abs()}d'
            : '${due.days}d';
    final caption = due.isOverdue ? 'overdue' : 'until return';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              due.needsAttention
                  ? Icons.warning_amber_rounded
                  : Icons.schedule,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 3),
            Text(
              big,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final due = listing.dueDate == null
        ? null
        : computeDueInfo(listing.dueDate!, now);
    final value = _valueColumn(theme, due);
    final showBadges = listing.isDemo ||
        listing.lendingState != LendingState.available ||
        listing.status != InteractionStatus.saved;

    return Semantics(
      button: true,
      label: _semanticLabel(due),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _leading(theme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.type.label.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700, height: 1.15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.description,
                              maxLines: value == null ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(width: 10),
                        value,
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          listing.category.label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
                        if (listing.lendingState != LendingState.available)
                          StatusBadge.lending(listing.lendingState),
                        if (listing.status != InteractionStatus.saved)
                          StatusBadge.status(listing.status),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

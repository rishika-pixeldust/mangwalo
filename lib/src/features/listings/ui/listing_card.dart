import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/due_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/due_info.dart';
import '../domain/listing.dart';

/// Feed card. The entire card is ONE semantics node with a composed,
/// meaningful label — a screen reader hears "Offer: Cricket bat… lent out,
/// due in 2 days", not five disconnected fragments.
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
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(listing.photoBase64!),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return CategoryAvatar(category: listing.category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = listing.dueDate == null
        ? null
        : computeDueInfo(listing.dueDate!, now);

    return Semantics(
      button: true,
      label: _semanticLabel(due),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge.type(listing.type),
                      if (listing.isDemo) const StatusBadge.sample(),
                      if (listing.lendingState != LendingState.available)
                        StatusBadge.lending(listing.lendingState),
                      if (listing.status != InteractionStatus.saved)
                        StatusBadge.status(listing.status),
                      if (due != null) DueBadge(info: due),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _leading(theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          listing.category.label,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.place_outlined,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          listing.area,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

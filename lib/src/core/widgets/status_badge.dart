import 'package:flutter/material.dart';

import '../../features/listings/domain/listing.dart';

/// Small tonal chip for a listing's type, status, or lending state.
class StatusBadge extends StatelessWidget {
  const StatusBadge._(this.text, this.icon, this.emphasis, {super.key});

  StatusBadge.type(ListingType type, {Key? key})
      : this._(
          type.label,
          type == ListingType.offer
              ? Icons.volunteer_activism_outlined
              : Icons.front_hand_outlined,
          type == ListingType.offer,
          key: key,
        );

  StatusBadge.status(InteractionStatus status, {Key? key})
      : this._(
          status.label,
          switch (status) {
            InteractionStatus.saved => Icons.bookmark_outline,
            InteractionStatus.contacted => Icons.chat_bubble_outline,
            InteractionStatus.closed => Icons.check_circle_outline,
          },
          false,
          key: key,
        );

  StatusBadge.lending(LendingState state, {Key? key})
      : this._(
          state.label,
          switch (state) {
            LendingState.available => Icons.inventory_2_outlined,
            LendingState.lentOut => Icons.swap_horiz,
            LendingState.returned => Icons.keyboard_return,
          },
          false,
          key: key,
        );

  const StatusBadge.sample({Key? key})
      : this._('Sample', Icons.science_outlined, false, key: key);

  final String text;
  final IconData icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = emphasis ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final fg = emphasis ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

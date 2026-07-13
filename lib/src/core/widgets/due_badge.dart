import 'package:flutter/material.dart';

import '../../features/listings/domain/due_info.dart';

/// "Due in N days" / "Overdue by N days" chip. Attention states use an icon
/// AND text — never color alone (accessibility requirement).
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.info, this.compact = true});

  final DueInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attention = info.needsAttention;
    final bg = attention ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = attention ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attention ? Icons.warning_amber_rounded : Icons.schedule,
            size: compact ? 14 : 18,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelLarge)
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

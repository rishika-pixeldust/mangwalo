import 'package:flutter/material.dart';

/// Five stars filled to [rating], gold on the Velvet palette, with an
/// optional caption. Purely visual — callers provide semantics.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.caption, this.size = 18});

  final double rating;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25
                ? Icons.star_rounded
                : rating >= i - 0.75
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: gold,
          ),
        if (caption != null) ...[
          const SizedBox(width: 6),
          Text(
            caption!,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

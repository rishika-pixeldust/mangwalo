import 'package:flutter/material.dart';

import '../../features/listings/domain/listing.dart';

/// Visual identity per catalog category — bundled Material icons (not
/// emoji): they render identically everywhere with zero runtime font
/// fetches, keeping the app fully local.
extension CategoryIcon on Category {
  IconData get icon => switch (this) {
        Category.designerBags => Icons.shopping_bag_outlined,
        Category.eventWear => Icons.checkroom_outlined,
        Category.partyWear => Icons.celebration_outlined,
        Category.sportsKits => Icons.sports_tennis_outlined,
        Category.jewellery => Icons.diamond_outlined,
        Category.watches => Icons.watch_outlined,
        Category.accessories => Icons.style_outlined,
      };
}

/// Rounded category tile used as the card visual when a listing has no
/// photos yet.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 52});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(category.icon,
          size: size * 0.5, color: scheme.onPrimaryContainer),
    );
  }
}

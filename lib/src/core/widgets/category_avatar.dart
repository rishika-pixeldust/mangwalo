import 'package:flutter/material.dart';

import '../../features/listings/domain/listing.dart';

/// Visual identity per category — feed cards scan faster with a glyph.
/// Bundled Material icons (not emoji): they render identically everywhere
/// with zero runtime font fetches, keeping the app fully local.
extension CategoryIcon on Category {
  IconData get icon => switch (this) {
        Category.toolsRepair => Icons.handyman_outlined,
        Category.kitchenAppliances => Icons.soup_kitchen_outlined,
        Category.booksStudy => Icons.menu_book_outlined,
        Category.sportsFitness => Icons.sports_tennis_outlined,
        Category.outdoorsTravel => Icons.landscape_outlined,
        Category.electronics => Icons.camera_alt_outlined,
        Category.musicInstruments => Icons.music_note_outlined,
        Category.kidsToys => Icons.toys_outlined,
        Category.festivalDecor => Icons.celebration_outlined,
        Category.homeFurniture => Icons.chair_outlined,
        Category.other => Icons.inventory_2_outlined,
      };
}

/// Rounded category tile used as the card leading visual when a listing has
/// no photo.
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

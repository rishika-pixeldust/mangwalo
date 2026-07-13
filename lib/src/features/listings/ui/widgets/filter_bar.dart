import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/feed_filter_controller.dart';
import '../../domain/listing.dart';

/// Type toggle + scrollable category chips + show-closed toggle.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedFilterProvider);
    final controller = ref.read(feedFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
              ButtonSegment(
                value: 1,
                label: Text('Offers'),
                icon: Icon(Icons.volunteer_activism_outlined),
              ),
              ButtonSegment(
                value: 2,
                label: Text('Requests'),
                icon: Icon(Icons.front_hand_outlined),
              ),
            ],
            selected: {
              switch (filter.type) {
                null => 0,
                ListingType.offer => 1,
                ListingType.request => 2,
              }
            },
            onSelectionChanged: (selection) => controller.setType(
              switch (selection.first) {
                1 => ListingType.offer,
                2 => ListingType.request,
                _ => null,
              },
            ),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.standard,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('All categories'),
                  selected: filter.category == null,
                  onSelected: (_) => controller.setCategory(null),
                ),
              ),
              for (final category in Category.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: filter.category == category,
                    onSelected: (selected) =>
                        controller.setCategory(selected ? category : null),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Show closed'),
                  selected: filter.showClosed,
                  onSelected: (_) => controller.toggleShowClosed(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

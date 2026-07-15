import 'package:flutter/material.dart';

import '../../theme/night_tokens.dart';

class NightNavDestination {
  const NightNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The dark docked bottom bar of the Warm Ledger design system: charcoal
/// slab with 28px top radii, icon destinations, and an orange rounded-square
/// center button for the primary action.
class NightNavBar extends StatelessWidget {
  const NightNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.centerIcon,
    required this.centerLabel,
    required this.onCenterPressed,
  });

  final List<NightNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final IconData centerIcon;
  final String centerLabel;
  final VoidCallback onCenterPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final night = nightTokensOf(context);

    Widget item(int index, NightNavDestination d) {
      final selected = index == selectedIndex;
      return Expanded(
        child: Semantics(
          label: d.label,
          button: true,
          selected: selected,
          onTap: () => onDestinationSelected(index),
          child: ExcludeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onDestinationSelected(index),
              child: SizedBox(
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        selected ? d.selectedIcon : d.icon,
                        size: 24,
                        color: selected
                            ? scheme.primary
                            : night.onNight.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            color: selected
                                ? scheme.primary
                                : night.onNight.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final left = destinations.sublist(0, (destinations.length / 2).ceil());
    final right = destinations.sublist((destinations.length / 2).ceil());

    return Container(
      decoration: BoxDecoration(
        color: night.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < left.length; i++) item(i, left[i]),
              // Center action: orange rounded-square, the bar's one accent.
              // Height MUST be bounded: Scaffold hands the nav bar loose
              // constraints, and an unbounded Center would expand the whole
              // bar to fill the screen.
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: Center(
                  child: Semantics(
                    label: centerLabel,
                    button: true,
                    onTap: onCenterPressed,
                    child: ExcludeSemantics(
                      child: Material(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onCenterPressed,
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: Icon(centerIcon,
                                size: 28, color: scheme.onPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              ),
              for (var i = 0; i < right.length; i++)
                item(left.length + i, right[i]),
            ],
          ),
        ),
      ),
    );
  }
}

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
/// slab with 28px top radii and icon destinations. The primary action is a
/// separate floating square (see [NightCenterAction]) docked over the bar's
/// top edge via Scaffold's centerDocked FAB location — the bar just leaves
/// a center gap for it.
class NightNavBar extends StatelessWidget {
  const NightNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NightNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

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

    // Destinations spread evenly — the middle one sits at screen center,
    // directly beneath the floating + action (see NightCenterAction, raised
    // above the bar's top edge by RaisedCenterDockedFabLocation).
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
              for (var i = 0; i < destinations.length; i++)
                item(i, destinations[i]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centers the FAB horizontally and floats it ABOVE the nav bar so only its
/// lower edge overlaps the slab — the destination beneath stays visible.
class RaisedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const RaisedCenterDockedFabLocation({this.lift = 20});

  /// How far above the centerDocked position (FAB center on the bar's top
  /// edge) the button rises.
  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base =
        FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
    return Offset(base.dx, base.dy - lift);
  }
}

/// The orange rounded-square primary action, floating over the nav bar's top
/// edge. Use as Scaffold.floatingActionButton with
/// [RaisedCenterDockedFabLocation].
class NightCenterAction extends StatelessWidget {
  const NightCenterAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(22),
          // Slight lift so the square reads above list content it overlaps.
          elevation: 3,
          shadowColor: scheme.shadow.withValues(alpha: 0.35),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, size: 30, color: scheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

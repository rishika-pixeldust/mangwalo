import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/night_nav_bar.dart';
import '../listings/application/feed_filter_controller.dart';
import '../listings/ui/feed_screen.dart';
import '../listings/ui/listing_form_screen.dart';
import '../settings/ui/settings_screen.dart';

/// Root navigation: Noticeboard / My items / Settings as destinations in the
/// dark docked bar, with the orange center square for "New listing".
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  void _select(int index) {
    setState(() => _index = index);
    if (index == 0 || index == 1) {
      ref.read(feedFilterProvider.notifier).setMineOnly(index == 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        2 => const SettingsScreen(),
        _ => const FeedScreen(),
      },
      bottomNavigationBar: NightNavBar(
        destinations: const [
          NightNavDestination(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            label: 'Board',
          ),
          NightNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'My items',
          ),
          NightNavDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
        selectedIndex: _index,
        onDestinationSelected: _select,
        centerIcon: Icons.add,
        centerLabel: 'New listing',
        onCenterPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ListingFormScreen()),
        ),
      ),
    );
  }
}

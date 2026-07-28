import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../listings/ui/feed_screen.dart';
import '../listings/ui/listing_form_screen.dart';
import '../onboarding/coach_marks.dart';
import '../settings/application/settings_controller.dart';

/// The board is the app. Profile and Settings live in the app-bar avatar menu
/// and "Mine" is a filter chip on the board itself, so there is nothing left
/// to navigate between — the "+" is the only global action.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Migration for anyone upgrading: loadSamples is a no-op unless the
    // stored seedVersion is behind, in which case the refreshed sample set
    // overwrites the old rows in place (ids are deterministic).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settingsProvider.notifier).loadSamples();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tutorialSeen = ref.watch(settingsProvider).tutorialSeen;

    return Scaffold(
      body: Stack(
        children: [
          const FeedScreen(),
          // First visit, or a replay from the avatar menu: teach on the real
          // board rather than explaining it before the user has seen it.
          if (!tutorialSeen) const CoachMarksOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ListingFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
        tooltip: 'Post a listing',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/application/settings_controller.dart';

/// A step in the on-board tour: what to point at, and what to say.
///
/// Positions are expressed as fractions of the board so the callout lands in
/// the right region at any phone size, without needing GlobalKeys threaded
/// through every widget it describes.
@immutable
class _Step {
  const _Step({
    required this.title,
    required this.body,
    required this.align,
    required this.icon,
  });

  final String title;
  final String body;

  /// Where the callout sits. The spotlight arrow points from here.
  final Alignment align;
  final IconData icon;
}

const _steps = <_Step>[
  _Step(
    icon: Icons.storefront_outlined,
    title: 'This is the noticeboard',
    body: 'Every card is something a neighbour in your locality will rent '
        'you — designer bags, event wear, jewellery, sports kits. The ₹ '
        'price is per day, and overdue rentals float to the top.',
    align: Alignment.center,
  ),
  _Step(
    icon: Icons.search,
    title: 'Search and filter',
    body: 'Search titles, descriptions and landmarks. The chips below narrow '
        'by offers or requests, by category — and once you pick a category, '
        'by sub-category too. "Mine" shows only your own listings.',
    align: Alignment.topCenter,
  ),
  _Step(
    icon: Icons.add,
    title: 'Post in seconds',
    body: 'Tap + and just describe the item in plain Hinglish. The on-device '
        'AI suggests a title, category, condition, rental window and a ₹/day '
        'rate — every suggestion is a chip you choose to apply.',
    align: Alignment.bottomCenter,
  ),
  _Step(
    icon: Icons.notifications_none_rounded,
    title: 'Requests come to the bell',
    body: 'When someone wants to rent your item, it lands here — and you can '
        'message them to arrange the handover.',
    align: Alignment.topRight,
  ),
  _Step(
    icon: Icons.person_outline,
    title: 'Your account lives here',
    body: 'The avatar opens your profile — your reviews and what is out on '
        'loan — plus Settings for locality, theme and your data. You can '
        'replay this tour any time from "How it works".',
    align: Alignment.topRight,
  ),
];

/// Dismissible spotlight tour shown over the real board on first visit.
///
/// Hand-rolled rather than a package: the app bundles everything and ships no
/// runtime dependencies it does not need.
class CoachMarksOverlay extends ConsumerStatefulWidget {
  const CoachMarksOverlay({super.key});

  @override
  ConsumerState<CoachMarksOverlay> createState() => _CoachMarksOverlayState();
}

class _CoachMarksOverlayState extends ConsumerState<CoachMarksOverlay> {
  int _index = 0;

  void _finish() =>
      ref.read(settingsProvider.notifier).markTutorialSeen();

  void _next() {
    if (_index >= _steps.length - 1) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    return Semantics(
      container: true,
      label: 'App tour, step ${_index + 1} of ${_steps.length}',
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: step.align,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: scheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step.icon,
                                  size: 20,
                                  color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(step.title,
                                  style: theme.textTheme.titleLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(step.body, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Progress dots double as the step counter.
                            for (var i = 0; i < _steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  width: i == _index ? 18 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: i == _index
                                        ? scheme.primary
                                        : scheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: _finish,
                              child: const Text('Skip'),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _next,
                              child: Text(isLast ? 'Got it' : 'Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

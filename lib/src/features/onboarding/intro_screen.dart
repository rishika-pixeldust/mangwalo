import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/application/settings_controller.dart';

class _IntroPage {
  const _IntroPage({
    required this.asset,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String asset;
  final String eyebrow;
  final String title;
  final String body;
}

const _pages = [
  _IntroPage(
    asset: 'assets/seed/bag_chanel.jpg',
    eyebrow: 'MAANG LO',
    title: 'Luxury, from\nyour locality.',
    body: 'The Chanel your reception outfit deserves lives two buildings '
        'away. Rent designer bags, event & party wear, jewellery, watches '
        'and sports kits — from neighbors, not couriers.',
  ),
  _IntroPage(
    asset: 'assets/seed/lehenga.jpg',
    eyebrow: 'PRICED · PICTURED · REVIEWED',
    title: 'Every listing\nearns your trust.',
    body: 'A clear ₹/day rate on every card, up to five photos to preview, '
        'a refundable deposit where it matters — and star reviews that '
        'speak to the item and the person.',
  ),
  _IntroPage(
    asset: 'assets/seed/jewellery.jpg',
    eyebrow: 'PRIVATE BY DESIGN',
    title: 'Yours stays\non your device.',
    body: 'No account servers, no tracking. An on-device helper drafts your '
        'listing — Hinglish welcome — landmarks replace addresses, and one '
        'tap erases everything.',
  ),
];

/// First-launch concept preview: three swipeable pages explaining what
/// MangWalo is, then onboarding. Skippable, and never shown again.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() =>
      ref.read(settingsProvider.notifier).markIntroSeen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Semantics(
                    label: 'Intro page ${i + 1} of ${_pages.length}: '
                        '${page.title.replaceAll('\n', ' ')}. ${page.body}',
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    page.asset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              page.eyebrow,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(page.title,
                                style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 12),
                            Text(
                              page.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(last ? Icons.arrow_forward : Icons.east),
                  label: Text(last ? 'Get started' : 'Next'),
                  onPressed: last
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

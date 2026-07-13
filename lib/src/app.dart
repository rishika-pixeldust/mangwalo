import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/widgets/phone_frame.dart';
import 'features/listings/ui/feed_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/application/settings_controller.dart';
import 'theme/app_theme.dart';

class MangWaloApp extends ConsumerWidget {
  const MangWaloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      // The frame wraps the Navigator, so every screen and dialog stays
      // phone-sized on desktop browsers.
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: settings.onboardingDone
          ? const FeedScreen()
          : const OnboardingScreen(),
    );
  }
}

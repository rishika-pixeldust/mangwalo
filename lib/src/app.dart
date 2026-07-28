import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/widgets/phone_frame.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/intro_screen.dart';
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
      darkTheme: AppTheme.dark(settings.darkVariant),
      themeMode: settings.themeMode,
      // The frame wraps the Navigator, so every screen and dialog stays
      // phone-sized on desktop browsers.
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
      // Concept intro → pick a locality → straight to the board. Signing in
      // is prompted later, only when an action actually needs an identity.
      home: !settings.introSeen
          ? const IntroScreen()
          : !settings.onboardingDone
              ? const OnboardingScreen()
              : const HomeShell(),
    );
  }
}

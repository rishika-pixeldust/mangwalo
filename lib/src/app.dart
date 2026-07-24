import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/widgets/phone_frame.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/intro_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/pin_gate_screen.dart';
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
      home: !settings.introSeen
          ? const IntroScreen()
          : !settings.onboardingDone
              ? const OnboardingScreen()
              : (settings.pinEnabled && !ref.watch(appUnlockedProvider))
                  ? const PinGateScreen()
                  : const HomeShell(),
    );
  }
}

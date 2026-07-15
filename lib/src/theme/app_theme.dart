import 'package:flutter/material.dart';

/// "Warm Ledger" design system (see docs/design-system.md): warm cream
/// canvas, near-white cards with 28px radii, one peach-orange accent,
/// charcoal ink, and a dark charcoal "night" tone for the bottom nav and
/// primary CTAs (mapped onto inverseSurface/onInverseSurface).
abstract final class AppTheme {
  // Light tokens
  static const _canvas = Color(0xFFF3EEE6);
  static const _surface = Color(0xFFFBF9F4);
  static const _surfaceAlt = Color(0xFFEFE8DD);
  static const _ink = Color(0xFF201B16);
  static const _inkSoft = Color(0xFF8A8178);
  static const _accent = Color(0xFFF2793C);
  static const _accentSoft = Color(0xFFFCE4D5);
  static const _onAccentSoft = Color(0xFF6B2E0F);
  static const _night = Color(0xFF211D19);
  static const _onNight = Color(0xFFF7F2EB);

  // Dark tokens
  static const _canvasD = Color(0xFF171310);
  static const _surfaceD = Color(0xFF221D18);
  static const _surfaceAltD = Color(0xFF2B241E);
  static const _inkD = Color(0xFFF4EEE7);
  static const _inkSoftD = Color(0xFFA99E93);
  static const _accentD = Color(0xFFF58B55);
  static const _accentSoftD = Color(0xFF4A2E1E);
  static const _onAccentSoftD = Color(0xFFFFDBC8);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final isLight = b == Brightness.light;
    return ColorScheme(
      brightness: b,
      primary: isLight ? _accent : _accentD,
      onPrimary: isLight ? Colors.white : const Color(0xFF3A1A08),
      primaryContainer: isLight ? _accentSoft : _accentSoftD,
      onPrimaryContainer: isLight ? _onAccentSoft : _onAccentSoftD,
      secondary: isLight ? const Color(0xFF6E5D4E) : const Color(0xFFD5C4B4),
      onSecondary: isLight ? Colors.white : const Color(0xFF2A2018),
      secondaryContainer: isLight ? _surfaceAlt : _surfaceAltD,
      onSecondaryContainer:
          isLight ? const Color(0xFF4A4036) : const Color(0xFFE5DACE),
      tertiary: isLight ? const Color(0xFF8A6D00) : const Color(0xFFF0D77B),
      onTertiary: isLight ? Colors.white : const Color(0xFF3A320A),
      tertiaryContainer:
          isLight ? const Color(0xFFF2E3AC) : const Color(0xFF4A3E12),
      onTertiaryContainer:
          isLight ? const Color(0xFF4A3E12) : const Color(0xFFF6EAC0),
      error: isLight ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
      onError: isLight ? Colors.white : const Color(0xFF4A1F1C),
      errorContainer:
          isLight ? const Color(0xFFF9DEDC) : const Color(0xFF4A1F1C),
      onErrorContainer:
          isLight ? const Color(0xFF7A1A14) : const Color(0xFFF9DEDC),
      surface: isLight ? _surface : _surfaceD,
      onSurface: isLight ? _ink : _inkD,
      onSurfaceVariant: isLight ? _inkSoft : _inkSoftD,
      surfaceContainerLowest:
          isLight ? const Color(0xFFD8D1C7) : const Color(0xFF100D0B),
      surfaceContainerLow: isLight ? _canvas : _canvasD,
      surfaceContainer: isLight ? _surface : _surfaceD,
      surfaceContainerHigh: isLight ? _surfaceAlt : _surfaceAltD,
      surfaceContainerHighest:
          isLight ? const Color(0xFFE9E1D4) : const Color(0xFF342C25),
      outline: isLight ? const Color(0xFFB9AFA3) : const Color(0xFF6E6459),
      outlineVariant:
          isLight ? const Color(0xFFE3DACC) : const Color(0xFF3C332B),
      inverseSurface: isLight ? _night : _onNight,
      onInverseSurface: isLight ? _onNight : _night,
      inversePrimary: isLight ? _accentD : _accent,
      shadow: const Color(0xFF201B16),
      scrim: Colors.black,
    );
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = _scheme(brightness);
    final isLight = brightness == Brightness.light;

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: 'PlusJakartaSans',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    final textTheme = baseText.copyWith(
      // Stat numerals & page titles carry the design language: heavy weights.
      displaySmall:
          baseText.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium:
          baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall:
          baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: baseText.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: baseText.labelSmall?.copyWith(
          fontWeight: FontWeight.w600, letterSpacing: 0.4),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.45),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      // Accessibility: comfortable touch targets everywhere by default.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: isLight
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: isLight
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        shape: const StadiumBorder(),
        side: isLight
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: textTheme.labelMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        // Primary CTA: the "night" pill.
        style: FilledButton.styleFrom(
          backgroundColor: scheme.inverseSurface,
          foregroundColor: scheme.onInverseSurface,
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: const StadiumBorder(),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surface,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: isLight
              ? const BorderSide(color: Colors.transparent)
              : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLow,
        scrolledUnderElevation: 0,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}

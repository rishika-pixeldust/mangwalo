import 'package:flutter/material.dart';

/// "Velvet Ledger" design system: the luxury evolution of Warm Ledger.
/// Ivory canvas, near-white cards with 28px radii, oxblood/burgundy as the
/// single accent with blush containers, wine-black "night" tone for the
/// bottom nav and primary CTAs (mapped onto inverseSurface), Playfair
/// Display serif for display type over Plus Jakarta Sans body.
abstract final class AppTheme {
  // Light tokens
  static const _canvas = Color(0xFFF6EFEA);
  static const _surface = Color(0xFFFDF9F6);
  static const _surfaceAlt = Color(0xFFF0E3DD);
  static const _ink = Color(0xFF2A171C);
  static const _inkSoft = Color(0xFF8E7A80);
  static const _accent = Color(0xFF7E2231); // oxblood
  static const _accentSoft = Color(0xFFF7DCDE); // blush
  static const _onAccentSoft = Color(0xFF56141F);
  static const _night = Color(0xFF26141A);
  static const _onNight = Color(0xFFF7EFEA);

  // Dark tokens
  static const _canvasD = Color(0xFF17100D);
  static const _surfaceD = Color(0xFF221715);
  static const _surfaceAltD = Color(0xFF2E1F1D);
  static const _inkD = Color(0xFFF4EAE6);
  static const _inkSoftD = Color(0xFFAD9599);
  static const _accentD = Color(0xFFE8A0AB); // blush-rose reads on dark
  static const _accentSoftD = Color(0xFF4A222B);
  static const _onAccentSoftD = Color(0xFFFFD9DE);

  static const serif = 'PlayfairDisplay';
  static const sans = 'PlusJakartaSans';

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final isLight = b == Brightness.light;
    return ColorScheme(
      brightness: b,
      primary: isLight ? _accent : _accentD,
      onPrimary: isLight ? Colors.white : const Color(0xFF3F0F18),
      primaryContainer: isLight ? _accentSoft : _accentSoftD,
      onPrimaryContainer: isLight ? _onAccentSoft : _onAccentSoftD,
      secondary: isLight ? const Color(0xFF6E5257) : const Color(0xFFD8BEC2),
      onSecondary: isLight ? Colors.white : const Color(0xFF2A181B),
      secondaryContainer: isLight ? _surfaceAlt : _surfaceAltD,
      onSecondaryContainer:
          isLight ? const Color(0xFF4A363B) : const Color(0xFFE8D6D2),
      // Warn/gold family (privacy warnings) — champagne against the wine.
      tertiary: isLight ? const Color(0xFF7A5C00) : const Color(0xFFE9C96B),
      onTertiary: isLight ? Colors.white : const Color(0xFF3A2E06),
      tertiaryContainer:
          isLight ? const Color(0xFFF1E2B0) : const Color(0xFF4A3B0E),
      onTertiaryContainer:
          isLight ? const Color(0xFF453508) : const Color(0xFFF6E9C2),
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
          isLight ? const Color(0xFFDDD2CB) : const Color(0xFF100B09),
      surfaceContainerLow: isLight ? _canvas : _canvasD,
      surfaceContainer: isLight ? _surface : _surfaceD,
      surfaceContainerHigh: isLight ? _surfaceAlt : _surfaceAltD,
      surfaceContainerHighest:
          isLight ? const Color(0xFFEADBD3) : const Color(0xFF382622),
      outline: isLight ? const Color(0xFFBCA8A4) : const Color(0xFF6E5C58),
      outlineVariant:
          isLight ? const Color(0xFFE6D6CF) : const Color(0xFF3E2C28),
      inverseSurface: isLight ? _night : _onNight,
      onInverseSurface: isLight ? _onNight : _night,
      inversePrimary: isLight ? _accentD : _accent,
      shadow: const Color(0xFF2A171C),
      scrim: Colors.black,
    );
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = _scheme(brightness);
    final isLight = brightness == Brightness.light;

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: sans,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    final textTheme = baseText.copyWith(
      // Display voice is the serif — the luxury signature.
      displaySmall: baseText.displaySmall
          ?.copyWith(fontFamily: serif, fontWeight: FontWeight.w700),
      headlineMedium: baseText.headlineMedium
          ?.copyWith(fontFamily: serif, fontWeight: FontWeight.w700),
      headlineSmall: baseText.headlineSmall
          ?.copyWith(fontFamily: serif, fontWeight: FontWeight.w700),
      titleLarge: baseText.titleLarge
          ?.copyWith(fontFamily: serif, fontWeight: FontWeight.w600),
      // Working type stays the sans.
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
      fontFamily: sans,
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
        // Primary CTA: the wine-black pill.
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
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}

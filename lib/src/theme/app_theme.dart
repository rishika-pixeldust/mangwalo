import 'package:flutter/material.dart';

import 'dark_variant.dart';

/// One dark palette. Light is a single fixed identity; dark is a choice,
/// because comfort in the dark depends on the room, the panel, and the eye.
@immutable
class _Night {
  const _Night({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceLowest,
    required this.surfaceHighest,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.outline,
    required this.outlineVariant,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceLowest;
  final Color surfaceHighest;
  final Color ink;
  final Color inkSoft;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color outline;
  final Color outlineVariant;
}

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
  static const _nightInk = Color(0xFF26141A);
  static const _onNight = Color(0xFFF7EFEA);

  /// Default dark. Surfaces sit well clear of black and the rose is
  /// deliberately desaturated: a saturated accent on a near-black ground is
  /// what made the first attempt tiring to read.
  static const _warmCharcoal = _Night(
    canvas: Color(0xFF1A1618),
    surface: Color(0xFF242022),
    surfaceAlt: Color(0xFF302B2E),
    surfaceLowest: Color(0xFF131011),
    surfaceHighest: Color(0xFF3A3437),
    ink: Color(0xFFE9E3E5),
    inkSoft: Color(0xFFAEA5A9),
    accent: Color(0xFFD8AAB2),
    onAccent: Color(0xFF3A1C22),
    accentSoft: Color(0xFF3D2E33),
    onAccentSoft: Color(0xFFF3DCE0),
    outline: Color(0xFF7C7276),
    outlineVariant: Color(0xFF413A3D),
  );

  /// The original Luxe night — deeper and browner, more dramatic.
  static const _wineNoir = _Night(
    canvas: Color(0xFF17100D),
    surface: Color(0xFF221715),
    surfaceAlt: Color(0xFF2E1F1D),
    surfaceLowest: Color(0xFF100B09),
    surfaceHighest: Color(0xFF382622),
    ink: Color(0xFFF4EAE6),
    inkSoft: Color(0xFFAD9599),
    accent: Color(0xFFE8A0AB),
    onAccent: Color(0xFF3F0F18),
    accentSoft: Color(0xFF4A222B),
    onAccentSoft: Color(0xFFFFD9DE),
    outline: Color(0xFF6E5C58),
    outlineVariant: Color(0xFF3E2C28),
  );

  /// OLED: true black ground, with cards lifted just enough to read as cards.
  static const _trueBlack = _Night(
    canvas: Color(0xFF000000),
    surface: Color(0xFF0E0C0D),
    surfaceAlt: Color(0xFF1A1719),
    surfaceLowest: Color(0xFF000000),
    surfaceHighest: Color(0xFF241F21),
    ink: Color(0xFFEDE7E9),
    inkSoft: Color(0xFFA9A1A4),
    accent: Color(0xFFE0B0B8),
    onAccent: Color(0xFF33161C),
    accentSoft: Color(0xFF2B2124),
    onAccentSoft: Color(0xFFF5E1E5),
    outline: Color(0xFF7A7275),
    outlineVariant: Color(0xFF302A2C),
  );

  static _Night _night(DarkVariant v) => switch (v) {
        DarkVariant.warmCharcoal => _warmCharcoal,
        DarkVariant.wineNoir => _wineNoir,
        DarkVariant.trueBlack => _trueBlack,
      };

  static const serif = 'PlayfairDisplay';
  static const sans = 'PlusJakartaSans';

  static ThemeData light() => _base(Brightness.light, DarkVariant.warmCharcoal);
  static ThemeData dark([DarkVariant variant = DarkVariant.warmCharcoal]) =>
      _base(Brightness.dark, variant);

  static ColorScheme _scheme(Brightness b, DarkVariant variant) {
    final isLight = b == Brightness.light;
    final n = _night(variant);
    return ColorScheme(
      brightness: b,
      primary: isLight ? _accent : n.accent,
      onPrimary: isLight ? Colors.white : n.onAccent,
      primaryContainer: isLight ? _accentSoft : n.accentSoft,
      onPrimaryContainer: isLight ? _onAccentSoft : n.onAccentSoft,
      secondary: isLight ? const Color(0xFF6E5257) : const Color(0xFFD5C2C6),
      onSecondary: isLight ? Colors.white : const Color(0xFF2A181B),
      secondaryContainer: isLight ? _surfaceAlt : n.surfaceAlt,
      onSecondaryContainer: isLight ? const Color(0xFF4A363B) : n.ink,
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
      surface: isLight ? _surface : n.surface,
      onSurface: isLight ? _ink : n.ink,
      onSurfaceVariant: isLight ? _inkSoft : n.inkSoft,
      surfaceContainerLowest:
          isLight ? const Color(0xFFDDD2CB) : n.surfaceLowest,
      surfaceContainerLow: isLight ? _canvas : n.canvas,
      surfaceContainer: isLight ? _surface : n.surface,
      surfaceContainerHigh: isLight ? _surfaceAlt : n.surfaceAlt,
      surfaceContainerHighest:
          isLight ? const Color(0xFFEADBD3) : n.surfaceHighest,
      outline: isLight ? const Color(0xFFBCA8A4) : n.outline,
      outlineVariant: isLight ? const Color(0xFFE6D6CF) : n.outlineVariant,
      // On dark, the "night CTA" trick inverts: a light pill on dark ground.
      inverseSurface: isLight ? _nightInk : n.ink,
      onInverseSurface: isLight ? _onNight : n.canvas,
      inversePrimary: isLight ? _warmCharcoal.accent : _accent,
      shadow: const Color(0xFF2A171C),
      scrim: Colors.black,
    );
  }

  static ThemeData _base(Brightness brightness, DarkVariant variant) {
    final scheme = _scheme(brightness, variant);
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

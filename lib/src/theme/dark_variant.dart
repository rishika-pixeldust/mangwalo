/// The dark palettes MangWalo offers. Light is deliberately not a choice —
/// it is the identity of the brand and people like it as-is; dark is where
/// comfort is personal (ambient light, OLED smearing, contrast tolerance).
enum DarkVariant {
  /// Default. Surfaces lifted well off pure black with a warm cast, burgundy
  /// desaturated so it stops vibrating against dark backgrounds.
  warmCharcoal,

  /// The original Luxe night palette — deeper, more saturated wine.
  wineNoir,

  /// Near-black for OLED screens, where true black saves power and avoids
  /// the grey haze of a lifted surface.
  trueBlack,
}

extension DarkVariantLabel on DarkVariant {
  String get label => switch (this) {
        DarkVariant.warmCharcoal => 'Warm charcoal',
        DarkVariant.wineNoir => 'Wine noir',
        DarkVariant.trueBlack => 'True black',
      };

  String get description => switch (this) {
        DarkVariant.warmCharcoal => 'Softest on the eyes — the default',
        DarkVariant.wineNoir => 'Deeper, more dramatic wine tones',
        DarkVariant.trueBlack => 'Near-black, best on OLED screens',
      };
}

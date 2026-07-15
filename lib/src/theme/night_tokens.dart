import 'package:flutter/material.dart';

/// The "night" tone pair (charcoal slab + warm off-white content) used by
/// the bottom nav and primary CTAs. Mapped onto inverseSurface so both
/// themes resolve it correctly — this helper just names the intent.
({Color night, Color onNight}) nightTokensOf(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  // In dark mode the "slab" should stay dark, not invert to cream.
  if (scheme.brightness == Brightness.dark) {
    return (night: const Color(0xFF100D0B), onNight: const Color(0xFFF7F2EB));
  }
  return (night: scheme.inverseSurface, onNight: scheme.onInverseSurface);
}

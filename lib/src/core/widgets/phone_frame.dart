import 'package:flutter/material.dart';

/// On wide (desktop) browsers, constrains the app to a phone-width column so
/// MangWalo reads as the mobile product it is. On actual phones it is a no-op.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const _phoneWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _phoneWidth + 48) return child;
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          color: scheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _phoneWidth),
              // Descendants must SEE phone dimensions, not the browser
              // window: Material dialogs (e.g. the date picker) pick their
              // portrait/landscape layout from MediaQuery size.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(_phoneWidth, constraints.maxHeight),
                ),
                child: Material(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

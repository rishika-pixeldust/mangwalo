/// Build-time backend configuration.
///
/// Values arrive via `--dart-define-from-file=.env`, so nothing is read from
/// disk at runtime and no secret is embedded in source. Only client-safe
/// values live here: a Flutter web build ships them inside main.dart.js, and
/// they are safe because Row Level Security — not secrecy — guards the data.
///
/// When they are absent the app runs in **local-only mode**: everything from
/// Phase A keeps working against Hive, and the social features simply announce
/// that they need a backend. That keeps `flutter run` useful for anyone who
/// clones the repo without credentials.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The publishable (`sb_publishable_…`) key. Public by design and guarded by
  /// RLS, so shipping it in the web bundle is expected — this is the key the
  /// current SDK wants; the legacy `anon` JWT is deprecated.
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// True only when both values are present, so a half-configured build fails
  /// closed into local-only mode rather than throwing at first request.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Where the magic link returns to. Supabase must list this exact origin
  /// under Authentication → URL Configuration → Redirect URLs.
  static const authRedirect = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT',
    defaultValue: 'https://mangwalo.vercel.app',
  );

  /// Public bucket holding listing photos (downscaled and EXIF-stripped
  /// on-device before upload).
  static const photoBucket = 'listing-photos';
}

/// Invisible Unicode formatting characters: zero-width spaces/joiners, bidi
/// overrides, word joiner, BOM — removed outright (they can hide or reorder
/// content, and turning them into spaces would split words).
final _invisibles = RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060\uFEFF]');

/// Control characters (newline handled separately per mode).
final _controlChars = RegExp(r'[\x00-\x09\x0B-\x1F\x7F]');
final _newline = RegExp(r'\r\n?');
final _spaceRuns = RegExp(r'[ \t]+');
final _spacedNewlines = RegExp(r' ?\n ?');
final _newlineRuns = RegExp(r'\n{3,}');
final _whitespaceRuns = RegExp(r'\s+');

/// Normalizes user text before storage: strips control and invisible
/// characters, collapses whitespace, clamps length. Applied in the form
/// layer AND again in the repository — defense in depth.
///
/// With [multiline], newlines the user typed are preserved (normalized,
/// max one blank line) — the description field invites them.
String sanitize(String input, {int? maxLength, bool multiline = false}) {
  var out = input.replaceAll(_newline, '\n');
  out = out.replaceAll(_invisibles, '');
  out = out.replaceAll(_controlChars, ' ');
  if (multiline) {
    out = out
        .replaceAll(_spaceRuns, ' ')
        .replaceAll(_spacedNewlines, '\n')
        .replaceAll(_newlineRuns, '\n\n');
  } else {
    out = out.replaceAll(_whitespaceRuns, ' ');
  }
  out = out.trim();
  if (maxLength != null && out.length > maxLength) {
    out = out.substring(0, maxLength).trim();
  }
  return out;
}

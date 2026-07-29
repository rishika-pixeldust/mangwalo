import 'dart:convert';

import 'package:flutter/material.dart';

/// A listing photo, wherever it lives.
///
/// Photos arrive in two shapes and the UI should not have to care which:
///
///  * a **Storage URL** (`https://…/listing-photos/…`) once a listing has
///    synced to the shared noticeboard, and
///  * a **base64 JPEG** for anything still local-only — a draft being edited,
///    a board running without a backend, or a row written before the sync
///    layer existed.
///
/// Both are downscaled and EXIF-stripped on-device before they get this far,
/// so nothing here re-encodes or strips anything.
bool isPhotoUrl(String photo) =>
    photo.startsWith('http://') || photo.startsWith('https://');

class ListingPhoto extends StatelessWidget {
  const ListingPhoto({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Either a Storage URL or a base64-encoded JPEG.
  final String photo;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (photo.isEmpty) return _Fallback(width: width, height: height);

    if (isPhotoUrl(photo)) {
      return Image.network(
        photo,
        width: width,
        height: height,
        fit: fit,
        // A dead URL must never take the card down with it.
        errorBuilder: (_, _, _) => _Fallback(width: width, height: height),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _Fallback(width: width, height: height),
      );
    }

    try {
      return Image.memory(
        base64Decode(photo),
        width: width,
        height: height,
        fit: fit,
        // Avoids a flash of nothing while a re-decode happens on rebuild.
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _Fallback(width: width, height: height),
      );
    } on FormatException {
      // Corrupted row: show the placeholder rather than throwing in build.
      return _Fallback(width: width, height: height);
    }
  }
}

/// Neutral stand-in that keeps layout stable when a photo cannot be shown.
class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/widgets/listing_photo.dart';

/// Swipeable photo preview for a listing: full-width pages with dot
/// indicators. Each page announces "Photo N of M".
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.photos, required this.title});

  final List<String> photos;
  final String title;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Semantics(
                label: 'Photo ${i + 1} of ${widget.photos.length} — '
                    '${widget.title}',
                image: true,
                child: ListingPhoto(
                  photo: widget.photos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.photos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

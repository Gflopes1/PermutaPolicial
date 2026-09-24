import 'package:flutter/material.dart';

import '../../../core/widgets/cached_network_image_wrapper.dart';
import '../utils/mapa_tatico_photo_url.dart';
import '../models/map_point_photo.dart';

class MapaTaticoPhotoCarousel extends StatefulWidget {
  final List<MapPointPhoto> photos;
  final String? legacyPhotoUrl;
  final bool canDelete;
  final void Function(MapPointPhoto photo)? onDeletePhoto;

  const MapaTaticoPhotoCarousel({
    super.key,
    required this.photos,
    this.legacyPhotoUrl,
    this.canDelete = false,
    this.onDeletePhoto,
  });

  @override
  State<MapaTaticoPhotoCarousel> createState() => _MapaTaticoPhotoCarouselState();
}

class _MapaTaticoPhotoCarouselState extends State<MapaTaticoPhotoCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  List<MapPointPhoto> get _items {
    if (widget.photos.isNotEmpty) return widget.photos;
    if (widget.legacyPhotoUrl != null && widget.legacyPhotoUrl!.isNotEmpty) {
      return [
        MapPointPhoto(id: 0, url: widget.legacyPhotoUrl!, orderIndex: 0),
      ];
    }
    return const [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final photo = items[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImageWrapper(
                      imageUrl: resolveMapaTaticoPhotoUrl(photo.url),
                      fit: BoxFit.cover,
                      useCacheBusting: false,
                      errorWidget: Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  if (widget.canDelete && photo.id > 0 && widget.onDeletePhoto != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => widget.onDeletePhoto!(photo),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

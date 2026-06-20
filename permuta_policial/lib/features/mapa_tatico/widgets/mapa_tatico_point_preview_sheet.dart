import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../core/widgets/cached_network_image_wrapper.dart';
import '../models/map_point.dart';
import '../providers/mapa_tatico_provider.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import '../utils/mapa_tatico_navigation_utils.dart';
import '../utils/mapa_tatico_photo_url.dart';

class MapaTaticoPointPreviewSheet extends StatefulWidget {
  final MapPoint point;
  final bool isMuted;

  const MapaTaticoPointPreviewSheet({
    super.key,
    required this.point,
    required this.isMuted,
  });

  @override
  State<MapaTaticoPointPreviewSheet> createState() => _MapaTaticoPointPreviewSheetState();
}

class _MapaTaticoPointPreviewSheetState extends State<MapaTaticoPointPreviewSheet> {
  final _commentController = TextEditingController();
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final provider = context.read<MapaTaticoProvider>();
    await provider.getComments(widget.point.id);
    if (mounted) setState(() => _loadingComments = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapaTaticoProvider>();
    final point = widget.point;
    final distance = provider.distanceToPoint(point);
    final comments = provider.recentCommentsForPoint(point.id);
    final expiringSoon = isPointExpiringSoon(point);

    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: markerColorForPointType(point),
                      shape: BoxShape.circle,
                      border: expiringSoon
                          ? Border.all(color: Colors.orange, width: 3)
                          : Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(markerEmojiForPointType(point)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point.title, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${pointTypeLabel(point.type)} • ${point.creatorDisplay}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if (distance != null)
                          Text(
                            '${distance.toStringAsFixed(0)} m de você',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        if (point.expiresAt != null)
                          Text(
                            formatExpiresLabel(point.expiresAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: expiringSoon ? Colors.orange.shade800 : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (point.photoUrl != null && point.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: CachedNetworkImageWrapper(
                      imageUrl: resolveMapaTaticoPhotoUrl(point.photoUrl),
                      height: 140,
                      fit: BoxFit.cover,
                      useCacheBusting: false,
                      placeholder: Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (point.address != null && point.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(point.address!, style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final pos = provider.currentPosition;
                      showNavigationChooser(
                        context,
                        lat: point.lat,
                        lng: point.lng,
                        label: point.title,
                        fromLat: pos?.latitude,
                        fromLng: pos?.longitude,
                        onRouteLoaded: (route) {
                          provider.setNavigationRoute(route);
                          Navigator.pop(context);
                        },
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navegar até'),
                  ),
                  if (!widget.isMuted)
                    OutlinedButton.icon(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.comment, size: 18),
                      label: const Text('Comentar'),
                    ),
                  if (point.mapType == 'LOGISTICS')
                    FilledButton.tonalIcon(
                      onPressed: _registerVisit,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Fui Hoje'),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/mapa-tatico/ponto/${point.id}');
                    },
                    child: const Text('Ver completo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Comentários recentes', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_loadingComments)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhum comentário ainda.', style: TextStyle(color: Colors.grey.shade600)),
                )
              else
                ...comments.take(3).map(
                      (c) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.authorDisplayName ?? 'Membro', style: const TextStyle(fontSize: 12)),
                        subtitle: Text(c.text),
                      ),
                    ),
              if (!widget.isMuted) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Escreva um comentário rápido...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(onPressed: _submitComment, icon: const Icon(Icons.send)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final provider = context.read<MapaTaticoProvider>();
    final comment = await provider.addComment(widget.point.id, text);
    if (!mounted) return;
    if (comment != null) {
      _commentController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Comentário enviado.'),
      );
    }
  }

  Future<void> _registerVisit() async {
    final provider = context.read<MapaTaticoProvider>();
    final ok = await provider.registerVisit(widget.point.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      ok
          ? AppStyles.successSnackBar('Visita registrada!')
          : AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao registrar visita.'),
    );
  }
}

// /lib/features/mapa_tatico/screens/detalhe_ponto_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../providers/mapa_tatico_provider.dart';
import '../models/map_point.dart';
import '../models/map_point_comment.dart';
import '../models/map_point_visit.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/utils/error_handler.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class DetalhePontoScreen extends StatefulWidget {
  final int pointId;

  const DetalhePontoScreen({super.key, required this.pointId});

  @override
  State<DetalhePontoScreen> createState() => _DetalhePontoScreenState();
}

class _DetalhePontoScreenState extends State<DetalhePontoScreen> {
  MapPoint? _point;
  List<MapPointComment> _comments = [];
  List<MapPointVisit> _visits = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<MapaTaticoProvider>();
    setState(() => _isLoading = true);
    try {
      _point = await provider.getPoint(widget.pointId);
      if (_point != null) {
        _comments = await provider.getComments(widget.pointId);
        if (_point!.mapType == 'LOGISTICS') {
          _visits = await provider.getVisits(widget.pointId, lastDays: 7);
        }
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatExpires(DateTime? expiresAt) {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 'Expirado';
    final diff = expiresAt.difference(now);
    if (diff.inDays > 0) return 'Expira em ${diff.inDays} dia(s)';
    if (diff.inHours > 0) return 'Expira em ${diff.inHours} hora(s)';
    return 'Expira em ${diff.inMinutes} min';
  }

  String _photoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_point == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ponto')),
        body: Center(child: Text(_errorMessage ?? 'Ponto não encontrado')),
      );
    }

    final point = _point!;
    final provider = context.read<MapaTaticoProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final activeGroup = provider.activeGroup;
    final currentUserId = dashboardProvider.userData?.id;
    final canEdit = activeGroup != null &&
        (activeGroup.isModerator || point.creatorId == currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(point.title),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(provider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (point.photoUrl != null && point.photoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _photoUrl(point.photoUrl),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              point.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  point.creatorDisplay,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (point.address != null && point.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(point.address!)),
                ],
              ),
            ],
            if (point.expiresAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatExpires(point.expiresAt),
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (!provider.isMuted)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addComment(provider),
                      icon: const Icon(Icons.comment),
                      label: const Text('Comentar'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _report(provider),
                    icon: const Icon(Icons.flag),
                    label: const Text('Denunciar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                if (point.mapType == 'LOGISTICS') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _registerVisit(provider),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Fui Hoje'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Text('Comentários', style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
            if (!provider.isMuted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addComment(provider),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ..._comments.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.authorDisplayName ?? 'Anônimo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(c.text),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(c.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (point.mapType == 'LOGISTICS' && _visits.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Visitas (últimos 7 dias)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              ..._visits.map(
                (v) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(v.userDisplayName ?? 'Usuário'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(v.visitedAt),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addComment(MapaTaticoProvider provider) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final comment = await provider.addComment(widget.pointId, text);
    if (comment != null && mounted) {
      _commentController.clear();
      setState(() => _comments.insert(0, comment));
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Comentário adicionado.'),
      );
    }
  }

  Future<void> _report(MapaTaticoProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denunciar ponto'),
        content: const Text(
          'Deseja denunciar este ponto? Os moderadores serão notificados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Denunciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await provider.reportPoint(widget.pointId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          success
              ? AppStyles.successSnackBar('Denúncia registrada.')
              : AppStyles.errorSnackBar(
                  provider.errorMessage ?? 'Erro ao denunciar.'),
        );
      }
    }
  }

  Future<void> _registerVisit(MapaTaticoProvider provider) async {
    final success = await provider.registerVisit(widget.pointId);
    if (mounted) {
      if (success) {
        _visits = await provider.getVisits(widget.pointId, lastDays: 7);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.successSnackBar('Visita registrada!'),
        );
      }
    }
  }

  Future<void> _confirmDelete(MapaTaticoProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ponto'),
        content: const Text(
          'Tem certeza que deseja excluir este ponto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await provider.deletePoint(widget.pointId);
      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            AppStyles.successSnackBar('Ponto excluído.'),
          );
        }
      }
    }
  }
}

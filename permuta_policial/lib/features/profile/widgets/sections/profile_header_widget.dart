import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_styles.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../core/models/user_profile.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../utils/profile_photo_url.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final UserProfile userProfile;
  final int intencoesCount;

  const ProfileHeaderWidget({
    super.key,
    required this.userProfile,
    this.intencoesCount = 0,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final _picker = ImagePicker();
  bool _isUpdatingPhoto = false;

  String _initials(String nome) {
    final parts = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  double _calcularCompletude() {
    const total = 6;
    var preenchidos = 0;
    if (widget.userProfile.qso?.isNotEmpty == true) preenchidos++;
    if (widget.userProfile.forcaId != null) preenchidos++;
    if (widget.userProfile.postoGraduacaoId != null) preenchidos++;
    if (widget.userProfile.municipioAtualId != null) preenchidos++;
    if (widget.userProfile.antiguidade?.isNotEmpty == true) preenchidos++;
    if (widget.intencoesCount > 0) preenchidos++;
    return preenchidos / total;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 90);
    if (file == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    final bytes = await file.readAsBytes();
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final success = await provider.uploadProfilePhoto(bytes, photoFilename: file.name);

    if (!mounted) return;
    setState(() => _isUpdatingPhoto = false);

    ScaffoldMessenger.of(context).showSnackBar(
      success
          ? AppStyles.successSnackBar('Foto de perfil atualizada.')
          : AppStyles.errorSnackBar(provider.initialDataError ?? 'Erro ao enviar foto.'),
    );
  }

  Future<void> _removePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover foto de perfil?'),
        content: const Text('Sua foto será removida e as iniciais voltarão a aparecer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final success = await provider.deleteProfilePhoto();

    if (!mounted) return;
    setState(() => _isUpdatingPhoto = false);

    ScaffoldMessenger.of(context).showSnackBar(
      success
          ? AppStyles.successSnackBar('Foto de perfil removida.')
          : AppStyles.errorSnackBar(provider.initialDataError ?? 'Erro ao remover foto.'),
    );
  }

  Future<void> _showPhotoOptions() async {
    if (_isUpdatingPhoto) return;

    final hasPhoto = widget.userProfile.fotoPerfil?.isNotEmpty == true;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completude = _calcularCompletude();
    final photoUrl = resolveProfilePhotoUrl(widget.userProfile.fotoPerfil);
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.22),
                      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                      child: _isUpdatingPhoto
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (!hasPhoto
                              ? Text(
                                  _initials(widget.userProfile.nome),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryLight,
                                  ),
                                )
                              : null),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryLight,
                        child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userProfile.nome,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.userProfile.idFuncional?.isNotEmpty == true)
                      Text(
                        'Mat. ${widget.userProfile.idFuncional}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    Text(
                      'Toque na foto para alterar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryLight.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (widget.userProfile.forcaSigla != null)
                _Chip(label: widget.userProfile.forcaSigla!, icon: Icons.shield_outlined),
              if (widget.userProfile.postoGraduacaoNome != null)
                _Chip(label: widget.userProfile.postoGraduacaoNome!, icon: Icons.military_tech_outlined),
              if (widget.userProfile.lotacaoInterestadual)
                _Chip(label: 'Interestadual', icon: Icons.public_outlined, color: Colors.teal),
              if (widget.userProfile.isPremium)
                _Chip(label: 'Premium', icon: Icons.workspace_premium_outlined, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Perfil completo', style: theme.textTheme.bodySmall),
              ),
              Text(
                '${(completude * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completude,
              minHeight: 6,
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _Chip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c),
          ),
        ],
      ),
    );
  }
}

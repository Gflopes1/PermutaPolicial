import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../models/map_suspect_profile.dart';
import '../providers/mapa_tatico_provider.dart';
import 'mapa_tatico_suspect_profile_form.dart';

class MapaTaticoSuspectProfileSection extends StatefulWidget {
  final int pointId;
  final MapSuspectProfile? initialProfile;
  final bool canEdit;

  const MapaTaticoSuspectProfileSection({
    super.key,
    required this.pointId,
    this.initialProfile,
    required this.canEdit,
  });

  @override
  State<MapaTaticoSuspectProfileSection> createState() => _MapaTaticoSuspectProfileSectionState();
}

class _MapaTaticoSuspectProfileSectionState extends State<MapaTaticoSuspectProfileSection> {
  final _formData = MapaTaticoSuspectProfileFormData();
  MapSuspectProfile? _profile;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (_profile != null) {
      _formData.applyFromProfile(_profile!);
    } else {
      _editing = widget.canEdit;
    }
  }

  Future<void> _save() async {
    _formData.fundamentacao = _formData.fundamentacao.trim();
    if (_formData.fundamentacao.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('A fundamentação deve ter pelo menos 20 caracteres.'),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<MapaTaticoProvider>();
    final saved = await provider.upsertSuspectProfile(widget.pointId, _formData.toJson());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved != null) {
        _profile = saved;
        _formData.applyFromProfile(saved);
        _editing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.successSnackBar('Perfil de suspeito salvo.'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao salvar perfil.'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profile?.archivedAt != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text(
          'Este perfil foi arquivado por um moderador após contestação.',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Perfil do suspeito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.canEdit && _profile != null && !_editing)
              TextButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Editar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        MapaTaticoSuspectProfileForm(
          data: _formData,
          readOnly: !widget.canEdit || (_profile != null && !_editing),
        ),
        if (widget.canEdit && (_editing || _profile == null)) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_profile == null ? 'Salvar perfil' : 'Atualizar perfil'),
            ),
          ),
        ],
      ],
    );
  }
}

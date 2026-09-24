import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/models/user_profile.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../section_card.dart';

class PreferenciasSection extends StatefulWidget {
  final UserProfile userProfile;

  const PreferenciasSection({super.key, required this.userProfile});

  @override
  State<PreferenciasSection> createState() => _PreferenciasSectionState();
}

class _PreferenciasSectionState extends State<PreferenciasSection> {
  late bool _interestadual;
  late bool _ocultarNoMapa;
  late bool _alertasMatch;

  @override
  void initState() {
    super.initState();
    _syncFromProfile();
  }

  @override
  void didUpdateWidget(covariant PreferenciasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _syncFromProfile();
    }
  }

  void _syncFromProfile() {
    _interestadual = widget.userProfile.lotacaoInterestadual;
    _ocultarNoMapa = widget.userProfile.ocultarNoMapa ?? false;
    _alertasMatch = widget.userProfile.alertasMatchAtivo;
  }

  Future<void> _salvar(Map<String, dynamic> data) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.updateProfile(data);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      label: 'Preferências',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.primary,
          title: const Text('Permuta interestadual'),
          subtitle: const Text('Aceitar propostas de outros estados'),
          value: _interestadual,
          onChanged: (value) {
            setState(() => _interestadual = value);
            _salvar({'lotacao_interestadual': value});
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.primary,
          title: const Text('Modo privado'),
          subtitle: const Text('Ocultar no mapa e não enviar contato automaticamente'),
          value: _ocultarNoMapa,
          onChanged: (value) {
            setState(() => _ocultarNoMapa = value);
            _salvar({'ocultar_no_mapa': value});
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.primary,
          title: const Text('Alertas de matches'),
          subtitle: const Text('Notificar quando surgir permuta compatível'),
          value: _alertasMatch,
          onChanged: (value) {
            setState(() => _alertasMatch = value);
            _salvar({'alertas_match_ativo': value ? 1 : 0});
          },
        ),
      ],
    );
  }
}

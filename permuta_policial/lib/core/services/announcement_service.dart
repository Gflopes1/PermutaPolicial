import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repositories/configuracoes_repository.dart';
import '../api/repositories/referral_repository.dart';

class AnnouncementCampaign {
  final String id;
  final String title;
  final String description;
  final String? primaryLabel;
  final String? secondaryLabel;
  final String primaryAction;
  final bool showShare;

  AnnouncementCampaign({
    required this.id,
    required this.title,
    required this.description,
    this.primaryLabel,
    this.secondaryLabel,
    this.primaryAction = 'close',
    this.showShare = false,
  });

  factory AnnouncementCampaign.fromJson(Map<String, dynamic> json) {
    return AnnouncementCampaign(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryLabel: json['primary_label'] as String?,
      secondaryLabel: json['secondary_label'] as String?,
      primaryAction: json['primary_action'] as String? ?? 'close',
      showShare: json['show_share'] == true,
    );
  }
}

/// Gerencia popups versionados: nota de atualização e campanhas.
class AnnouncementService {
  final ConfiguracoesRepository _configuracoesRepository;
  final ReferralRepository? _referralRepository;
  final FlutterSecureStorage _secureStorage;
  static const _ultimaVersaoKey = 'ultima_versao_atualizacao';
  static const _dismissedPrefix = 'announcement_dismissed_';

  AnnouncementService(
    this._configuracoesRepository, {
    ReferralRepository? referralRepository,
  })  : _referralRepository = referralRepository,
        _secureStorage = const FlutterSecureStorage();

  Future<AnnouncementCampaign?> getPendingUpdateNote() async {
    try {
      final response = await _configuracoesRepository.getNotaAtualizacao();
      final nota = response['nota'] as String?;
      final versao = response['versao'] as String?;
      if (nota == null || nota.isEmpty || versao == null) return null;

      final ultimaVersao = await _secureStorage.read(key: _ultimaVersaoKey);
      if (ultimaVersao == versao) return null;

      return AnnouncementCampaign(
        id: 'nota_atualizacao_$versao',
        title: 'Nova Atualização',
        description: nota,
        primaryLabel: 'Fechar',
        primaryAction: 'close',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> markUpdateNoteSeen(String versao) async {
    await _secureStorage.write(key: _ultimaVersaoKey, value: versao);
  }

  String? extractVersionFromUpdateId(String campaignId) {
    if (!campaignId.startsWith('nota_atualizacao_')) return null;
    return campaignId.replaceFirst('nota_atualizacao_', '');
  }

  Future<AnnouncementCampaign?> getPendingReferralCampaign() async {
    if (_referralRepository == null) return null;
    try {
      final data = await _referralRepository!.getActiveCampaign();
      if (data == null) return null;
      final campaign = AnnouncementCampaign.fromJson(data);
      if (campaign.id.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('$_dismissedPrefix${campaign.id}') == true) {
        return null;
      }
      return campaign;
    } catch (_) {
      return null;
    }
  }

  Future<AnnouncementCampaign?> getNextPendingCampaign() async {
    final referral = await getPendingReferralCampaign();
    if (referral != null) return referral;
    return getPendingUpdateNote();
  }

  Future<void> dismissCampaign(AnnouncementCampaign campaign) async {
    if (campaign.id.startsWith('nota_atualizacao_')) {
      final versao = extractVersionFromUpdateId(campaign.id);
      if (versao != null) {
        await markUpdateNoteSeen(versao);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissedPrefix${campaign.id}', true);

    if (_referralRepository != null) {
      try {
        await _referralRepository!.dismissCampaign(campaign.id);
      } catch (_) {}
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/api/repositories/referral_repository.dart';
import '../../../core/services/referral_storage_service.dart';

class ReferralData {
  final String code;
  final String link;
  final int total;
  final int verifiedCount;
  final int pendingCount;
  final String tier;
  final String tierLabel;
  final int? nextLevel;
  final int remainingToNext;
  final double progressToNext;

  ReferralData({
    required this.code,
    required this.link,
    required this.total,
    required this.verifiedCount,
    required this.pendingCount,
    required this.tier,
    required this.tierLabel,
    this.nextLevel,
    required this.remainingToNext,
    required this.progressToNext,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      code: json['code'] as String? ?? '',
      link: json['link'] as String? ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      verifiedCount: (json['verified_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'usuario',
      tierLabel: json['tier_label'] as String? ?? 'Usuário',
      nextLevel: (json['next_level'] as num?)?.toInt(),
      remainingToNext: (json['remaining_to_next'] as num?)?.toInt() ?? 0,
      progressToNext: (json['progress_to_next'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _repository;
  final ReferralStorageService _storage;

  ReferralProvider(this._repository, this._storage);

  ReferralData? _data;
  bool _loading = false;
  String? _error;
  int _newVerifiedSinceLastVisit = 0;

  ReferralData? get data => _data;
  bool get isLoading => _loading;
  String? get error => _error;
  int get newVerifiedSinceLastVisit => _newVerifiedSinceLastVisit;

  static String whatsAppMessage(String link) =>
      'Você está procurando permuta de lotação? Conheça o Permuta Policial, uma plataforma criada para conectar policiais que querem mudar de lotação.\n\n'
      'Cadastre sua intenção e veja possíveis combinações com outros policiais:\n\n$link';

  static String sharePopupMessage(String link) =>
      '🚔 Conhece algum policial procurando permuta?\n\n'
      'O Permuta Policial conecta policiais que querem mudar de lotação.\n\n'
      'Cadastre-se gratuitamente:\n$link';

  Future<void> loadMyReferral() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _repository.getMyReferral();
      _data = ReferralData.fromJson(json);
      final lastSeen = await _storage.getLastSeenVerifiedCount();
      if (_data!.verifiedCount > lastSeen) {
        _newVerifiedSinceLastVisit = _data!.verifiedCount - lastSeen;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeVerifiedCount() async {
    if (_data != null) {
      await _storage.setLastSeenVerifiedCount(_data!.verifiedCount);
      _newVerifiedSinceLastVisit = 0;
      notifyListeners();
    }
  }

  Future<void> trackShare() async {
    try {
      await _repository.trackShare();
    } catch (_) {}
  }
}

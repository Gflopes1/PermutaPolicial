import 'package:shared_preferences/shared_preferences.dart';

/// Persiste código de indicação capturado por até 30 dias.
class ReferralStorageService {
  static const _keyCode = 'pending_referral_code';
  static const _keyCapturedAt = 'pending_referral_captured_at';
  static const _keyLastSeenVerified = 'referral_last_seen_verified_count';
  static const _captureDays = 30;

  Future<void> saveReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCode, code.trim().toUpperCase());
    await prefs.setString(_keyCapturedAt, DateTime.now().toIso8601String());
  }

  Future<String?> getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyCode);
    final capturedAtStr = prefs.getString(_keyCapturedAt);
    if (code == null || code.isEmpty) return null;
    if (capturedAtStr == null) return code;

    final capturedAt = DateTime.tryParse(capturedAtStr);
    if (capturedAt == null) return code;

    if (DateTime.now().difference(capturedAt).inDays > _captureDays) {
      await clearReferralCode();
      return null;
    }
    return code;
  }

  Future<void> clearReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCode);
    await prefs.remove(_keyCapturedAt);
  }

  Future<int> getLastSeenVerifiedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastSeenVerified) ?? 0;
  }

  Future<void> setLastSeenVerifiedCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSeenVerified, count);
  }

  /// Lê ?ref= da URL atual (web) ou parâmetro passado.
  String? parseRefFromUri(Uri? uri) {
    if (uri == null) return null;
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.trim().length >= 3) {
      return ref.trim().toUpperCase();
    }
    return null;
  }
}

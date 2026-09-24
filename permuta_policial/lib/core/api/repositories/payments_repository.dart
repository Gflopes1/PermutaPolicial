// /lib/core/api/repositories/payments_repository.dart

import '../api_client.dart';

class PaymentsRepository {
  final ApiClient _apiClient;

  PaymentsRepository(this._apiClient);

  /// Obtém a assinatura ativa do usuário
  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      final responseData = await _apiClient.get('/api/payments/subscription');
      return responseData != null ? Map<String, dynamic>.from(responseData) : null;
    } catch (e) {
      // Se não tiver assinatura ativa, retorna null
      return null;
    }
  }

  /// Cancela a assinatura do usuário
  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    final responseData = await _apiClient.post(
      '/api/payments/subscription/cancel',
      {'subscription_id': subscriptionId},
    );
    return Map<String, dynamic>.from(responseData);
  }
}


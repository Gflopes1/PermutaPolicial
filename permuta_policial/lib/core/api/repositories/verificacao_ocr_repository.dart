import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../api_client.dart';
class VerificacaoOcrSubmitResult {
  final String resultado;
  final bool agenteVerificado;
  final String? metodoVerificacao;
  final int? pendingId;

  VerificacaoOcrSubmitResult({
    required this.resultado,
    required this.agenteVerificado,
    this.metodoVerificacao,
    this.pendingId,
  });

  factory VerificacaoOcrSubmitResult.fromJson(Map<String, dynamic> json) {
    return VerificacaoOcrSubmitResult(
      resultado: json['resultado']?.toString() ?? '',
      agenteVerificado: json['agente_verificado'] == true || json['agente_verificado'] == 1,
      metodoVerificacao: json['metodo_verificacao']?.toString(),
      pendingId: json['pending_id'] is int ? json['pending_id'] as int : int.tryParse('${json['pending_id']}'),
    );
  }

  bool get verificadoAutomaticamente => resultado == 'verificado_automaticamente';
  bool get enviadoParaRevisao => resultado == 'enviado_para_revisao';
}

class VerificacaoOcrRepository {
  final ApiClient _apiClient;

  VerificacaoOcrRepository(this._apiClient);

  Future<Map<String, dynamic>> getMyStatus() async {
    final data = await _apiClient.get('/api/verificacao/ocr/status');
    return data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
  }

  Future<
      ({
        List<({String text, Rect rect, int orientation})> lines,
        List<({String text, Rect rect, int orientation})> words,
        String rawText,
      })> recognizeWithGoogleVision(List<int> ocrImageBytes) async {
    final file = http.MultipartFile.fromBytes(
      'imagem_ocr',
      ocrImageBytes,
      filename: 'ocr_input.jpg',
      contentType: MediaType('image', 'jpeg'),
    );

    final response = await _apiClient.postMultipart(
      '/api/verificacao/ocr/vision-recognize',
      const {},
      [file],
    );

    final data = response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);
    return (
      lines: _parseVisionItems(data['lines']),
      words: _parseVisionItems(data['words']),
      rawText: data['text']?.toString() ?? '',
    );
  }

  List<({String text, Rect rect, int orientation})> _parseVisionItems(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      final orientation = (map['orientation'] as num?)?.round() ?? 0;
      return (
        text: map['text']?.toString() ?? '',
        rect: Rect.fromLTRB(
          (map['x0'] as num?)?.toDouble() ?? 0,
          (map['y0'] as num?)?.toDouble() ?? 0,
          (map['x1'] as num?)?.toDouble() ?? 0,
          (map['y1'] as num?)?.toDouble() ?? 0,
        ),
        orientation: const [0, 90, 180, 270].contains(orientation) ? orientation : 0,
      );
    }).where((e) => e.text.trim().isNotEmpty).toList();
  }

  Future<VerificacaoOcrSubmitResult> submitRedactedDocument({
    required List<int> redactedBytes,
    required Map<String, String> fields,
  }) async {
    final file = http.MultipartFile.fromBytes(
      'imagem_redigida',
      redactedBytes,
      filename: 'documento_redigido.jpg',
      contentType: MediaType('image', 'jpeg'),
    );

    final response = await _apiClient.postMultipart('/api/verificacao/ocr', fields, [file]);
    final data = response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);
    return VerificacaoOcrSubmitResult.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getPendingOcrReviews() async {
    final data = await _apiClient.get('/api/verificacao/ocr/pendentes');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> approveOcrReview(int id) async {
    return await _apiClient.post('/api/verificacao/ocr/pendentes/$id/aprovar', {});
  }

  Future<Map<String, dynamic>> rejectOcrReview(int id) async {
    return await _apiClient.post('/api/verificacao/ocr/pendentes/$id/rejeitar', {});
  }
}

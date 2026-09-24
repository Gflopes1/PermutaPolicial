import 'package:flutter/material.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories/editais_repository.dart';
import '../../../core/models/edital_resumo.dart';

enum EditaisHubStatus { idle, loading, error }

class EditaisHubProvider extends ChangeNotifier {
  final EditaisRepository _repository;
  EditaisHubProvider(this._repository);

  EditaisHubStatus _status = EditaisHubStatus.idle;
  String? _errorMessage;
  List<EditalResumo> _abertos = [];
  List<EditalResumo> _encerrados = [];
  String? _whatsappNumero;
  String? _whatsappMensagem;

  EditaisHubStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<EditalResumo> get abertos => _abertos;
  List<EditalResumo> get encerrados => _encerrados;
  String? get whatsappNumero => _whatsappNumero;
  String? get whatsappMensagem => _whatsappMensagem;

  Future<void> loadAll() async {
    _status = EditaisHubStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.listEditais(aba: 'abertos'),
        _repository.listEditais(aba: 'encerrados'),
        _repository.getWhatsappConfig(),
      ]);
      _abertos = results[0] as List<EditalResumo>;
      _encerrados = results[1] as List<EditalResumo>;
      final wa = results[2] as Map<String, dynamic>;
      _whatsappNumero = wa['numero'] as String?;
      _whatsappMensagem = wa['mensagem'] as String?;
      _status = EditaisHubStatus.idle;
    } on ApiException catch (e) {
      _status = EditaisHubStatus.error;
      _errorMessage = e.message;
    }
    notifyListeners();
  }
}

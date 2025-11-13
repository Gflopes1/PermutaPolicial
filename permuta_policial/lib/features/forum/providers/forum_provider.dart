// /lib/features/forum/providers/forum_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/forum_repository.dart';

class ForumProvider with ChangeNotifier {
  final ForumRepository _forumRepository;

  ForumProvider(this._forumRepository);

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _categorias = [];
  List<dynamic> _topicos = [];
  Map<String, dynamic>? _topicoAtual;
  List<dynamic> _respostas = [];
  int? _categoriaSelecionada;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get categorias => _categorias;
  List<dynamic> get topicos => _topicos;
  Map<String, dynamic>? get topicoAtual => _topicoAtual;
  List<dynamic> get respostas => _respostas;
  int? get categoriaSelecionada => _categoriaSelecionada;

  // Carrega categorias
  Future<void> loadCategorias() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categorias = await _forumRepository.getCategorias();
    } catch (e) {
      _errorMessage = 'Erro ao carregar categorias: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Carrega tópicos de uma categoria
  Future<void> loadTopicos(int categoriaId, {bool refresh = false}) async {
    if (!refresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _categoriaSelecionada = categoriaId;
      _topicos = await _forumRepository.getTopicos(categoriaId: categoriaId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar tópicos: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Carrega um tópico específico
  Future<void> loadTopico(int topicoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topicoAtual = await _forumRepository.getTopico(topicoId);
      await loadRespostas(topicoId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar tópico: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Carrega respostas de um tópico
  Future<void> loadRespostas(int topicoId) async {
    try {
      _respostas = await _forumRepository.getRespostas(topicoId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar respostas: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cria um novo tópico
  Future<bool> createTopico({
    required int categoriaId,
    required String titulo,
    required String conteudo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _forumRepository.createTopico(
        categoriaId: categoriaId,
        titulo: titulo,
        conteudo: conteudo,
      );
      await loadTopicos(categoriaId, refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar tópico: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cria uma resposta
  Future<bool> createResposta(int topicoId, String conteudo, {int? respostaId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _forumRepository.createResposta(topicoId, conteudo, respostaId: respostaId);
      await loadRespostas(topicoId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar resposta: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle reação (curtida)
  Future<void> toggleReacao({required String tipo, int? topicoId, int? respostaId}) async {
    try {
      await _forumRepository.toggleReacao(
        tipo: tipo,
        topicoId: topicoId,
        respostaId: respostaId,
      );
      if (topicoId != null && _topicoAtual != null && _topicoAtual!['id'] == topicoId) {
        await loadTopico(topicoId);
      } else if (respostaId != null) {
        await loadRespostas(_topicoAtual!['id']);
      }
    } catch (e) {
      _errorMessage = 'Erro ao processar reação: ${e.toString()}';
      notifyListeners();
    }
  }

  // Busca tópicos
  Future<void> searchTopicos(String searchTerm) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topicos = await _forumRepository.searchTopicos(searchTerm);
      _categoriaSelecionada = null;
    } catch (e) {
      _errorMessage = 'Erro ao buscar tópicos: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Limpa o tópico atual
  void clearTopico() {
    _topicoAtual = null;
    _respostas = [];
    notifyListeners();
  }

  // Moderação - Estado
  List<dynamic> _topicosPendentes = [];
  List<dynamic> _respostasPendentes = [];

  List<dynamic> get topicosPendentes => _topicosPendentes;
  List<dynamic> get respostasPendentes => _respostasPendentes;

  // Carrega tópicos pendentes
  Future<void> loadTopicosPendentes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topicosPendentes = await _forumRepository.getTopicosPendentes();
    } catch (e) {
      _errorMessage = 'Erro ao carregar tópicos pendentes: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Carrega respostas pendentes
  Future<void> loadRespostasPendentes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _respostasPendentes = await _forumRepository.getRespostasPendentes();
    } catch (e) {
      _errorMessage = 'Erro ao carregar respostas pendentes: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Moderação - Tópicos
  Future<bool> aprovarTopico(int topicoId) async {
    try {
      await _forumRepository.aprovarTopico(topicoId);
      await loadTopicosPendentes();
      if (_categoriaSelecionada != null) {
        await loadTopicos(_categoriaSelecionada!, refresh: true);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao aprovar tópico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejeitarTopico(int topicoId, String motivoRejeicao) async {
    try {
      await _forumRepository.rejeitarTopico(topicoId, motivoRejeicao);
      await loadTopicosPendentes();
      if (_categoriaSelecionada != null) {
        await loadTopicos(_categoriaSelecionada!, refresh: true);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao rejeitar tópico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFixarTopico(int topicoId) async {
    try {
      await _forumRepository.toggleFixarTopico(topicoId);
      if (_categoriaSelecionada != null) {
        await loadTopicos(_categoriaSelecionada!, refresh: true);
      }
      if (_topicoAtual != null && _topicoAtual!['id'] == topicoId) {
        await loadTopico(topicoId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao fixar/desfixar tópico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleBloquearTopico(int topicoId) async {
    try {
      await _forumRepository.toggleBloquearTopico(topicoId);
      if (_categoriaSelecionada != null) {
        await loadTopicos(_categoriaSelecionada!, refresh: true);
      }
      if (_topicoAtual != null && _topicoAtual!['id'] == topicoId) {
        await loadTopico(topicoId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao bloquear/desbloquear tópico: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Moderação - Respostas
  Future<bool> aprovarResposta(int respostaId) async {
    try {
      await _forumRepository.aprovarResposta(respostaId);
      await loadRespostasPendentes();
      if (_topicoAtual != null) {
        await loadRespostas(_topicoAtual!['id']);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao aprovar resposta: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejeitarResposta(int respostaId, String motivoRejeicao) async {
    try {
      await _forumRepository.rejeitarResposta(respostaId, motivoRejeicao);
      await loadRespostasPendentes();
      if (_topicoAtual != null) {
        await loadRespostas(_topicoAtual!['id']);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao rejeitar resposta: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}


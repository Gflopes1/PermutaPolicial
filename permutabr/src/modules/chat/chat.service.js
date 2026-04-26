// /src/modules/chat/chat.service.js

const chatRepository = require('./chat.repository');
const ApiError = require('../../core/utils/ApiError');

class ChatService {
  async getConversas(req) {
    const usuarioId = req.user.id;
    // Busca conversas do usuário que fez a requisição
    // A query já filtra corretamente os dados baseado no usuário
    const conversas = await chatRepository.findConversasByUsuario(usuarioId);
    // Retorna apenas conversas do usuário autenticado
    return conversas;
  }

  async getConversa(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;

    const conversa = await chatRepository.findConversaById(conversaId);
    if (!conversa) {
      throw new ApiError(404, 'Conversa não encontrada.');
    }

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para acessar esta conversa.');
    }

    // Retorna apenas os dados que o usuário pode ver
    // Não expõe dados sensíveis que não devem ser vistos
    return conversa;
  }

  async getMensagens(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Verifica se o usuário pertence à conversa ANTES de buscar mensagens
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para acessar esta conversa.');
    }

    // Busca mensagens com filtragem baseada no usuário que fez a requisição
    // A função findMensagensByConversa já aplica a lógica de anonimato corretamente
    const mensagens = await chatRepository.findMensagensByConversa(conversaId, usuarioId, limit, offset);
    
    // Marca mensagens como lidas
    await chatRepository.marcarMensagensComoLidas(conversaId, usuarioId);

    // Retorna apenas as mensagens que o usuário pode ver
    return mensagens;
  }

  async createMensagem(req) {
    const { conversaId } = req.params;
    const { mensagem } = req.body;
    const remetenteId = req.user.id; // ID do usuário que fez a requisição

    if (!mensagem || mensagem.trim().length === 0) {
      throw new ApiError(400, 'A mensagem não pode estar vazia.');
    }

    // VALIDAÇÃO CRÍTICA: Verifica se o usuário que fez a requisição pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, remetenteId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para enviar mensagens nesta conversa.');
    }

    // Cria a mensagem usando o ID do usuário autenticado (não confia no body)
    const mensagemCriada = await chatRepository.createMensagem(conversaId, remetenteId, mensagem.trim());
    
    // Retorna a mensagem criada (com dados completos, pois o remetente já sabe quem é)
    return mensagemCriada;
  }

  async iniciarConversa(req) {
    const { usuarioId, anonima } = req.body;
    const usuarioAtualId = req.user.id;

    if (!usuarioId || usuarioId === usuarioAtualId) {
      throw new ApiError(400, 'ID de usuário inválido.');
    }

    // Verifica se o destinatário está oculto no mapa
    // Se estiver oculto, força o anonimato da conversa para proteger a privacidade
    const policiaisRepository = require('../policiais/policiais.repository');
    const destinatario = await policiaisRepository.findProfileById(usuarioId);
    if (!destinatario) {
      throw new ApiError(404, 'Usuário não encontrado.');
    }
    
    // Se o destinatário está oculto, a mensagem deve ser anônima automaticamente
    const deveSerAnonima = anonima || destinatario.ocultar_no_mapa;

    const conversa = await chatRepository.findOrCreateConversa(usuarioAtualId, usuarioId, deveSerAnonima);
    return conversa;
  }

  async marcarComoLidas(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para acessar esta conversa.');
    }

    await chatRepository.marcarMensagensComoLidas(conversaId, usuarioId);
    return { message: 'Mensagens marcadas como lidas.' };
  }

  async getMensagensNaoLidas(req) {
    const usuarioId = req.user.id; // ID do usuário que fez a requisição
    // Conta apenas mensagens não lidas do usuário autenticado
    const total = await chatRepository.countMensagensNaoLidas(usuarioId);
    return { total };
  }

  async aceitarCompartilharDados(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para acessar esta conversa.');
    }

    // Busca informações da conversa
    const conversa = await chatRepository.findConversaById(conversaId);
    if (!conversa) {
      throw new ApiError(404, 'Conversa não encontrada.');
    }

    // Verifica se é anônima e se o usuário atual é o destinatário (não o iniciador)
    if (!conversa.anonima) {
      throw new ApiError(400, 'Esta conversa não é anônima.');
    }

    // Só o destinatário (não iniciador) pode aceitar compartilhar dados
    if (conversa.iniciada_por === usuarioId) {
      throw new ApiError(400, 'Apenas o destinatário pode aceitar compartilhar dados.');
    }

    // Atualiza o flag de compartilhamento
    await chatRepository.aceitarCompartilharDados(conversaId);
    return { message: 'Dados compartilhados com sucesso.' };
  }

  async excluirConversa(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para excluir esta conversa.');
    }

    // Exclui a conversa e todas as mensagens
    await chatRepository.excluirConversa(conversaId);
    return { message: 'Conversa excluída com sucesso.' };
  }
}

module.exports = new ChatService();





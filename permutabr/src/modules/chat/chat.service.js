// /src/modules/chat/chat.service.js

const chatRepository = require('./chat.repository');
const ApiError = require('../../core/utils/ApiError');

class ChatService {
  async getConversas(req) {
    const usuarioId = req.user.id;
    const conversas = await chatRepository.findConversasByUsuario(usuarioId);
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

    return conversa;
  }

  async getMensagens(req) {
    const { conversaId } = req.params;
    const usuarioId = req.user.id;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, usuarioId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para acessar esta conversa.');
    }

    const mensagens = await chatRepository.findMensagensByConversa(conversaId, limit, offset);
    
    // Marca mensagens como lidas
    await chatRepository.marcarMensagensComoLidas(conversaId, usuarioId);

    return mensagens;
  }

  async createMensagem(req) {
    const { conversaId } = req.params;
    const { mensagem } = req.body;
    const remetenteId = req.user.id;

    if (!mensagem || mensagem.trim().length === 0) {
      throw new ApiError(400, 'A mensagem não pode estar vazia.');
    }

    // Verifica se o usuário pertence à conversa
    const isParticipante = await chatRepository.verificarParticipante(conversaId, remetenteId);
    if (!isParticipante) {
      throw new ApiError(403, 'Você não tem permissão para enviar mensagens nesta conversa.');
    }

    const mensagemCriada = await chatRepository.createMensagem(conversaId, remetenteId, mensagem.trim());
    return mensagemCriada;
  }

  async iniciarConversa(req) {
    const { usuarioId } = req.body;
    const usuarioAtualId = req.user.id;

    if (!usuarioId || usuarioId === usuarioAtualId) {
      throw new ApiError(400, 'ID de usuário inválido.');
    }

    const conversa = await chatRepository.findOrCreateConversa(usuarioAtualId, usuarioId);
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
    const usuarioId = req.user.id;
    const total = await chatRepository.countMensagensNaoLidas(usuarioId);
    return { total };
  }
}

module.exports = new ChatService();



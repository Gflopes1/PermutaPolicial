// /src/modules/notificacoes/notificacoes.service.js

const notificacoesRepository = require('./notificacoes.repository');
const policiaisRepository = require('../policiais/policiais.repository');
const ApiError = require('../../core/utils/ApiError');

class NotificacoesService {
  async getNotificacoes(usuarioId) {
    return await notificacoesRepository.findAllByUsuario(usuarioId);
  }

  async criarSolicitacaoContato(solicitanteId, destinatarioId) {
    // Busca dados do solicitante
    const solicitante = await policiaisRepository.findProfileById(solicitanteId);
    if (!solicitante) {
      throw new ApiError(404, 'Solicitante não encontrado.', null, 'NOT_FOUND');
    }

    // Verifica se já existe notificação pendente
    const notificacoes = await notificacoesRepository.findAllByUsuario(destinatarioId);
    const jaExiste = notificacoes.some(
      n => n.tipo === 'SOLICITACAO_CONTATO' && 
           n.referencia_id === solicitanteId && 
           n.lida === 0
    );

    if (jaExiste) {
      throw new ApiError(400, 'Já existe uma solicitação de contato pendente para este usuário.', null, 'DUPLICATE');
    }

    const titulo = 'Solicitação de Contato';
    const mensagem = `O usuário ${solicitante.nome} solicitou seu contato.`;

    return await notificacoesRepository.create({
      usuario_id: destinatarioId,
      tipo: 'SOLICITACAO_CONTATO',
      referencia_id: solicitanteId,
      titulo,
      mensagem,
    });
  }

  async responderSolicitacaoContato(notificacaoId, usuarioId, aceitar) {
    const notificacao = await notificacoesRepository.findById(notificacaoId);
    
    if (!notificacao) {
      throw new ApiError(404, 'Notificação não encontrada.', null, 'NOT_FOUND');
    }

    if (notificacao.usuario_id !== usuarioId) {
      throw new ApiError(403, 'Você não tem permissão para responder esta notificação.', null, 'FORBIDDEN');
    }

    if (notificacao.tipo !== 'SOLICITACAO_CONTATO') {
      throw new ApiError(400, 'Esta notificação não é uma solicitação de contato.', null, 'INVALID_TYPE');
    }

    // Marca a notificação original como lida
    await notificacoesRepository.marcarComoLida(notificacaoId, usuarioId);

    // Busca dados do usuário que respondeu
    const respondente = await policiaisRepository.findProfileById(usuarioId);
    if (!respondente) {
      throw new ApiError(404, 'Usuário não encontrado.', null, 'NOT_FOUND');
    }

    // Cria notificação de resposta para o solicitante
    if (aceitar) {
      const titulo = 'Solicitação de Contato Aceita';
      
      // Monta mensagem com informações detalhadas do aceitador
      let mensagem = `Sua solicitação de contato foi aceita por ${respondente.nome}.`;
      
      const detalhes = [];
      if (respondente.forca_sigla) detalhes.push(`Força: ${respondente.forca_sigla}`);
      if (respondente.estado_atual_sigla) detalhes.push(`Estado: ${respondente.estado_atual_sigla}`);
      if (respondente.municipio_atual_nome) detalhes.push(`Cidade: ${respondente.municipio_atual_nome}`);
      if (respondente.unidade_atual_nome) detalhes.push(`Unidade: ${respondente.unidade_atual_nome}`);
      if (respondente.posto_graduacao_nome) detalhes.push(`Posto/Graduação: ${respondente.posto_graduacao_nome}`);
      // Só mostra telefone se o usuário não estiver oculto no mapa
      if (respondente.qso && !respondente.ocultar_no_mapa) detalhes.push(`Telefone: ${respondente.qso}`);
      
      if (detalhes.length > 0) {
        mensagem += '\n\n' + detalhes.join('\n');
      }
      
      await notificacoesRepository.create({
        usuario_id: notificacao.referencia_id,
        tipo: 'SOLICITACAO_CONTATO_ACEITA',
        referencia_id: usuarioId,
        titulo,
        mensagem,
      });
    } else {
      const titulo = 'Solicitação de Contato Negada';
      const mensagem = `Sua solicitação de contato foi negada.`;
      
      await notificacoesRepository.create({
        usuario_id: notificacao.referencia_id,
        tipo: 'SOLICITACAO_CONTATO_NEGADA',
        referencia_id: usuarioId,
        titulo,
        mensagem,
      });
    }

    return { message: aceitar ? 'Solicitação aceita com sucesso.' : 'Solicitação negada.' };
  }

  async marcarComoLida(id, usuarioId) {
    const notificacao = await notificacoesRepository.findById(id);
    if (!notificacao) {
      throw new ApiError(404, 'Notificação não encontrada.', null, 'NOT_FOUND');
    }
    if (notificacao.usuario_id !== usuarioId) {
      throw new ApiError(403, 'Você não tem permissão para marcar esta notificação como lida.', null, 'FORBIDDEN');
    }
    return await notificacoesRepository.marcarComoLida(id, usuarioId);
  }

  async marcarTodasComoLidas(usuarioId) {
    return await notificacoesRepository.marcarTodasComoLidas(usuarioId);
  }

  async countNaoLidas(usuarioId) {
    const count = await notificacoesRepository.countNaoLidas(usuarioId);
    return { count };
  }

  async delete(id, usuarioId) {
    const notificacao = await notificacoesRepository.findById(id);
    if (!notificacao) {
      throw new ApiError(404, 'Notificação não encontrada.', null, 'NOT_FOUND');
    }
    if (notificacao.usuario_id !== usuarioId) {
      throw new ApiError(403, 'Você não tem permissão para excluir esta notificação.', null, 'FORBIDDEN');
    }
    return await notificacoesRepository.delete(id, usuarioId);
  }
}

module.exports = new NotificacoesService();


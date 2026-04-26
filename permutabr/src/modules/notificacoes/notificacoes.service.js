// /src/modules/notificacoes/notificacoes.service.js

const notificacoesRepository = require('./notificacoes.repository');
const policiaisRepository = require('../policiais/policiais.repository');
const emailService = require('../../core/services/email.service');
const ApiError = require('../../core/utils/ApiError');
const logger = require('../../core/utils/logger');

class NotificacoesService {
  async getNotificacoes(usuarioId) {
    return await notificacoesRepository.findAllByUsuario(usuarioId);
  }

  async criarSolicitacaoContato(solicitanteId, destinatarioId, origem = null, tipoPermuta = null) {
    // Busca dados do solicitante
    const solicitante = await policiaisRepository.findProfileById(solicitanteId);
    if (!solicitante) {
      throw new ApiError(404, 'Solicitante não encontrado.', null, 'NOT_FOUND');
    }

    // Busca dados do destinatário para enviar email
    const destinatario = await policiaisRepository.findProfileById(destinatarioId);
    if (!destinatario) {
      throw new ApiError(404, 'Destinatário não encontrado.', null, 'NOT_FOUND');
    }

    // Verifica se já existe notificação pendente
    const notificacoes = await notificacoesRepository.findAllByUsuario(destinatarioId);
    const notificacaoExistente = notificacoes.find(
      n => n.tipo === 'SOLICITACAO_CONTATO' && 
           n.referencia_id === solicitanteId && 
           n.lida === 0
    );

    // ✅ CORREÇÃO: Se já existe solicitação pendente, retorna sucesso (não erro)
    // O email já foi enviado na primeira solicitação, então não precisa enviar novamente
    if (notificacaoExistente) {
      // Adiciona flag para indicar que já existia
      return { ...notificacaoExistente, already_exists: true };
    }

    const titulo = 'Solicitação de Contato';
    const mensagem = `O usuário ${solicitante.nome} solicitou seu contato.`;

    // Cria a notificação
    const notificacao = await notificacoesRepository.create({
      usuario_id: destinatarioId,
      tipo: 'SOLICITACAO_CONTATO',
      referencia_id: solicitanteId,
      titulo,
      mensagem,
    });

    // ✅ CORREÇÃO: Envia email de notificação se o destinatário tiver email
    // Usa origem ou fallback para 'permuta' se não fornecida
    logger.debug('Verificando envio de email', {
      destinatarioId,
      temEmail: !!destinatario.email,
      origem,
      origemType: typeof origem
    });

    if (destinatario.email) {
      try {
        const dadosEmail = {
          solicitanteNome: solicitante.nome || 'Usuário',
          solicitanteForca: solicitante.forca_sigla || solicitante.forca_nome || null,
          solicitanteEstado: solicitante.estado_atual_sigla || null,
          solicitanteCidade: solicitante.municipio_atual_nome || null,
        };

        // ✅ CORREÇÃO: Normaliza a origem (trim + lowercase) para comparação mais robusta
        const origemNormalizada = origem ? origem.trim().toLowerCase() : '';
        const origemFinal = origemNormalizada === 'mapa' ? 'mapa' : 'permuta';

        logger.debug('Preparando para enviar email', {
          origemOriginal: origem,
          origemNormalizada,
          origemFinal
        });

        if (origemFinal === 'mapa') {
          logger.debug('Enviando email de solicitação de contato (mapa)');
          await emailService.sendContactRequestFromMapEmail(destinatario.email, dadosEmail);
        } else {
          // Para permuta ou origem não especificada
          // ✅ Determina o tipo de permuta baseado no parâmetro recebido
          let tipoPermutaTexto = 'Permuta Fechada';
          if (tipoPermuta === 'direta') {
            tipoPermutaTexto = 'Permuta Direta';
          } else if (tipoPermuta === 'triangular') {
            tipoPermutaTexto = 'Permuta Triangular';
          } else if (tipoPermuta === 'interessado') {
            tipoPermutaTexto = 'Você possui interesse no estado/município/unidade do solicitante';
          }
          dadosEmail.tipoPermuta = tipoPermutaTexto;
          logger.debug('Enviando email de solicitação de contato (permuta)', { tipo: tipoPermutaTexto });
          await emailService.sendContactRequestFromPermutaEmail(destinatario.email, dadosEmail);
        }
        logger.debug('Email de solicitação de contato enviado com sucesso');
      } catch (emailError) {
        // Log detalhado do erro mas não falha a criação da notificação
        logger.error('Erro ao enviar email de notificação de solicitação de contato', {
          error: emailError.message,
          stack: emailError.stack,
          origem: origem,
          hasMailConfig: !!(process.env.MAIL_HOST && process.env.MAIL_USER)
        });
      }
    } else {
      logger.warn('Email não enviado: destinatário não possui email cadastrado', {
        destinatarioId
      });
    }

    return notificacao;
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

    // Busca dados do solicitante para enviar email
    const solicitante = await policiaisRepository.findProfileById(notificacao.referencia_id);
    if (!solicitante) {
      throw new ApiError(404, 'Solicitante não encontrado.', null, 'NOT_FOUND');
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

      // Envia email de notificação se o solicitante tiver email
      if (solicitante.email) {
        try {
          const dadosEmail = {
            respondenteNome: respondente.nome || 'Usuário',
            respondenteForca: respondente.forca_sigla || respondente.forca_nome || null,
            respondenteEstado: respondente.estado_atual_sigla || null,
            respondenteCidade: respondente.municipio_atual_nome || null,
            respondenteUnidade: respondente.unidade_atual_nome || null,
            respondentePosto: respondente.posto_graduacao_nome || null,
            respondenteTelefone: (respondente.qso && !respondente.ocultar_no_mapa) ? respondente.qso : null,
          };
          await emailService.sendContactRequestAcceptedEmail(solicitante.email, dadosEmail);
        } catch (emailError) {
          // Log do erro mas não falha a criação da notificação
          logger.error('Erro ao enviar email de solicitação aceita', { error: emailError.message });
        }
      }
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

      // Envia email de notificação se o solicitante tiver email
      if (solicitante.email) {
        try {
          const dadosEmail = {
            respondenteNome: respondente.nome || 'Usuário',
          };
          await emailService.sendContactRequestRejectedEmail(solicitante.email, dadosEmail);
        } catch (emailError) {
          // Log do erro mas não falha a criação da notificação
          logger.error('Erro ao enviar email de solicitação negada', { error: emailError.message });
        }
      }
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


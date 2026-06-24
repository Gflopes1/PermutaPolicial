// /src/modules/admin/admin.service.js

const adminRepository = require('./admin.repository');
const problemasService = require('../problemas/problemas.service');
const emailService = require('../../core/services/email.service');
const ApiError = require('../../core/utils/ApiError');
const logger = require('../../core/utils/logger');

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

class AdminService {
  async getEstatisticas() {
    return adminRepository.getEstatisticas();
  }

  async getPermutasConcluidas() {
    return adminRepository.findPermutasConcluidasFeedback();
  }

  async getProblemaRelatos(query = {}) {
    return problemasService.buscarRelatos({
      status: query.status || null,
      pagina: query.pagina || null,
      usuario_id: query.usuario_id ? parseInt(query.usuario_id, 10) : null,
      dataInicio: query.data_inicio || null,
      dataFim: query.data_fim || null,
      page: query.page ? parseInt(query.page, 10) : 1,
      perPage: query.per_page ? parseInt(query.per_page, 10) : 50,
    });
  }

  async atualizarProblemaRelatoStatus(id, status, resolvidoPor, resolucao) {
    return problemasService.atualizarStatus(id, status, resolvidoPor, resolucao);
  }

  async getSugestoes() {
    return adminRepository.findSugestoesPendentes();
  }

  async aprovarSugestao(sugestaoId) {
    await adminRepository.aprovarSugestao(sugestaoId);
    return { message: 'Sugestão aprovada e nova unidade criada.' };
  }

  async rejeitarSugestao(sugestaoId) {
    const success = await adminRepository.updateStatusSugestao(sugestaoId, 'REJEITADA');
    if (!success) {
      throw new ApiError(404, 'Sugestão não encontrada ou já processada.');
    }
    return { message: 'Sugestão rejeitada.' };
  }

  async getVerificacoes() {
    return adminRepository.findVerificacoesPendentes();
  }

  async verificarPolicial(policialId) {
    const success = await adminRepository.updateStatusPolicial(policialId, 'VERIFICADO');
    if (!success) {
      throw new ApiError(404, 'Policial não encontrado ou já processado.');
    }
    return { message: 'Policial verificado com sucesso.' };
  }
  
  async rejeitarPolicial(policialId) {
    const success = await adminRepository.updateStatusPolicial(policialId, 'REJEITADO');
    if (!success) {
        throw new ApiError(404, 'Policial não encontrado ou já processado.');
    }
    return { message: 'Policial rejeitado com sucesso.' };
  }

  async getAllPoliciais(filters) {
    const [policiais, total] = await Promise.all([
      adminRepository.findAllPoliciais(filters),
      adminRepository.countPoliciais(filters),
    ]);
    return { policiais, total };
  }

  async getPolicialDetalhes(policialId) {
    const policiaisRepository = require('../policiais/policiais.repository');
    const intencoesRepository = require('../intencoes/intencoes.repository');
    const { computeMatchesForPolicial } = require('../permutas-inteligentes/permutas-inteligentes.service');

    const profile = await policiaisRepository.findProfileById(policialId);
    if (!profile) {
      throw new ApiError(404, 'Policial não encontrado.');
    }

    const intencoes = await intencoesRepository.findByPolicialId(policialId);

    let matches = {
      total: 0,
      diretas: [],
      proximas: 0,
      interessados: 0,
      triangulares: 0,
      ciclos_n: 0,
    };

    try {
      const resultado = await computeMatchesForPolicial(policialId);
      matches = {
        total:
          (resultado.diretas?.length || 0) +
          (resultado.proximas?.length || 0) +
          (resultado.interessados?.length || 0) +
          (resultado.triangulares?.length || 0) +
          (resultado.ciclos_n?.length || 0),
        diretas: (resultado.diretas || []).slice(0, 8).map((m) => ({
          id: m.id,
          nome: m.nome,
          municipio_atual: m.municipio_atual,
          descricao: m.descricao_interesse,
        })),
        proximas: resultado.proximas?.length || 0,
        interessados: resultado.interessados?.length || 0,
        triangulares: resultado.triangulares?.length || 0,
        ciclos_n: resultado.ciclos_n?.length || 0,
      };
    } catch (err) {
      logger.warn('Admin: falha ao carregar matches do policial %s: %s', policialId, err.message);
    }

    return {
      lotacao: {
        unidade: profile.unidade_atual_nome,
        municipio: profile.municipio_atual_nome,
        estado: profile.estado_atual_sigla,
      },
      intencoes,
      matches,
    };
  }

  async updatePolicial(policialId, updateData, adminUserId) {
    const targetId = parseInt(policialId, 10);
    const adminId = parseInt(adminUserId, 10);
    const sanitized = { ...updateData };

    if (targetId === adminId) {
      delete sanitized.is_moderator;
      delete sanitized.embaixador;
      delete sanitized.is_premium;
    }

    const adminUser = await adminRepository.findPolicialById(adminId);
    const isEmbaixador = adminUser && (adminUser.embaixador === 1);
    if (!isEmbaixador) {
      delete sanitized.is_moderator;
      delete sanitized.embaixador;
      delete sanitized.is_premium;
    }

    const success = await adminRepository.updatePolicial(targetId, sanitized);
    if (!success) {
      throw new ApiError(404, 'Policial não encontrado ou nenhum campo válido para atualizar.');
    }
    return { message: 'Policial atualizado com sucesso.' };
  }

  async getConfiguracoes() {
    return await adminRepository.getConfiguracoes();
  }

  async updateConfiguracoes(updateData) {
    const success = await adminRepository.updateConfiguracoes(updateData);
    if (!success) {
      throw new ApiError(400, 'Nenhum campo válido para atualizar.');
    }
    return { message: 'Configurações atualizadas com sucesso.' };
  }

  async getPremiumUsers(filters) {
    const [users, total] = await Promise.all([
      adminRepository.getPremiumUsers(filters),
      adminRepository.countPremiumUsers(filters),
    ]);
    return { users, total };
  }

  async deletePolicial(policialId, adminUserId) {
    if (parseInt(policialId, 10) === parseInt(adminUserId, 10)) {
      throw new ApiError(400, 'Você não pode excluir a própria conta pelo painel admin.', null, 'CANNOT_DELETE_SELF');
    }

    const success = await adminRepository.deletePolicial(policialId);
    if (!success) {
      throw new ApiError(404, 'Usuário não encontrado.', null, 'POLICIAL_NOT_FOUND');
    }
    return { message: 'Conta excluída com sucesso.' };
  }

  async sendBulkEmail({ subject, body }) {
    if (!subject?.trim() || !body?.trim()) {
      throw new ApiError(400, 'Assunto e corpo da mensagem são obrigatórios.', null, 'VALIDATION_ERROR');
    }

    const recipients = await adminRepository.findBroadcastRecipients();
    const total = recipients.length;

    if (total === 0) {
      return { sent: 0, failed: 0, total: 0, status: 'completed', message: 'Nenhum destinatário encontrado.' };
    }

    setImmediate(() => {
      this._processBulkEmail(subject.trim(), body.trim(), recipients).catch((err) => {
        logger.error('Erro no envio em massa em background', { error: err.message });
      });
    });

    return {
      sent: 0,
      failed: 0,
      total,
      status: 'processing',
      message: `Envio iniciado em background para ${total} destinatário(s).`,
    };
  }

  async _processBulkEmail(subject, body, recipients) {
    let sent = 0;
    let failed = 0;

    for (const recipient of recipients) {
      const nome = recipient.nome || 'usuário';
      const personalizedText = body.replace(/\{\{nome\}\}/gi, nome);
      const personalizedParagraphs = personalizedText.split(/\n\s*\n/).filter(Boolean);
      const bodyHtml = personalizedParagraphs
        .map((p) => `<p style="font-size: 16px; line-height: 1.6; color: #333;">${escapeHtml(p).replace(/\n/g, '<br>')}</p>`)
        .join('');

      try {
        await emailService.sendAdminBroadcastEmail(recipient.email, {
          subject,
          bodyHtml,
          bodyText: personalizedText,
        });
        sent += 1;
      } catch (error) {
        failed += 1;
        logger.error('Falha ao enviar email em massa', {
          email: recipient.email,
          error: error.message,
        });
      }
    }

    logger.info('Envio em massa concluído', { sent, failed, total: recipients.length });
  }
}

module.exports = new AdminService();
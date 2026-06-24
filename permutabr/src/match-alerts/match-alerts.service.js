const matchAlertsRepository = require('./match-alerts.repository');
const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const { sendPushToUser } = require('../push/push.sender');

function buildMatchEntries(matchesResult) {
  const entries = [];

  for (const m of matchesResult.diretas || []) {
    entries.push({
      chave: `DIRETA:${m.id}`,
      tipo: 'DIRETA',
      referenciaId: m.id,
      titulo: 'Nova permuta direta!',
      mensagem: `Encontramos uma permuta direta compatível com você (${m.municipio_atual || 'local não informado'}).`,
    });
  }

  for (const m of matchesResult.interessados || []) {
    entries.push({
      chave: `INTERESSADO:${m.id}`,
      tipo: 'INTERESSADO',
      referenciaId: m.id,
      titulo: 'Novo interessado na sua região',
      mensagem: `Um policial demonstrou interesse compatível com sua lotação (${m.descricao_interesse || 'ver detalhes'}).`,
    });
  }

  for (const t of matchesResult.triangulares || []) {
    const bId = t.policialB?.id || t.policial_b_id;
    const cId = t.policialC?.id || t.policial_c_id;
    if (bId && cId) {
      entries.push({
        chave: `TRIANGULAR:${bId}:${cId}`,
        tipo: 'TRIANGULAR',
        referenciaId: bId,
        titulo: 'Nova permuta triangular!',
        mensagem: 'Encontramos uma combinação triangular envolvendo você.',
      });
    }
  }

  return entries;
}

class MatchAlertsService {
  async processMatchesForUser(usuarioId, matchesResult) {
    const ativo = await matchAlertsRepository.isAlertasAtivo(usuarioId);
    if (!ativo) return { notificados: 0 };

    const entries = buildMatchEntries(matchesResult);
    let notificados = 0;

    for (const entry of entries) {
      const jaNotificado = await matchAlertsRepository.wasAlreadyNotified(
        usuarioId,
        entry.chave
      );
      if (jaNotificado) continue;

      await notificacoesRepository.create({
        usuario_id: usuarioId,
        tipo: 'NOVO_MATCH',
        referencia_id: entry.referenciaId,
        titulo: entry.titulo,
        mensagem: entry.mensagem,
      });

      await matchAlertsRepository.registerNotification(
        usuarioId,
        entry.chave,
        entry.tipo
      );

      await sendPushToUser(usuarioId, {
        title: entry.titulo,
        body: entry.mensagem,
        data: { tipo: 'NOVO_MATCH', referencia_id: entry.referenciaId },
      });

      notificados += 1;
    }

    return { notificados };
  }

  async runScheduledScan() {
    const userIds = await matchAlertsRepository.findUsuariosParaVarredura(80);
    const permutasService = require('../permutas/permutas.service');
    let totalNotificados = 0;

    for (const userId of userIds) {
      try {
        const matches = await permutasService.findMatchesForPolicial(userId);
        const { notificados } = await this.processMatchesForUser(userId, matches);
        totalNotificados += notificados;
      } catch (error) {
        console.error(`[match-alerts] Erro ao varrer usuário ${userId}:`, error.message);
      }
    }

    return { usuarios_varridos: userIds.length, notificados: totalNotificados };
  }
}

module.exports = new MatchAlertsService();

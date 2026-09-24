// Serviço de avisos por email e registro de permutas por expiração de intenções

const db = require('../../config/db');
const emailService = require('./email.service');
const logger = require('../../core/utils/logger');

class IntencoesExpirationService {
  /**
   * Envia email para policiais com intenções que expiram em até 7 dias.
   */
  async sendExpirationWarnings() {
    const [rows] = await db.execute(`
      SELECT
        p.id AS policial_id,
        p.email,
        p.nome,
        COUNT(i.id) AS quantidade_intencoes,
        MIN(COALESCE(i.renovado_em, i.criado_em)) AS data_referencia,
        DATE_ADD(MIN(COALESCE(i.renovado_em, i.criado_em)), INTERVAL 6 MONTH) AS expira_em
      FROM policiais p
      JOIN intencoes i ON i.policial_id = p.id
      LEFT JOIN intencoes_avisos_email av ON av.policial_id = p.id AND av.tipo = 'AVISO_7_DIAS'
      WHERE p.email IS NOT NULL
        AND p.email <> ''
        AND av.id IS NULL
        AND DATE_ADD(COALESCE(i.renovado_em, i.criado_em), INTERVAL 6 MONTH) > NOW()
        AND DATE_ADD(COALESCE(i.renovado_em, i.criado_em), INTERVAL 6 MONTH) <= DATE_ADD(NOW(), INTERVAL 7 DAY)
      GROUP BY p.id, p.email, p.nome
    `);

    let enviados = 0;
    for (const row of rows) {
      const diasRestantes = Math.max(
        0,
        Math.ceil((new Date(row.expira_em) - new Date()) / (1000 * 60 * 60 * 24))
      );

      try {
        await emailService.sendIntencoesExpiringSoonEmail(row.email, {
          nome: row.nome,
          quantidadeIntencoes: row.quantidade_intencoes,
          diasRestantes,
          expiraEm: row.expira_em,
        });

        await db.execute(
          'INSERT INTO intencoes_avisos_email (policial_id, tipo) VALUES (?, ?)',
          [row.policial_id, 'AVISO_7_DIAS']
        );
        enviados += 1;
      } catch (error) {
        logger.error('Erro ao enviar aviso de expiração', {
          policialId: row.policial_id,
          error: error.message,
        });
      }
    }

    logger.log(`Avisos de expiração de intenções enviados: ${enviados}`);
    return { enviados, candidatos: rows.length };
  }

  async clearWarningsForPolicial(policialId) {
    await db.execute('DELETE FROM intencoes_avisos_email WHERE policial_id = ?', [policialId]);
  }
}

module.exports = new IntencoesExpirationService();

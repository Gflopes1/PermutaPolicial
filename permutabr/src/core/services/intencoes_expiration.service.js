// Serviço de avisos por email e registro de permutas por expiração de intenções

const db = require('../../config/db');
const emailService = require('./email.service');
const intencoesRepository = require('../../modules/intencoes/intencoes.repository');
const logger = require('../../core/utils/logger');

class IntencoesExpirationService {
  async ensureSchema() {
    await intencoesRepository.ensureFeedbackSchema();
    await intencoesRepository.ensureMetadataSchema();

    await db.execute(`
      CREATE TABLE IF NOT EXISTS intencoes_avisos_email (
        id INT AUTO_INCREMENT PRIMARY KEY,
        policial_id INT NOT NULL,
        tipo ENUM('AVISO_7_DIAS') NOT NULL DEFAULT 'AVISO_7_DIAS',
        enviado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_policial_tipo (policial_id, tipo),
        CONSTRAINT fk_intencoes_avisos_policial
          FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
      )
    `);

    const [origemColumn] = await db.execute(
      "SHOW COLUMNS FROM permutas_concluidas_feedback LIKE 'origem'"
    );
    if (origemColumn.length === 0) {
      await db.execute(
        "ALTER TABLE permutas_concluidas_feedback ADD COLUMN origem ENUM('MANUAL', 'EXPIRACAO') NOT NULL DEFAULT 'MANUAL'"
      );
    }
  }

  /**
   * Envia email para policiais com intenções que expiram em até 7 dias.
   */
  async sendExpirationWarnings() {
    await this.ensureSchema();

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
        console.error(`Erro ao enviar aviso de expiração para policial ${row.policial_id}:`, error.message);
      }
    }

    logger.log(`📧 Avisos de expiração de intenções enviados: ${enviados}`);
    return { enviados, candidatos: rows.length };
  }

  /**
   * Remove avisos pendentes após renovação (para permitir novo aviso no próximo ciclo).
   */
  async clearWarningsForPolicial(policialId) {
    await this.ensureSchema();
    await db.execute('DELETE FROM intencoes_avisos_email WHERE policial_id = ?', [policialId]);
  }
}

module.exports = new IntencoesExpirationService();

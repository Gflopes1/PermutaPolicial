// /src/modules/intencoes/intencoes.repository.js

const db = require('../../config/db');

let metadataSchemaEnsured = false;
let feedbackSchemaEnsured = false;
let historicoSchemaEnsured = false;
let raioKmSchemaEnsured = false;

const MOTIVOS_ARQUIVO = {
  ATUALIZACAO: 'ATUALIZACAO',
  EXCLUSAO: 'EXCLUSAO',
  PERMUTA_CONCLUIDA: 'PERMUTA_CONCLUIDA',
  EXPIRACAO: 'EXPIRACAO',
  CONTA_REMOVIDA: 'CONTA_REMOVIDA',
};

class IntencoesRepository {
  async ensureHistoricoSchema(connection = db) {
    if (historicoSchemaEnsured) return;

    await connection.execute(`
      CREATE TABLE IF NOT EXISTS intencoes_historico (
        id INT AUTO_INCREMENT PRIMARY KEY,
        intencao_id INT NULL,
        policial_id INT NOT NULL,
        prioridade TINYINT NOT NULL,
        tipo_intencao ENUM('ESTADO', 'MUNICIPIO', 'UNIDADE') NOT NULL,
        estado_id INT NULL,
        municipio_id INT NULL,
        unidade_id INT NULL,
        unidade_atual_id INT NULL,
        municipio_atual_id INT NULL,
        raio_km SMALLINT UNSIGNED NULL,
        criado_em TIMESTAMP NULL,
        renovado_em TIMESTAMP NULL,
        forca_id INT NULL,
        municipio_origem_id INT NULL,
        posto_graduacao_id INT NULL,
        arquivado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        motivo ENUM(
          'ATUALIZACAO',
          'EXCLUSAO',
          'PERMUTA_CONCLUIDA',
          'EXPIRACAO',
          'CONTA_REMOVIDA'
        ) NOT NULL,
        INDEX idx_historico_policial (policial_id, arquivado_em),
        INDEX idx_historico_motivo (motivo, arquivado_em),
        INDEX idx_historico_destino (tipo_intencao, municipio_id, estado_id),
        CONSTRAINT fk_intencoes_historico_policial
          FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);

    historicoSchemaEnsured = true;
  }

  async ensureRaioKmSchema(connection = db) {
    if (raioKmSchemaEnsured) return;

    const [raioColumn] = await connection.execute(
      "SHOW COLUMNS FROM intencoes LIKE 'raio_km'"
    );
    if (raioColumn.length === 0) {
      await connection.execute(
        'ALTER TABLE intencoes ADD COLUMN raio_km SMALLINT UNSIGNED NULL COMMENT \'Raio aceitável em km (NULL = match exato)\''
      );
    }

    raioKmSchemaEnsured = true;
  }

  async ensureMetadataSchema(connection = db) {
    if (metadataSchemaEnsured) return;

    const [criadoEmColumn] = await connection.execute(
      "SHOW COLUMNS FROM intencoes LIKE 'criado_em'"
    );
    if (criadoEmColumn.length === 0) {
      await connection.execute(
        'ALTER TABLE intencoes ADD COLUMN criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
      );
    }

    const [renovadoEmColumn] = await connection.execute(
      "SHOW COLUMNS FROM intencoes LIKE 'renovado_em'"
    );
    if (renovadoEmColumn.length === 0) {
      await connection.execute(
        'ALTER TABLE intencoes ADD COLUMN renovado_em TIMESTAMP NULL DEFAULT NULL'
      );
    }

    metadataSchemaEnsured = true;
  }

  async ensureFeedbackSchema(connection = db) {
    if (feedbackSchemaEnsured) return;

    await connection.execute(`
      CREATE TABLE IF NOT EXISTS permutas_concluidas_feedback (
        id INT AUTO_INCREMENT PRIMARY KEY,
        policial_id INT NOT NULL,
        quantidade_intencoes INT NOT NULL DEFAULT 0,
        origem ENUM('MANUAL', 'EXPIRACAO') NOT NULL DEFAULT 'MANUAL',
        criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_policial_id (policial_id),
        CONSTRAINT fk_permutas_concluidas_policial
          FOREIGN KEY (policial_id) REFERENCES policiais(id)
          ON DELETE CASCADE
      )
    `);

    const [origemColumn] = await connection.execute(
      "SHOW COLUMNS FROM permutas_concluidas_feedback LIKE 'origem'"
    );
    if (origemColumn.length === 0) {
      await connection.execute(
        "ALTER TABLE permutas_concluidas_feedback ADD COLUMN origem ENUM('MANUAL', 'EXPIRACAO') NOT NULL DEFAULT 'MANUAL'"
      );
    }

    feedbackSchemaEnsured = true;
  }

  async ensureAllSchemas(connection = db) {
    await this.ensureMetadataSchema(connection);
    await this.ensureRaioKmSchema(connection);
    await this.ensureHistoricoSchema(connection);
    await this.ensureFeedbackSchema(connection);
  }

  /**
   * Copia intenções para historico e remove da tabela ativa.
   * @param {string} extraWhere - cláusula AND adicional (ex: 'AND COALESCE(i.renovado_em, i.criado_em) < ?')
   * @param {Array} extraParams - parâmetros do extraWhere (antes de policialId se usado)
   */
  async archiveAndDelete(connection, { policialId, motivo, extraWhere = '', extraParams = [] }) {
    await this.ensureAllSchemas(connection);

    const wherePolicial = policialId != null ? 'AND i.policial_id = ?' : '';
    const archiveParams = [motivo, ...extraParams];
    if (policialId != null) {
      archiveParams.push(policialId);
    }

    await connection.execute(
      `INSERT INTO intencoes_historico (
        intencao_id, policial_id, prioridade, tipo_intencao,
        estado_id, municipio_id, unidade_id,
        unidade_atual_id, municipio_atual_id,
        raio_km, criado_em, renovado_em,
        forca_id, municipio_origem_id, posto_graduacao_id,
        motivo
      )
      SELECT
        i.id, i.policial_id, i.prioridade, i.tipo_intencao,
        i.estado_id, i.municipio_id, i.unidade_id,
        i.unidade_atual_id, i.municipio_atual_id,
        i.raio_km, i.criado_em, i.renovado_em,
        p.forca_id,
        COALESCE(p.municipio_atual_id, u_lot.municipio_id, i.municipio_atual_id),
        p.posto_graduacao_id,
        ?
      FROM intencoes i
      JOIN policiais p ON p.id = i.policial_id
      LEFT JOIN unidades u_lot ON u_lot.id = p.unidade_atual_id
      WHERE 1=1 ${extraWhere} ${wherePolicial}`,
      archiveParams
    );

    const deleteParams = [...extraParams];
    if (policialId != null) {
      deleteParams.push(policialId);
    }

    const [result] = await connection.execute(
      `DELETE i FROM intencoes i WHERE 1=1 ${extraWhere.replace(/i\./g, 'i.')} ${wherePolicial}`,
      deleteParams
    );

    return result.affectedRows;
  }

  async syncLotacaoFromProfile(policialId, unidadeAtualId, municipioAtualId) {
    const [result] = await db.execute(
      `UPDATE intencoes
       SET unidade_atual_id = ?, municipio_atual_id = ?
       WHERE policial_id = ?`,
      [unidadeAtualId || null, municipioAtualId || null, policialId]
    );
    return result.affectedRows;
  }

  async findByPolicialId(policialId) {
    await this.ensureAllSchemas();
    const query = `
        SELECT
            i.id, i.prioridade, i.tipo_intencao,
            i.estado_id, i.municipio_id, i.unidade_id,
            i.unidade_atual_id, i.municipio_atual_id,
            i.raio_km,
            i.criado_em, i.renovado_em,
            e.sigla as estado_sigla,
            m.nome as municipio_nome,
            u.nome as unidade_nome,
            u_atual.nome as unidade_atual_nome,
            m_atual.nome as municipio_atual_nome
        FROM intencoes i
        LEFT JOIN estados e ON i.estado_id = e.id
        LEFT JOIN municipios m ON i.municipio_id = m.id
        LEFT JOIN unidades u ON i.unidade_id = u.id
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_atual ON i.municipio_atual_id = m_atual.id
        WHERE i.policial_id = ?
        ORDER BY i.prioridade ASC
    `;
    const [intencoes] = await db.execute(query, [policialId]);
    return intencoes;
  }

  async replaceAll(policialId, intencoes) {
    await this.ensureAllSchemas();
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [policialRows] = await connection.execute(
        'SELECT unidade_atual_id, municipio_atual_id FROM policiais WHERE id = ?',
        [policialId]
      );

      if (policialRows.length === 0) {
        throw new Error('Policial não encontrado');
      }

      const policial = policialRows[0];
      let unidadeAtualId = policial.unidade_atual_id;
      let municipioAtualId = policial.municipio_atual_id;

      if (!municipioAtualId && unidadeAtualId) {
        const [unidadeRows] = await connection.execute(
          'SELECT municipio_id FROM unidades WHERE id = ?',
          [unidadeAtualId]
        );
        if (unidadeRows.length > 0) {
          municipioAtualId = unidadeRows[0].municipio_id;
        }
      }

      await this.archiveAndDelete(connection, {
        policialId,
        motivo: MOTIVOS_ARQUIVO.ATUALIZACAO,
      });

      if (intencoes.length > 0) {
        const query = `
            INSERT INTO intencoes (
              policial_id, prioridade, tipo_intencao,
              estado_id, municipio_id, unidade_id,
              unidade_atual_id, municipio_atual_id, raio_km
            )
            VALUES ?
        `;
        const values = intencoes.map((i) => [
          policialId,
          i.prioridade,
          i.tipo_intencao,
          i.estado_id || null,
          i.municipio_id || null,
          i.unidade_id || null,
          unidadeAtualId || null,
          municipioAtualId || null,
          i.raio_km ?? null,
        ]);
        await connection.query(query, [values]);
      }

      await connection.commit();

      setImmediate(() => {
        try {
          const cacheRepo = require('../permutas-inteligentes/permutas-inteligentes.cache.repository');
          cacheRepo.invalidateUserCache(policialId).catch(() => {});
        } catch (_) {}
      });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async deleteAll(policialId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const deleted = await this.archiveAndDelete(connection, {
        policialId,
        motivo: MOTIVOS_ARQUIVO.EXCLUSAO,
      });
      await connection.commit();
      return deleted;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async renewAll(policialId) {
    await this.ensureMetadataSchema();
    const [result] = await db.execute(
      'UPDATE intencoes SET renovado_em = CURRENT_TIMESTAMP WHERE policial_id = ?',
      [policialId]
    );
    try {
      await db.execute('DELETE FROM intencoes_avisos_email WHERE policial_id = ?', [policialId]);
    } catch (_) {
      // Tabela pode ainda não existir em ambientes antigos
    }
    return result.affectedRows;
  }

  async markPermutaConcluida(policialId) {
    await this.ensureFeedbackSchema();
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [intencoes] = await connection.execute(
        'SELECT COUNT(*) as total FROM intencoes WHERE policial_id = ?',
        [policialId]
      );
      const quantidade = intencoes[0]?.total || 0;

      await connection.execute(
        'INSERT INTO permutas_concluidas_feedback (policial_id, quantidade_intencoes, origem) VALUES (?, ?, ?)',
        [policialId, quantidade, 'MANUAL']
      );

      await this.archiveAndDelete(connection, {
        policialId,
        motivo: MOTIVOS_ARQUIVO.PERMUTA_CONCLUIDA,
      });

      await connection.commit();

      return { quantidade };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async archiveExpiredBefore(cutoffDate) {
    const connection = await db.getConnection();
    try {
      await this.ensureAllSchemas(connection);
      await connection.beginTransaction();

      const [expiredByPolicial] = await connection.execute(
        `SELECT policial_id, COUNT(*) as total
         FROM intencoes
         WHERE COALESCE(renovado_em, criado_em) < ?
         GROUP BY policial_id`,
        [cutoffDate]
      );

      for (const row of expiredByPolicial) {
        await connection.execute(
          'INSERT INTO permutas_concluidas_feedback (policial_id, quantidade_intencoes, origem) VALUES (?, ?, ?)',
          [row.policial_id, row.total, 'EXPIRACAO']
        );
        try {
          await connection.execute(
            'DELETE FROM intencoes_avisos_email WHERE policial_id = ?',
            [row.policial_id]
          );
        } catch (_) {
          // Tabela de avisos pode ainda não existir
        }
      }

      const deleted = await this.archiveAndDelete(connection, {
        policialId: null,
        motivo: MOTIVOS_ARQUIVO.EXPIRACAO,
        extraWhere: 'AND COALESCE(i.renovado_em, i.criado_em) < ?',
        extraParams: [cutoffDate],
      });

      await connection.commit();
      return { deleted, permutasPorExpiracao: expiredByPolicial.length };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async archiveForAccountRemoval(connection, policialId) {
    await this.ensureAllSchemas(connection);
    return this.archiveAndDelete(connection, {
      policialId,
      motivo: MOTIVOS_ARQUIVO.CONTA_REMOVIDA,
    });
  }
}

module.exports = new IntencoesRepository();
module.exports.MOTIVOS_ARQUIVO = MOTIVOS_ARQUIVO;

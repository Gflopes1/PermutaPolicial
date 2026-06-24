const db = require('../../config/db');

class EditaisRepository {
  async getWhatsappConfig() {
    const [rows] = await db.execute(
      `SELECT chave, valor FROM configuracoes_gerais
       WHERE chave IN ('editais_whatsapp_numero', 'editais_whatsapp_mensagem')`
    );
    const map = Object.fromEntries(rows.map((r) => [r.chave, r.valor]));
    return {
      numero: map.editais_whatsapp_numero || '5551986200626',
      mensagem:
        map.editais_whatsapp_mensagem ||
        'Olá, gostaria de enviar um edital de transferência ou de novos agentes para adicionar ao site',
    };
  }

  async updateWhatsappConfig({ numero, mensagem }) {
    if (numero !== undefined) {
      await db.execute(
        `INSERT INTO configuracoes_gerais (chave, valor) VALUES ('editais_whatsapp_numero', ?)
         ON DUPLICATE KEY UPDATE valor = ?`,
        [numero, numero]
      );
    }
    if (mensagem !== undefined) {
      await db.execute(
        `INSERT INTO configuracoes_gerais (chave, valor) VALUES ('editais_whatsapp_mensagem', ?)
         ON DUPLICATE KEY UPDATE valor = ?`,
        [mensagem, mensagem]
      );
    }
    return this.getWhatsappConfig();
  }

  async listPublic({ status, forcaIdUsuario }) {
    const params = [status];
    const [rows] = await db.execute(
      `SELECT e.id, e.tipo, e.forca_id, e.titulo, e.resumo, e.link_pdf,
              e.data_abertura, e.data_encerramento, e.status, e.criterio_label,
              e.criado_em,
              f.sigla AS forca_sigla, f.nome AS forca_nome,
              (e.forca_id = ?) AS destacar_forca,
              (SELECT COUNT(*) FROM edital_vagas v WHERE v.edital_id = e.id) AS total_vagas
       FROM editais e
       JOIN forcas_policiais f ON f.id = e.forca_id
       WHERE e.status = ?
       ORDER BY destacar_forca DESC, e.criado_em DESC`,
      [forcaIdUsuario || 0, status]
    );
    return rows;
  }

  async findById(id) {
    const [rows] = await db.execute(
      `SELECT e.*, f.sigla AS forca_sigla, f.nome AS forca_nome
       FROM editais e
       JOIN forcas_policiais f ON f.id = e.forca_id
       WHERE e.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  async findParticipanteByEditalAndIdFuncional(editalId, idFuncional) {
    const [rows] = await db.execute(
      `SELECT * FROM edital_participantes
       WHERE edital_id = ? AND id_funcional = ?`,
      [editalId, String(idFuncional)]
    );
    return rows[0] || null;
  }

  async linkPolicialToParticipante(editalId, idFuncional, policialId) {
    await db.execute(
      `UPDATE edital_participantes SET policial_id = ?
       WHERE edital_id = ? AND id_funcional = ? AND (policial_id IS NULL OR policial_id = ?)`,
      [policialId, editalId, String(idFuncional), policialId]
    );
  }

  async getVagasByEdital(editalId) {
    const [rows] = await db.execute(
      `SELECT id, edital_id, crpm, opm, unidade_nome, vagas_disponiveis, ordem
       FROM edital_vagas WHERE edital_id = ?
       ORDER BY ordem ASC, crpm ASC, opm ASC`,
      [editalId]
    );
    return rows;
  }

  async getIntencoes(policialId, editalId) {
    const [rows] = await db.execute(
      `SELECT escolha_1_vaga_id, escolha_2_vaga_id, escolha_3_vaga_id
       FROM edital_intencoes WHERE policial_id = ? AND edital_id = ?`,
      [policialId, editalId]
    );
    return rows[0] || null;
  }

  async saveIntencoes(policialId, editalId, { escolha1, escolha2, escolha3 }) {
    await db.execute(
      `INSERT INTO edital_intencoes
        (edital_id, policial_id, escolha_1_vaga_id, escolha_2_vaga_id, escolha_3_vaga_id)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
        escolha_1_vaga_id = VALUES(escolha_1_vaga_id),
        escolha_2_vaga_id = VALUES(escolha_2_vaga_id),
        escolha_3_vaga_id = VALUES(escolha_3_vaga_id)`,
      [editalId, policialId, escolha1 || null, escolha2 || null, escolha3 || null]
    );
  }

  async analisarVaga(editalId, vagaId, minhaPosicao) {
    const [vagaInfo] = await db.execute(
      'SELECT opm, vagas_disponiveis FROM edital_vagas WHERE id = ? AND edital_id = ?',
      [vagaId, editalId]
    );
    if (vagaInfo.length === 0) return null;

    const countFor = async (col) => {
      const [rows] = await db.execute(
        `SELECT COUNT(DISTINCT ep.id) AS total
         FROM edital_participantes ep
         INNER JOIN edital_intencoes ei
           ON ei.edital_id = ep.edital_id AND ei.policial_id = ep.policial_id
         WHERE ep.edital_id = ?
           AND ep.posicao_prioridade < ?
           AND ep.policial_id IS NOT NULL
           AND ei.${col} = ?`,
        [editalId, minhaPosicao, vagaId]
      );
      return rows[0]?.total || 0;
    };

    const [c1, c2, c3] = await Promise.all([
      countFor('escolha_1_vaga_id'),
      countFor('escolha_2_vaga_id'),
      countFor('escolha_3_vaga_id'),
    ]);

    return {
      vagaInfo: vagaInfo[0],
      minhaPosicao,
      competicao: {
        como_1_opcao: c1,
        como_2_opcao: c2,
        como_3_opcao: c3,
      },
    };
  }

  // --- Admin ---

  async listAllAdmin() {
    const [rows] = await db.execute(
      `SELECT e.*, f.sigla AS forca_sigla,
        (SELECT COUNT(*) FROM edital_vagas v WHERE v.edital_id = e.id) AS total_vagas,
        (SELECT COUNT(*) FROM edital_participantes p WHERE p.edital_id = e.id) AS total_participantes
       FROM editais e
       JOIN forcas_policiais f ON f.id = e.forca_id
       ORDER BY e.criado_em DESC`
    );
    return rows;
  }

  async createEdital(data) {
    const [result] = await db.execute(
      `INSERT INTO editais (
        tipo, forca_id, titulo, resumo, link_pdf, data_abertura, data_encerramento,
        status, criterio_prioridade, criterio_label, max_opcoes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.tipo,
        data.forca_id,
        data.titulo,
        data.resumo || null,
        data.link_pdf || null,
        data.data_abertura || null,
        data.data_encerramento || null,
        data.status || 'RASCUNHO',
        data.criterio_prioridade || 'CLASSIFICACAO_CURSO',
        data.criterio_label || 'Classificação',
        data.max_opcoes || 3,
      ]
    );
    return result.insertId;
  }

  async updateEdital(id, data) {
    const fields = [];
    const values = [];
    const allowed = [
      'tipo', 'forca_id', 'titulo', 'resumo', 'link_pdf', 'data_abertura',
      'data_encerramento', 'status', 'criterio_prioridade', 'criterio_label', 'max_opcoes',
    ];
    for (const key of allowed) {
      if (data[key] !== undefined) {
        fields.push(`${key} = ?`);
        values.push(data[key]);
      }
    }
    if (fields.length === 0) return false;
    values.push(id);
    const [result] = await db.execute(
      `UPDATE editais SET ${fields.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows > 0;
  }

  async deleteEdital(id) {
    const [result] = await db.execute('DELETE FROM editais WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  async replaceVagas(editalId, vagas, modo = 'substituir') {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      if (modo === 'substituir') {
        await connection.execute('DELETE FROM edital_vagas WHERE edital_id = ?', [editalId]);
      }
      for (let i = 0; i < vagas.length; i++) {
        const v = vagas[i];
        await connection.execute(
          `INSERT INTO edital_vagas (edital_id, crpm, opm, unidade_nome, vagas_disponiveis, ordem)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [
            editalId,
            v.crpm || null,
            v.opm,
            v.unidade_nome || null,
            v.vagas_disponiveis ?? 0,
            v.ordem ?? i + 1,
          ]
        );
      }
      await connection.commit();
      return vagas.length;
    } catch (e) {
      await connection.rollback();
      throw e;
    } finally {
      connection.release();
    }
  }

  async upsertParticipantes(editalId, participantes, modo = 'substituir') {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      if (modo === 'substituir') {
        await connection.execute('DELETE FROM edital_participantes WHERE edital_id = ?', [editalId]);
      }
      for (const p of participantes) {
        const [polRows] = await connection.execute(
          'SELECT id FROM policiais WHERE CAST(id_funcional AS CHAR) = ? LIMIT 1',
          [String(p.id_funcional)]
        );
        const policialId = polRows[0]?.id || null;
        await connection.execute(
          `INSERT INTO edital_participantes (edital_id, id_funcional, posicao_prioridade, policial_id)
           VALUES (?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE posicao_prioridade = VALUES(posicao_prioridade),
             policial_id = COALESCE(VALUES(policial_id), policial_id)`,
          [editalId, String(p.id_funcional), p.posicao_prioridade, policialId]
        );
      }
      await connection.commit();
      return participantes.length;
    } catch (e) {
      await connection.rollback();
      throw e;
    } finally {
      connection.release();
    }
  }
}

module.exports = new EditaisRepository();

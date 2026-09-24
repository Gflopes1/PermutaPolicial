const db = require('../../config/db');

class VerificacaoOcrRepository {
  async findPolicialForVerification(policialId) {
    const [rows] = await db.execute(
      `SELECT p.id, p.nome, p.id_funcional, p.agente_verificado, p.status_verificacao,
              f.sigla as forca_sigla
       FROM policiais p
       LEFT JOIN forcas_policiais f ON p.forca_id = f.id
       WHERE p.id = ?`,
      [policialId]
    );
    return rows[0] || null;
  }

  async findPendingByUsuario(usuarioId) {
    const [rows] = await db.execute(
      `SELECT id, status FROM verificacoes_ocr_pendentes
       WHERE usuario_id = ? AND status = 'pendente_revisao_ocr'
       ORDER BY criado_em DESC LIMIT 1`,
      [usuarioId]
    );
    return rows[0] || null;
  }

  async createPendingReview({
    usuarioId,
    tipoDocumento,
    imagemRedigidaUrl,
    nomeExtraido,
    matriculaExtraida,
    forcaExtraida,
    cargoExtraido,
  }) {
    const [result] = await db.execute(
      `INSERT INTO verificacoes_ocr_pendentes
        (usuario_id, tipo_documento, imagem_redigida_url, nome_extraido,
         matricula_extraida, forca_extraida, cargo_extraido, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pendente_revisao_ocr')`,
      [
        usuarioId,
        tipoDocumento,
        imagemRedigidaUrl,
        nomeExtraido || null,
        matriculaExtraida || null,
        forcaExtraida || null,
        cargoExtraido || null,
      ]
    );
    return result.insertId;
  }

  async setDocumentoVerificacaoUrl(policialId, url) {
    try {
      await db.execute(
        'UPDATE policiais SET documento_verificacao_url = ? WHERE id = ?',
        [url, policialId]
      );
    } catch (error) {
      if (error.code !== 'ER_BAD_FIELD_ERROR') throw error;
    }
  }

  async clearDocumentoVerificacaoUrl(policialId) {
    try {
      await db.execute(
        'UPDATE policiais SET documento_verificacao_url = NULL WHERE id = ?',
        [policialId]
      );
    } catch (error) {
      if (error.code !== 'ER_BAD_FIELD_ERROR') throw error;
    }
  }

  async getDocumentoVerificacaoUrl(policialId) {
    try {
      const [rows] = await db.execute(
        'SELECT documento_verificacao_url FROM policiais WHERE id = ?',
        [policialId]
      );
      return rows[0]?.documento_verificacao_url || null;
    } catch (error) {
      if (error.code === 'ER_BAD_FIELD_ERROR') return null;
      throw error;
    }
  }

  async markAgentVerifiedAutomatico(policialId) {
    try {
      const [result] = await db.execute(
        `UPDATE policiais
         SET agente_verificado = 1,
             metodo_verificacao = 'ocr_automatico',
             verificado_em = NOW()
         WHERE id = ? AND agente_verificado = 0 AND status_verificacao = 'VERIFICADO'`,
        [policialId]
      );
      return result.affectedRows > 0;
    } catch (error) {
      if (error.code !== 'ER_BAD_FIELD_ERROR') throw error;
      const [result] = await db.execute(
        `UPDATE policiais
         SET agente_verificado = 1
         WHERE id = ? AND agente_verificado = 0 AND status_verificacao = 'VERIFICADO'`,
        [policialId]
      );
      return result.affectedRows > 0;
    }
  }

  async isAgentVerified(policialId) {
    const [rows] = await db.execute(
      'SELECT COALESCE(agente_verificado, 0) AS agente_verificado FROM policiais WHERE id = ?',
      [policialId]
    );
    return rows[0]?.agente_verificado === 1;
  }

  async replacePendingReview(pendingId, data) {
    await db.execute(
      `UPDATE verificacoes_ocr_pendentes
       SET tipo_documento = ?, imagem_redigida_url = ?, nome_extraido = ?,
           matricula_extraida = ?, forca_extraida = ?, cargo_extraido = ?,
           status = 'pendente_revisao_ocr', criado_em = NOW(),
           revisado_em = NULL, revisado_por = NULL
       WHERE id = ? AND usuario_id = ? AND status = 'pendente_revisao_ocr'`,
      [
        data.tipoDocumento,
        data.imagemRedigidaUrl,
        data.nomeExtraido || null,
        data.matriculaExtraida || null,
        data.forcaExtraida || null,
        data.cargoExtraido || null,
        pendingId,
        data.usuarioId,
      ]
    );
    return pendingId;
  }

  async findPendingReviews() {
    const [rows] = await db.execute(
      `SELECT v.id, v.usuario_id, v.tipo_documento, v.imagem_redigida_url,
              v.nome_extraido, v.matricula_extraida, v.forca_extraida, v.cargo_extraido,
              v.status, v.criado_em,
              p.nome, p.email, p.id_funcional,
              f.sigla as forca_sigla
       FROM verificacoes_ocr_pendentes v
       JOIN policiais p ON p.id = v.usuario_id
       LEFT JOIN forcas_policiais f ON p.forca_id = f.id
       WHERE v.status = 'pendente_revisao_ocr'
       ORDER BY v.criado_em ASC`
    );
    return rows;
  }

  async findPendingById(id) {
    const [rows] = await db.execute(
      `SELECT v.*, p.nome, p.email, p.id_funcional, p.agente_verificado,
              f.sigla as forca_sigla
       FROM verificacoes_ocr_pendentes v
       JOIN policiais p ON p.id = v.usuario_id
       LEFT JOIN forcas_policiais f ON p.forca_id = f.id
       WHERE v.id = ? AND v.status = 'pendente_revisao_ocr'`,
      [id]
    );
    return rows[0] || null;
  }

  async approvePending(id, revisorId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [rows] = await connection.execute(
        `SELECT id, usuario_id FROM verificacoes_ocr_pendentes
         WHERE id = ? AND status = 'pendente_revisao_ocr' FOR UPDATE`,
        [id]
      );
      if (rows.length === 0) {
        await connection.rollback();
        return false;
      }

      const { usuario_id: usuarioId } = rows[0];

      await connection.execute(
        `UPDATE verificacoes_ocr_pendentes
         SET status = 'aprovado', revisado_em = NOW(), revisado_por = ?
         WHERE id = ?`,
        [revisorId, id]
      );

      await connection.execute(
        `UPDATE policiais
         SET agente_verificado = 1,
             metodo_verificacao = 'ocr_revisao_manual',
             verificado_em = NOW()
         WHERE id = ? AND status_verificacao = 'VERIFICADO'`,
        [usuarioId]
      );

      await connection.commit();
      return { usuarioId };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async rejectPending(id, revisorId) {
    const [rows] = await db.execute(
      `SELECT usuario_id FROM verificacoes_ocr_pendentes
       WHERE id = ? AND status = 'pendente_revisao_ocr'`,
      [id]
    );
    if (rows.length === 0) return false;

    const [result] = await db.execute(
      `UPDATE verificacoes_ocr_pendentes
       SET status = 'rejeitado', revisado_em = NOW(), revisado_por = ?
       WHERE id = ? AND status = 'pendente_revisao_ocr'`,
      [revisorId, id]
    );
    if (result.affectedRows > 0) {
      await this.clearDocumentoVerificacaoUrl(rows[0].usuario_id);
    }
    return result.affectedRows > 0;
  }

  async countPendingReviews() {
    const [rows] = await db.execute(
      "SELECT COUNT(*) as count FROM verificacoes_ocr_pendentes WHERE status = 'pendente_revisao_ocr'"
    );
    return rows[0]?.count || 0;
  }
}

module.exports = new VerificacaoOcrRepository();

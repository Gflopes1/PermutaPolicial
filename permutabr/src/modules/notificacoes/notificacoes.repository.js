// /src/modules/notificacoes/notificacoes.repository.js

const db = require('../../config/db');

class NotificacoesRepository {
  async findAllByUsuario(usuarioId) {
    const query = `
      SELECT 
        n.*,
        -- Dados do solicitante (quando tipo é SOLICITACAO_CONTATO)
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN p_solicitante.nome END as solicitante_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN p_solicitante.qso END as solicitante_contato,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN f_solicitante.nome END as solicitante_forca_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN f_solicitante.sigla END as solicitante_forca_sigla,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN es_solicitante.sigla END as solicitante_estado_sigla,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN m_solicitante.nome END as solicitante_cidade_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO' THEN pg_solicitante.nome END as solicitante_posto_nome,
        -- Dados do aceitador (quando tipo é SOLICITACAO_CONTATO_ACEITA)
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN p_aceitador.nome END as aceitador_nome,
        -- Só retorna telefone se o usuário não estiver oculto no mapa
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' AND p_aceitador.ocultar_no_mapa = 0 THEN p_aceitador.qso END as aceitador_contato,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN p_aceitador.ocultar_no_mapa END as aceitador_ocultar_no_mapa,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN f_aceitador.nome END as aceitador_forca_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN f_aceitador.sigla END as aceitador_forca_sigla,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN es_aceitador.sigla END as aceitador_estado_sigla,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN m_aceitador.nome END as aceitador_cidade_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN u_aceitador.nome END as aceitador_unidade_nome,
        CASE WHEN n.tipo = 'SOLICITACAO_CONTATO_ACEITA' THEN pg_aceitador.nome END as aceitador_posto_nome
      FROM notificacoes n
      -- JOINs para dados do solicitante
      LEFT JOIN policiais p_solicitante ON n.referencia_id = p_solicitante.id AND n.tipo = 'SOLICITACAO_CONTATO'
      LEFT JOIN forcas_policiais f_solicitante ON p_solicitante.forca_id = f_solicitante.id
      LEFT JOIN unidades u_solicitante ON p_solicitante.unidade_atual_id = u_solicitante.id
      LEFT JOIN municipios m_solicitante ON u_solicitante.municipio_id = m_solicitante.id
      LEFT JOIN estados es_solicitante ON m_solicitante.estado_id = es_solicitante.id
      LEFT JOIN postos_graduacoes pg_solicitante ON p_solicitante.posto_graduacao_id = pg_solicitante.id
      -- JOINs para dados do aceitador
      LEFT JOIN policiais p_aceitador ON n.referencia_id = p_aceitador.id AND n.tipo = 'SOLICITACAO_CONTATO_ACEITA'
      LEFT JOIN forcas_policiais f_aceitador ON p_aceitador.forca_id = f_aceitador.id
      LEFT JOIN unidades u_aceitador ON p_aceitador.unidade_atual_id = u_aceitador.id
      LEFT JOIN municipios m_aceitador ON u_aceitador.municipio_id = m_aceitador.id
      LEFT JOIN estados es_aceitador ON m_aceitador.estado_id = es_aceitador.id
      LEFT JOIN postos_graduacoes pg_aceitador ON p_aceitador.posto_graduacao_id = pg_aceitador.id
      WHERE n.usuario_id = ?
      ORDER BY n.criado_em DESC
    `;
    const [rows] = await db.execute(query, [usuarioId]);
    return rows;
  }

  async findById(id) {
    const query = 'SELECT * FROM notificacoes WHERE id = ?';
    const [rows] = await db.execute(query, [id]);
    return rows[0] || null;
  }

  async create(notificacao) {
    const { usuario_id, tipo, referencia_id, titulo, mensagem } = notificacao;
    const query = `
      INSERT INTO notificacoes (usuario_id, tipo, referencia_id, titulo, mensagem)
      VALUES (?, ?, ?, ?, ?)
    `;
    const [result] = await db.execute(query, [usuario_id, tipo, referencia_id, titulo, mensagem]);
    return result.insertId;
  }

  async marcarComoLida(id, usuarioId) {
    const query = 'UPDATE notificacoes SET lida = 1 WHERE id = ? AND usuario_id = ?';
    const [result] = await db.execute(query, [id, usuarioId]);
    return result.affectedRows > 0;
  }

  async marcarTodasComoLidas(usuarioId) {
    const query = 'UPDATE notificacoes SET lida = 1 WHERE usuario_id = ? AND lida = 0';
    const [result] = await db.execute(query, [usuarioId]);
    return result.affectedRows;
  }

  async countNaoLidas(usuarioId) {
    const query = 'SELECT COUNT(*) as count FROM notificacoes WHERE usuario_id = ? AND lida = 0';
    const [rows] = await db.execute(query, [usuarioId]);
    return rows[0].count;
  }

  async delete(id, usuarioId) {
    const query = 'DELETE FROM notificacoes WHERE id = ? AND usuario_id = ?';
    const [result] = await db.execute(query, [id, usuarioId]);
    return result.affectedRows > 0;
  }
}

module.exports = new NotificacoesRepository();


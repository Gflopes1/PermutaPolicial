// /src/modules/analytics/analytics.repository.js

const db = require('../../config/db');

class AnalyticsRepository {
  // Cria um evento de usuário
  async createUserEvent(eventData) {
    const { usuario_id, evento_tipo, metadata, ip_address, user_agent } = eventData;
    const query = `
      INSERT INTO user_events (usuario_id, evento_tipo, metadata, ip_address, user_agent)
      VALUES (?, ?, ?, ?, ?)
    `;
    const metadataJson = metadata ? JSON.stringify(metadata) : null;
    await db.execute(query, [usuario_id, evento_tipo, metadataJson, ip_address, user_agent]);
  }

  // Cria uma visualização de página
  async createPageView(pageViewData) {
    const { usuario_id, pagina, sessao_id, ip_address, user_agent } = pageViewData;
    const query = `
      INSERT INTO page_views (usuario_id, pagina, sessao_id, ip_address, user_agent)
      VALUES (?, ?, ?, ?, ?)
    `;
    const [result] = await db.execute(query, [usuario_id, pagina, sessao_id, ip_address, user_agent]);
    return result.insertId;
  }

  // Atualiza o tempo de permanência em uma página
  async updatePageViewDuration(pageViewId, tempoSegundos) {
    const query = `
      UPDATE page_views
      SET tempo_permanencia = ?
      WHERE id = ?
    `;
    await db.execute(query, [tempoSegundos, pageViewId]);
  }

  // Cria ou atualiza uma sessão de usuário
  async createOrUpdateSession(sessionData) {
    const { sessao_id, usuario_id, ip_address, user_agent, dispositivo_tipo, navegador, sistema_operacional } = sessionData;
    
    // Verifica se a sessão já existe
    const [existing] = await db.execute(
      'SELECT id FROM user_sessions WHERE sessao_id = ?',
      [sessao_id]
    );

    if (existing.length > 0) {
      // Atualiza sessão existente
      const query = `
        UPDATE user_sessions
        SET total_page_views = total_page_views + 1
        WHERE sessao_id = ?
      `;
      await db.execute(query, [sessao_id]);
      return existing[0].id;
    } else {
      // Cria nova sessão
      const query = `
        INSERT INTO user_sessions (
          sessao_id, usuario_id, ip_address, user_agent,
          dispositivo_tipo, navegador, sistema_operacional, total_page_views
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
      `;
      const [result] = await db.execute(
        query,
        [sessao_id, usuario_id, ip_address, user_agent, dispositivo_tipo, navegador, sistema_operacional]
      );
      return result.insertId;
    }
  }

  // Finaliza uma sessão
  async endSession(sessaoId, duracaoSegundos) {
    const query = `
      UPDATE user_sessions
      SET fim_sessao = CURRENT_TIMESTAMP, duracao_segundos = ?
      WHERE sessao_id = ?
    `;
    await db.execute(query, [duracaoSegundos, sessaoId]);
  }

  // Obtém estatísticas gerais
  async getEstatisticasGerais(dataInicio, dataFim) {
    // Query para eventos
    let whereEvents = '';
    const paramsEvents = [];
    if (dataInicio && dataFim) {
      whereEvents = 'WHERE criado_em BETWEEN ? AND ?';
      paramsEvents.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereEvents = 'WHERE criado_em >= ?';
      paramsEvents.push(dataInicio);
    } else if (dataFim) {
      whereEvents = 'WHERE criado_em <= ?';
      paramsEvents.push(dataFim);
    }
    const [eventRows] = await db.execute(`SELECT COUNT(*) as total FROM user_events ${whereEvents}`, paramsEvents);

    // Query para page views
    let wherePageViews = '';
    const paramsPageViews = [];
    if (dataInicio && dataFim) {
      wherePageViews = 'WHERE criado_em BETWEEN ? AND ?';
      paramsPageViews.push(dataInicio, dataFim);
    } else if (dataInicio) {
      wherePageViews = 'WHERE criado_em >= ?';
      paramsPageViews.push(dataInicio);
    } else if (dataFim) {
      wherePageViews = 'WHERE criado_em <= ?';
      paramsPageViews.push(dataFim);
    }
    const [pageViewRows] = await db.execute(`SELECT COUNT(*) as total FROM page_views ${wherePageViews}`, paramsPageViews);
    
    // Query para usuários únicos
    const whereUniqueUsers = wherePageViews ? `${wherePageViews} AND usuario_id IS NOT NULL` : 'WHERE usuario_id IS NOT NULL';
    const [uniqueUsersRows] = await db.execute(`SELECT COUNT(DISTINCT usuario_id) as total FROM page_views ${whereUniqueUsers}`, paramsPageViews);

    // Query para sessões
    let whereSessions = '';
    const paramsSessions = [];
    if (dataInicio && dataFim) {
      whereSessions = 'WHERE inicio_sessao BETWEEN ? AND ?';
      paramsSessions.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereSessions = 'WHERE inicio_sessao >= ?';
      paramsSessions.push(dataInicio);
    } else if (dataFim) {
      whereSessions = 'WHERE inicio_sessao <= ?';
      paramsSessions.push(dataFim);
    }
    const [sessionRows] = await db.execute(`SELECT COUNT(*) as total FROM user_sessions ${whereSessions}`, paramsSessions);

    return {
      total_eventos: eventRows[0]?.total || 0,
      total_page_views: pageViewRows[0]?.total || 0,
      usuarios_unicos: uniqueUsersRows[0]?.total || 0,
      total_sessoes: sessionRows[0]?.total || 0,
    };
  }

  // Obtém estatísticas de page views
  async getPageViewsStats(dataInicio, dataFim) {
    let whereClause = '';
    const params = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE criado_em <= ?';
      params.push(dataFim);
    }

    const [rows] = await db.execute(`
      SELECT 
        pagina,
        COUNT(*) as total_views,
        COUNT(DISTINCT usuario_id) as usuarios_unicos,
        AVG(tempo_permanencia) as tempo_medio_segundos
      FROM page_views
      ${whereClause}
      GROUP BY pagina
      ORDER BY total_views DESC
    `, params);

    return rows;
  }

  // Obtém eventos por tipo
  async getEventosPorTipo(dataInicio, dataFim) {
    let whereClause = '';
    const params = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE criado_em <= ?';
      params.push(dataFim);
    }

    const [rows] = await db.execute(`
      SELECT 
        evento_tipo,
        COUNT(*) as total,
        COUNT(DISTINCT usuario_id) as usuarios_unicos
      FROM user_events
      ${whereClause}
      GROUP BY evento_tipo
      ORDER BY total DESC
    `, params);

    return rows;
  }

  // Obtém estatísticas de sessões
  async getSessoesStats(dataInicio, dataFim) {
    let whereClause = '';
    const params = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE inicio_sessao BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = 'WHERE inicio_sessao >= ?';
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE inicio_sessao <= ?';
      params.push(dataFim);
    }

    const [rows] = await db.execute(`
      SELECT 
        COUNT(*) as total_sessoes,
        COUNT(DISTINCT usuario_id) as usuarios_unicos,
        AVG(duracao_segundos) as duracao_media_segundos,
        AVG(total_page_views) as page_views_medio,
        COUNT(CASE WHEN dispositivo_tipo = 'mobile' THEN 1 END) as sessoes_mobile,
        COUNT(CASE WHEN dispositivo_tipo = 'desktop' THEN 1 END) as sessoes_desktop
      FROM user_sessions
      ${whereClause}
    `, params);

    return rows[0] || {};
  }

  // Obtém atividade por hora do dia
  async getAtividadePorHora(dataInicio, dataFim) {
    let whereClause = '';
    const params = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE criado_em <= ?';
      params.push(dataFim);
    }

    const [rows] = await db.execute(`
      SELECT 
        HOUR(criado_em) as hora,
        COUNT(*) as total_eventos
      FROM user_events
      ${whereClause}
      GROUP BY HOUR(criado_em)
      ORDER BY hora
    `, params);

    return rows;
  }

  // ✅ Obtém crescimento de usuários agrupado por data
  async getCrescimentoUsuarios(dataInicio, dataFim) {
    let whereClause = '';
    const params = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE criado_em <= ?';
      params.push(dataFim);
    }

    const [rows] = await db.execute(`
      SELECT 
        DATE(criado_em) as data,
        COUNT(*) as total
      FROM policiais
      ${whereClause}
      GROUP BY DATE(criado_em)
      ORDER BY data ASC
    `, params);

    return rows;
  }
}

module.exports = new AnalyticsRepository();


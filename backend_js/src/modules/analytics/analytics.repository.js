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
    
    // Query para usuários únicos (conta sessões distintas, não apenas usuários logados)
    // Prioriza usuario_id quando disponível, senão conta sessao_id único
    let whereUnique = '';
    const paramsUnique = [];
    if (dataInicio && dataFim) {
      whereUnique = 'WHERE criado_em BETWEEN ? AND ?';
      paramsUnique.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereUnique = 'WHERE criado_em >= ?';
      paramsUnique.push(dataInicio);
    } else if (dataFim) {
      whereUnique = 'WHERE criado_em <= ?';
      paramsUnique.push(dataFim);
    }
    const [uniqueUsersRows] = await db.execute(
      // Prefixos evitam colisão entre usuario_id numérico e sessao_id string
      `SELECT COUNT(DISTINCT COALESCE(CONCAT('u:', usuario_id), CONCAT('s:', sessao_id))) as total
       FROM page_views
       ${whereUnique}`,
      paramsUnique
    );

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
    let wherePv = '';
    const paramsPv = [];

    if (dataInicio && dataFim) {
      whereClause = 'WHERE us.inicio_sessao BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
      wherePv = 'AND criado_em >= ?';
      paramsPv.push(dataInicio);
    } else if (dataInicio) {
      whereClause = 'WHERE us.inicio_sessao >= ?';
      params.push(dataInicio);
      wherePv = 'AND criado_em >= ?';
      paramsPv.push(dataInicio);
    } else if (dataFim) {
      whereClause = 'WHERE us.inicio_sessao <= ?';
      params.push(dataFim);
    }

    // duracao_segundos só é preenchido por /sessao/finalizar, que o app quase nunca chama
    // (aba fechada). Fallback: intervalo entre 1ª e última page view da sessão.
    // Limite de 4h por sessão para não distorcer a média com abas esquecidas abertas.
    const [rows] = await db.execute(`
      SELECT
        COUNT(*) as total_sessoes,
        COUNT(DISTINCT us.usuario_id) as usuarios_unicos,
        AVG(CASE
              WHEN COALESCE(NULLIF(us.duracao_segundos, 0), pv.dur) > 0
              THEN LEAST(COALESCE(NULLIF(us.duracao_segundos, 0), pv.dur), 14400)
            END) as duracao_media_segundos,
        AVG(us.total_page_views) as page_views_medio,
        COUNT(CASE WHEN us.dispositivo_tipo = 'mobile' THEN 1 END) as sessoes_mobile,
        COUNT(CASE WHEN us.dispositivo_tipo = 'desktop' THEN 1 END) as sessoes_desktop
      FROM user_sessions us
      LEFT JOIN (
        SELECT sessao_id, TIMESTAMPDIFF(SECOND, MIN(criado_em), MAX(criado_em)) AS dur
        FROM page_views
        WHERE sessao_id IS NOT NULL ${wherePv}
        GROUP BY sessao_id
      ) pv ON pv.sessao_id = us.sessao_id
      ${whereClause}
    `, [...paramsPv, ...params]);

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

  _buildDateFilter(column, dataInicio, dataFim) {
    let whereClause = '';
    const params = [];
    if (dataInicio && dataFim) {
      whereClause = `WHERE ${column} BETWEEN ? AND ?`;
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      whereClause = `WHERE ${column} >= ?`;
      params.push(dataInicio);
    } else if (dataFim) {
      whereClause = `WHERE ${column} <= ?`;
      params.push(dataFim);
    }
    return { whereClause, params };
  }

  _granularidadeSql(granularidade, alias = 'p', column = 'criado_em') {
    const col = `${alias}.${column}`;
    const map = {
      dia: { select: `DATE(${col})`, group: `DATE(${col})`, label: `DATE(${col})` },
      semana: { select: `DATE_FORMAT(${col}, '%x-%v')`, group: `DATE_FORMAT(${col}, '%x-%v')`, label: `DATE_FORMAT(MIN(${col}), '%d/%m/%Y')` },
      mes: { select: `DATE_FORMAT(${col}, '%Y-%m')`, group: `DATE_FORMAT(${col}, '%Y-%m')`, label: `DATE_FORMAT(MIN(${col}), '%m/%Y')` },
      ano: { select: `YEAR(${col})`, group: `YEAR(${col})`, label: `YEAR(MIN(${col}))` },
    };
    return map[granularidade] || map.dia;
  }

  _applyCumulativo(rows) {
    let acumulado = 0;
    return rows.map((row) => {
      acumulado += Number(row.total) || 0;
      return { ...row, total: acumulado, novos: Number(row.total) || 0 };
    });
  }

  async getCrescimentoUsuarios(dataInicio, dataFim, { granularidade = 'dia', cumulativo = false, estadoId = null, forcaId = null } = {}) {
    const g = this._granularidadeSql(granularidade);
    const { whereClause, params } = this._buildDateFilter('p.criado_em', dataInicio, dataFim);

    let extraWhere = '';
    const extraParams = [];
    if (estadoId) {
      extraWhere += ` AND COALESCE(m.estado_id, mu.estado_id) = ?`;
      extraParams.push(estadoId);
    }
    if (forcaId) {
      extraWhere += ' AND p.forca_id = ?';
      extraParams.push(forcaId);
    }

    const where = whereClause
      ? `${whereClause}${extraWhere}`
      : (extraWhere ? `WHERE 1=1${extraWhere}` : '');

    const [rows] = await db.execute(`
      SELECT
        ${g.select} as periodo,
        ${g.label} as data,
        COUNT(*) as total
      FROM policiais p
      LEFT JOIN municipios m ON p.municipio_atual_id = m.id
      LEFT JOIN unidades u ON p.unidade_atual_id = u.id
      LEFT JOIN municipios mu ON u.municipio_id = mu.id
      ${where}
      GROUP BY ${g.group}
      ORDER BY periodo ASC
    `, [...params, ...extraParams]);

    return cumulativo ? this._applyCumulativo(rows) : rows.map((r) => ({ ...r, novos: Number(r.total) || 0 }));
  }

  async getUsuariosPorEstado() {
    const [rows] = await db.execute(`
      SELECT
        e.id as estado_id,
        e.sigla,
        e.nome,
        COUNT(DISTINCT p.id) as total,
        COUNT(DISTINCT CASE WHEN p.status_verificacao = 'VERIFICADO' THEN p.id END) as verificados,
        COUNT(DISTINCT CASE WHEN p.status_verificacao = 'PENDENTE' THEN p.id END) as pendentes,
        COUNT(DISTINCT CASE WHEN i.policial_id IS NOT NULL THEN p.id END) as com_intencoes,
        COUNT(DISTINCT CASE WHEN p.destaque_ate IS NOT NULL AND p.destaque_ate > NOW() THEN p.id END) as em_destaque
      FROM policiais p
      LEFT JOIN municipios m ON p.municipio_atual_id = m.id
      LEFT JOIN unidades u ON p.unidade_atual_id = u.id
      LEFT JOIN municipios mu ON u.municipio_id = mu.id
      LEFT JOIN estados e ON e.id = COALESCE(m.estado_id, mu.estado_id)
      LEFT JOIN intencoes i ON i.policial_id = p.id
      WHERE e.id IS NOT NULL
      GROUP BY e.id, e.sigla, e.nome
      ORDER BY total DESC
    `);
    return rows;
  }

  async getUsuariosPorForcaDetalhado() {
    const [rows] = await db.execute(`
      SELECT
        f.id as forca_id,
        f.sigla,
        f.nome,
        COUNT(DISTINCT p.id) as total,
        SUM(CASE WHEN p.status_verificacao = 'VERIFICADO' THEN 1 ELSE 0 END) as verificados,
        SUM(CASE WHEN p.status_verificacao = 'PENDENTE' THEN 1 ELSE 0 END) as pendentes,
        COUNT(DISTINCT i.policial_id) as com_intencoes,
        SUM(CASE WHEN p.destaque_ate IS NOT NULL AND p.destaque_ate > NOW() THEN 1 ELSE 0 END) as em_destaque
      FROM forcas_policiais f
      LEFT JOIN policiais p ON p.forca_id = f.id
      LEFT JOIN intencoes i ON i.policial_id = p.id
      GROUP BY f.id, f.sigla, f.nome
      ORDER BY total DESC
    `);
    return rows;
  }

  async getContasAtivas(dataInicio, dataFim, { granularidade = 'dia' } = {}) {
    const g = this._granularidadeSql(granularidade, 'pv', 'criado_em');
    const { whereClause, params } = this._buildDateFilter('pv.criado_em', dataInicio, dataFim);
    const where = whereClause
      ? `${whereClause} AND pv.usuario_id IS NOT NULL`
      : 'WHERE pv.usuario_id IS NOT NULL';

    const [rows] = await db.execute(`
      SELECT
        ${g.select} as periodo,
        ${g.label} as data,
        COUNT(DISTINCT pv.usuario_id) as usuarios_ativos,
        COUNT(*) as page_views
      FROM page_views pv
      ${where}
      GROUP BY ${g.group}
      ORDER BY periodo ASC
    `, params);

    return rows;
  }

  async getMediaKitExport(dataInicio, dataFim) {
    const [
      estatisticas,
      funil,
      usuariosPorEstado,
      usuariosPorForca,
      crescimentoDia,
      crescimentoMes,
      crescimentoCumulativo,
      contasAtivas,
      engajamento,
      demandaForcas,
    ] = await Promise.all([
      this.getEstatisticasGerais(dataInicio, dataFim),
      this.getFunilPermuta(),
      this.getUsuariosPorEstado(),
      this.getUsuariosPorForcaDetalhado(),
      this.getCrescimentoUsuarios(dataInicio, dataFim, { granularidade: 'dia', cumulativo: false }),
      this.getCrescimentoUsuarios(dataInicio, dataFim, { granularidade: 'mes', cumulativo: false }),
      this.getCrescimentoUsuarios(dataInicio, dataFim, { granularidade: 'mes', cumulativo: true }),
      this.getContasAtivas(dataInicio, dataFim, { granularidade: 'mes' }),
      this.getEngajamentoPermuta(dataInicio, dataFim),
      this.getDemandaPorForca(),
    ]);

    return {
      gerado_em: new Date().toISOString(),
      periodo: { data_inicio: dataInicio || null, data_fim: dataFim || null },
      resumo: estatisticas,
      funil_permuta: funil,
      usuarios_por_estado: usuariosPorEstado,
      usuarios_por_forca: usuariosPorForca,
      crescimento: {
        dia: crescimentoDia,
        mes: crescimentoMes,
        cumulativo_mes: crescimentoCumulativo,
      },
      contas_ativas: contasAtivas,
      engajamento,
      demanda_forcas: demandaForcas,
    };
  }

  async getResumoAdmin(dataInicio, dataFim, options = {}) {
    const { granularidade = 'dia', cumulativo = false } = options;

    const [
      estatisticas,
      sessoes,
      crescimento,
      contasAtivas,
      usuariosPorEstado,
      usuariosPorForca,
      funil,
      engajamento,
    ] = await Promise.all([
      this.getEstatisticasGerais(dataInicio, dataFim),
      this.getSessoesStats(dataInicio, dataFim),
      this.getCrescimentoUsuarios(dataInicio, dataFim, { granularidade, cumulativo }),
      this.getContasAtivas(dataInicio, dataFim, { granularidade }),
      this.getUsuariosPorEstado(),
      this.getUsuariosPorForcaDetalhado(),
      this.getFunilPermuta(),
      this.getEngajamentoPermuta(dataInicio, dataFim),
    ]);

    return {
      estatisticas,
      sessoes,
      crescimento,
      contas_ativas: contasAtivas,
      usuarios_por_estado: usuariosPorEstado,
      usuarios_por_forca: usuariosPorForca,
      funil,
      engajamento,
    };
  }

  async getFunilPermuta() {
    const [[totais]] = await db.execute(`
      SELECT
        (SELECT COUNT(*) FROM policiais) as total_contas,
        (SELECT COUNT(*) FROM policiais WHERE status_verificacao = 'VERIFICADO') as verificados,
        (SELECT COUNT(DISTINCT policial_id) FROM intencoes) as com_intencoes,
        (SELECT COUNT(DISTINCT p.id) FROM policiais p
          WHERE p.status_verificacao = 'VERIFICADO'
          AND (p.unidade_atual_id IS NOT NULL OR p.municipio_atual_id IS NOT NULL
               OR EXISTS (SELECT 1 FROM intencoes i WHERE i.policial_id = p.id
                          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)))
        ) as com_lotacao,
        (SELECT COUNT(*) FROM policiais WHERE destaque_ate IS NOT NULL AND destaque_ate > NOW()) as em_destaque,
        (SELECT COUNT(*) FROM policiais WHERE COALESCE(alertas_match_ativo, 1) = 1) as alertas_ativos,
        (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active') as premium_ativos
    `);

    let solicitacoesContato = 0;
    let contatosAceitos = 0;
    let alertasMatch = 0;
    try {
      const [[notifs]] = await db.execute(`
        SELECT
          SUM(tipo = 'SOLICITACAO_CONTATO') as solicitacoes,
          SUM(tipo = 'SOLICITACAO_CONTATO_ACEITA') as aceitos,
          SUM(tipo = 'NOVO_MATCH') as alertas_match
        FROM notificacoes
      `);
      solicitacoesContato = notifs?.solicitacoes || 0;
      contatosAceitos = notifs?.aceitos || 0;
      alertasMatch = notifs?.alertas_match || 0;
    } catch (err) {
      console.error('Erro ao buscar notificações para analytics:', err.message);
    }

    let permutasConcluidas = 0;
    try {
      const [[pc]] = await db.execute('SELECT COUNT(*) as c FROM permutas_concluidas_feedback');
      permutasConcluidas = pc?.c || 0;
    } catch (err) {
      console.error('Erro ao buscar permutas concluídas para analytics:', err.message);
    }

    return {
      ...totais,
      solicitacoes_contato: solicitacoesContato,
      contatos_aceitos: contatosAceitos,
      alertas_match_notificacoes: alertasMatch,
      permutas_concluidas: permutasConcluidas,
    };
  }

  async getDemandaPorMunicipio({ forca_id, estado_id, limit = 50 } = {}) {
    const params = [];
    let forcaFilterOrigem = '';
    let forcaFilterDestino = '';
    let estadoFilter = '';

    if (forca_id) {
      forcaFilterOrigem = ' AND p.forca_id = ?';
      forcaFilterDestino = ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    if (estado_id) {
      estadoFilter = ' AND m.estado_id = ?';
      params.push(estado_id);
    }

    const destinoParams = [];
    if (forca_id) destinoParams.push(forca_id);
    if (estado_id) destinoParams.push(estado_id);

    const [saindo] = await db.execute(`
      SELECT m.id as municipio_id, m.nome as municipio_nome, e.sigla as estado_sigla,
             COUNT(DISTINCT i.policial_id) as saindo
      FROM municipios m
      JOIN estados e ON m.estado_id = e.id
      JOIN intencoes i ON (i.municipio_atual_id = m.id OR
        EXISTS (SELECT 1 FROM unidades u WHERE u.id = i.unidade_atual_id AND u.municipio_id = m.id))
      JOIN policiais p ON i.policial_id = p.id
      WHERE p.status_verificacao = 'VERIFICADO'
        AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
        ${forcaFilterOrigem}${estadoFilter}
      GROUP BY m.id, m.nome, e.sigla
    `, params);

    const [vindo] = await db.execute(`
      SELECT m.id as municipio_id, m.nome as municipio_nome, e.sigla as estado_sigla,
             COUNT(DISTINCT i.policial_id) as vindo
      FROM municipios m
      JOIN estados e ON m.estado_id = e.id
      JOIN intencoes i ON i.municipio_id = m.id AND i.tipo_intencao = 'MUNICIPIO'
      JOIN policiais p ON i.policial_id = p.id
      WHERE p.status_verificacao = 'VERIFICADO'
        AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
        ${forcaFilterDestino}${estadoFilter}
      GROUP BY m.id, m.nome, e.sigla
    `, destinoParams);

    const mapa = new Map();
    for (const row of saindo) {
      mapa.set(row.municipio_id, {
        municipio_id: row.municipio_id,
        municipio_nome: row.municipio_nome,
        estado_sigla: row.estado_sigla,
        saindo: row.saindo,
        vindo: 0,
      });
    }
    for (const row of vindo) {
      if (mapa.has(row.municipio_id)) {
        mapa.get(row.municipio_id).vindo = row.vindo;
      } else {
        mapa.set(row.municipio_id, {
          municipio_id: row.municipio_id,
          municipio_nome: row.municipio_nome,
          estado_sigla: row.estado_sigla,
          saindo: 0,
          vindo: row.vindo,
        });
      }
    }

    const lista = Array.from(mapa.values()).map((item) => ({
      ...item,
      balanco: item.vindo - item.saindo,
      volume: item.vindo + item.saindo,
    }));

    lista.sort((a, b) => b.volume - a.volume);
    return lista.slice(0, Math.min(limit, 200));
  }

  async getDemandaPorForca() {
    const [rows] = await db.execute(`
      SELECT f.sigla, f.nome,
        COUNT(DISTINCT p.id) as total_policiais,
        COUNT(DISTINCT i.policial_id) as com_intencoes,
        SUM(CASE WHEN p.destaque_ate > NOW() THEN 1 ELSE 0 END) as em_destaque
      FROM forcas_policiais f
      LEFT JOIN policiais p ON p.forca_id = f.id AND p.status_verificacao = 'VERIFICADO'
      LEFT JOIN intencoes i ON i.policial_id = p.id
      GROUP BY f.id, f.sigla, f.nome
      ORDER BY com_intencoes DESC
    `);
    return rows;
  }

  async getEngajamentoPermuta(dataInicio, dataFim) {
    const matchAlertsRepository = require('../match-alerts/match-alerts.repository');
    let where = '';
    const params = [];
    if (dataInicio && dataFim) {
      where = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      where = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    }

    const [[pageViews]] = await db.execute(`
      SELECT
        SUM(pagina IN ('/permutas', '/mapa', '/dashboard', '/dashboard-v3')) as views_permuta,
        SUM(pagina = '/permutas') as views_permutas_tela,
        SUM(pagina = '/mapa') as views_mapa
      FROM page_views ${where}
    `, params);

    const alertasLog = await matchAlertsRepository.countAlertasEnviados(dataInicio, dataFim);
    const alertasPorTipo = await matchAlertsRepository.countAlertasPorTipo(dataInicio, dataFim);

    return {
      page_views_permuta: pageViews?.views_permuta || 0,
      page_views_permutas_tela: pageViews?.views_permutas_tela || 0,
      page_views_mapa: pageViews?.views_mapa || 0,
      alertas_match_enviados: alertasLog,
      alertas_por_tipo: alertasPorTipo,
    };
  }

  async getHistoricoIntencoes({ limit = 20 } = {}) {
    const safeLimit = Math.min(Math.max(limit, 1), 100);

    try {
      const [[resumo]] = await db.execute(`
        SELECT
          COUNT(*) as total_arquivadas,
          SUM(motivo = 'ATUALIZACAO') as atualizacao,
          SUM(motivo = 'EXCLUSAO') as exclusao,
          SUM(motivo = 'PERMUTA_CONCLUIDA') as permuta_concluida,
          SUM(motivo = 'EXPIRACAO') as expiracao,
          SUM(motivo = 'CONTA_REMOVIDA') as conta_removida,
          SUM(raio_km IS NOT NULL) as com_raio_km,
          COUNT(DISTINCT policial_id) as policiais_unicos
        FROM intencoes_historico
      `);

      const [rotas] = await db.execute(`
        SELECT
          mo.nome as origem_nome,
          eo.sigla as origem_estado,
          md.nome as destino_nome,
          ed.sigla as destino_estado,
          COUNT(*) as volume,
          SUM(h.motivo = 'PERMUTA_CONCLUIDA') as concluidas,
          ROUND(AVG(h.raio_km), 0) as raio_medio_km
        FROM intencoes_historico h
        LEFT JOIN municipios mo ON mo.id = h.municipio_origem_id
        LEFT JOIN estados eo ON eo.id = mo.estado_id
        LEFT JOIN municipios md ON md.id = h.municipio_id
        LEFT JOIN estados ed ON ed.id = md.estado_id
        WHERE h.tipo_intencao = 'MUNICIPIO'
          AND h.municipio_id IS NOT NULL
          AND h.municipio_origem_id IS NOT NULL
          AND h.municipio_origem_id != h.municipio_id
        GROUP BY h.municipio_origem_id, h.municipio_id,
                 mo.nome, md.nome, eo.sigla, ed.sigla
        ORDER BY volume DESC
        LIMIT ?
      `, [safeLimit]);

      const [conversao] = await db.execute(`
        SELECT
          md.nome as destino_nome,
          ed.sigla as destino_estado,
          COUNT(*) as total_arquivadas,
          SUM(h.motivo = 'PERMUTA_CONCLUIDA') as concluidas,
          SUM(h.motivo = 'EXPIRACAO') as expiradas,
          SUM(h.motivo = 'ATUALIZACAO') as atualizadas,
          ROUND(100 * SUM(h.motivo = 'PERMUTA_CONCLUIDA') / NULLIF(COUNT(*), 0), 1) as taxa_conversao_pct
        FROM intencoes_historico h
        LEFT JOIN municipios md ON md.id = h.municipio_id
        LEFT JOIN estados ed ON ed.id = md.estado_id
        WHERE h.tipo_intencao = 'MUNICIPIO' AND h.municipio_id IS NOT NULL
        GROUP BY h.municipio_id, md.nome, ed.sigla
        HAVING total_arquivadas >= 2
        ORDER BY total_arquivadas DESC, taxa_conversao_pct DESC
        LIMIT ?
      `, [safeLimit]);

      return {
        resumo: resumo || {},
        rotas_demandadas: rotas,
        conversao_por_destino: conversao,
      };
    } catch (error) {
      if (error.code === 'ER_NO_SUCH_TABLE') {
        return {
          resumo: { total_arquivadas: 0, tabela_ausente: true },
          rotas_demandadas: [],
          conversao_por_destino: [],
        };
      }
      throw error;
    }
  }
}

module.exports = new AnalyticsRepository();


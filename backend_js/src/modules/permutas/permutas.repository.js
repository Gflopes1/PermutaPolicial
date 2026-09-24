// /src/modules/permutas/permutas.repository.js

const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');
const logger = require('../../core/utils/logger');
const {
    sqlLegMatch,
    sqlLegExactOnly,
    haversineKm,
    allowsEstadoIntentionFromForcaCondition,
    sqlMutualIntentionMatch,
    sqlInteressadoLocationMatch,
    sqlInteressadoProfileMatch,
} = require('./permutas.proximity');

class PermutasRepository {

    // MUDANÇA: 'filters' foi removido da assinatura da função.
    async findInteressados({ profile, forcaCondition, forcaParams }) {
        try {
            if (process.env.NODE_ENV === 'development') {
                logger.log('🔍 DEBUG PROFILE no findInteressados:');
                logger.log('   Unidade ID:', profile.unidade_atual_id);
                logger.log('   Município ID:', profile.municipio_id);
                logger.log('   Estado ID:', profile.estado_id);
                logger.log('   Força Condition:', forcaCondition);
                logger.log('   Força Params:', forcaParams);
            }

            // Busca as intenções do perfil para obter o local de cada intenção
            const [intencoesPerfil] = await db.execute(
                'SELECT unidade_atual_id, municipio_atual_id FROM intencoes WHERE policial_id = ? ORDER BY prioridade ASC LIMIT 1',
                [profile.id]
            );
            
            // Se não houver intenções com local, usa o perfil como fallback
            let unidadeAtualId = profile.unidade_atual_id;
            let municipioAtualId = profile.municipio_atual_id;
            let estadoIdPerfil = profile.estado_id;
            
            // Se houver intenções, usa o local da primeira intenção (maior prioridade)
            if (intencoesPerfil.length > 0 && (intencoesPerfil[0].unidade_atual_id || intencoesPerfil[0].municipio_atual_id)) {
                unidadeAtualId = intencoesPerfil[0].unidade_atual_id;
                municipioAtualId = intencoesPerfil[0].municipio_atual_id;
            }
            
            // Se não tem municipio_atual_id, tenta pegar da unidade
            if (!municipioAtualId && unidadeAtualId) {
                const [unidadeRows] = await db.execute('SELECT municipio_id FROM unidades WHERE id = ?', [unidadeAtualId]);
                if (unidadeRows.length > 0) {
                    municipioAtualId = unidadeRows[0].municipio_id;
                }
            }
            
            // Busca o estado_id do município
            if (!estadoIdPerfil && municipioAtualId) {
                const [municipioRows] = await db.execute('SELECT estado_id FROM municipios WHERE id = ?', [municipioAtualId]);
                if (municipioRows.length > 0) {
                    estadoIdPerfil = municipioRows[0].estado_id;
                }
            }

            // ✅ CORREÇÃO SEGURANÇA: Construção segura da query sem usar .replace() na string SQL
            // Valida e constrói a condição de força de forma segura
            let forcaConditionSafe = '';
            
            // A forcaCondition vem do service já validada e é uma das duas opções seguras:
            // 1. 'f2.tipo_permuta = ?' (permuta interestadual)
            // 2. 'p2.forca_id = ?' (permuta estadual)
            // Para a subquery, substituímos os aliases de forma segura
            if (forcaCondition === 'f2.tipo_permuta = ?') {
                forcaConditionSafe = 'f_temp.tipo_permuta = ?';
            } else if (forcaCondition === 'p2.forca_id = ?') {
                forcaConditionSafe = 'p_temp.forca_id = ?';
            } else {
                throw new ApiError(500, 'Condição de força inválida no findInteressados');
            }

            const allowEstadoIntention = allowsEstadoIntentionFromForcaCondition(forcaCondition);
            const locationMatchSql = sqlInteressadoLocationMatch(allowEstadoIntention);
            const profileMatchSql = sqlInteressadoProfileMatch(allowEstadoIntention);
            const locationParams = allowEstadoIntention
                ? [unidadeAtualId, municipioAtualId, estadoIdPerfil]
                : [unidadeAtualId, municipioAtualId];

            // Usa subquery para garantir que cada policial apareça apenas uma vez
            // Seleciona a intenção de maior prioridade (menor número) que corresponde
            let query = `
      SELECT 
          p2.id, 
          -- Só retorna nome se o usuário não estiver oculto no mapa
          CASE WHEN p2.ocultar_no_mapa = 0 THEN p2.nome ELSE 'Usuário não identificado' END as nome,
          -- Só retorna QSO se o usuário não estiver oculto no mapa
          CASE WHEN p2.ocultar_no_mapa = 0 THEN p2.qso ELSE NULL END as qso,
          p2.posto_graduacao_id, p2.ocultar_no_mapa,
          (p2.destaque_ate IS NOT NULL AND p2.destaque_ate > NOW()) as em_destaque,
          pg2.nome as posto_graduacao_nome,
          f2.sigla as forca_sigla, f2.nome as forca_nome,
          u2.nome as unidade_atual,
          COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual, 
          COALESCE(e_direto.sigla, e_unidade.sigla) as estado_atual,
          i.prioridade, i.tipo_intencao,
          CASE 
              WHEN i.tipo_intencao = 'UNIDADE' THEN CONCAT('Quer ir para sua unidade: ', COALESCE(u_consulta.nome, 'unidade não informada'))
              WHEN i.tipo_intencao = 'MUNICIPIO' THEN CONCAT(
                  'Quer ir para seu município: ',
                  COALESCE(m_consulta.nome, 'município não informado'),
                  CASE WHEN e_consulta.sigla IS NOT NULL THEN CONCAT('-', e_consulta.sigla) ELSE '' END
              )
              WHEN i.tipo_intencao = 'ESTADO' THEN CONCAT('Quer ir para seu estado: ', COALESCE(e_consulta.sigla, 'estado não informado'))
          END as descricao_interesse
      FROM (
          SELECT i2.policial_id, MIN(i2.prioridade) as min_prioridade
          FROM intencoes i2
          JOIN policiais p_temp ON i2.policial_id = p_temp.id
          JOIN forcas_policiais f_temp ON p_temp.forca_id = f_temp.id
          WHERE p_temp.id != ? 
          AND ${forcaConditionSafe}
          AND p_temp.status_verificacao = 'VERIFICADO'
          AND (i2.unidade_atual_id IS NOT NULL OR i2.municipio_atual_id IS NOT NULL)
          AND ${locationMatchSql}
          GROUP BY i2.policial_id
      ) as intencoes_match
      JOIN intencoes i ON i.policial_id = intencoes_match.policial_id 
          AND i.prioridade = intencoes_match.min_prioridade
      JOIN policiais p2 ON i.policial_id = p2.id
      JOIN forcas_policiais f2 ON p2.forca_id = f2.id
      LEFT JOIN unidades u2 ON i.unidade_atual_id = u2.id
      LEFT JOIN municipios m_direto ON i.municipio_atual_id = m_direto.id
      LEFT JOIN estados e_direto ON m_direto.estado_id = e_direto.id
      LEFT JOIN municipios m_unidade ON u2.municipio_id = m_unidade.id
      LEFT JOIN estados e_unidade ON m_unidade.estado_id = e_unidade.id
      LEFT JOIN postos_graduacoes pg2 ON p2.posto_graduacao_id = pg2.id
      LEFT JOIN unidades u_consulta ON u_consulta.id = ?
      LEFT JOIN municipios m_consulta ON m_consulta.id = ?
      LEFT JOIN estados e_consulta ON e_consulta.id = COALESCE(?, m_consulta.estado_id)
      WHERE ${profileMatchSql}
    `;

            const params = [
                profile.id,
                ...forcaParams,
                ...locationParams,
                unidadeAtualId,
                municipioAtualId,
                estadoIdPerfil,
                ...locationParams,
            ];

            if (process.env.NODE_ENV === 'development') {
                logger.log('📋 Query params:', params);
            }

            query += ' ORDER BY em_destaque DESC, i.prioridade ASC LIMIT 100';

            const [rows] = await db.execute(query, params);
            
            if (process.env.NODE_ENV === 'development') {
                logger.log('✅ Interessados encontrados:', rows.length);
            }
            
            return rows;
        } catch (error) {
            console.error('💥 ERRO ao buscar interessados:', error.message);
            if (process.env.NODE_ENV === 'development') {
                console.error('   Stack:', error.stack);
            }
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por interessados.', null, 'DATABASE_ERROR');
        }
    }

    // MUDANÇA: 'filters' foi removido da assinatura da função.
    async findDiretas({ profile, forcaMatchCondition }) {
        try {
            const allowEstadoIntention = allowsEstadoIntentionFromForcaCondition(forcaMatchCondition);
            const legAtoB = sqlMutualIntentionMatch(
                'int_A',
                {
                    unidadeAtual: 'int_B.unidade_atual_id',
                    municipioAtual: 'COALESCE(int_B.municipio_atual_id, u_B.municipio_id)',
                    eDireto: 'e_B_direto',
                    eUnidade: 'e_B_unidade',
                },
                allowEstadoIntention
            );
            const legBtoA = sqlMutualIntentionMatch(
                'int_B',
                {
                    unidadeAtual: 'int_A.unidade_atual_id',
                    municipioAtual: 'COALESCE(int_A.municipio_atual_id, u_A.municipio_id)',
                    eDireto: 'e_A_direto',
                    eUnidade: 'e_A_unidade',
                },
                allowEstadoIntention
            );

            // Usa subqueries para garantir que cada policial apareça apenas uma vez
            // Seleciona a intenção de maior prioridade (menor número) para cada policial
            let query = `
          SELECT DISTINCT B.id,
              CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END as nome,
              CASE WHEN B.ocultar_no_mapa = 0 THEN B.qso ELSE NULL END as qso,
              B.posto_graduacao_id, B.ocultar_no_mapa,
              (B.destaque_ate IS NOT NULL AND B.destaque_ate > NOW()) as em_destaque,
              pg_B.nome as posto_graduacao_nome,
              f_B.sigla as forca_sigla, f_B.nome as forca_nome, u_B.nome as unidade_atual, 
              COALESCE(m_B_direto.nome, m_B_unidade.nome) as municipio_atual, 
              COALESCE(e_B_direto.sigla, e_B_unidade.sigla) as estado_atual,
              (int_A.prioridade + int_B.prioridade) as soma_prioridades
          FROM (
              SELECT int_A2.policial_id, MIN(int_A2.prioridade) as min_prioridade
              FROM intencoes int_A2
              WHERE int_A2.policial_id = ?
              GROUP BY int_A2.policial_id
          ) as int_A_match
          JOIN intencoes int_A ON int_A.policial_id = int_A_match.policial_id 
              AND int_A.prioridade = int_A_match.min_prioridade
          JOIN policiais A ON int_A.policial_id = A.id
          JOIN forcas_policiais f_A ON A.forca_id = f_A.id
          LEFT JOIN unidades u_A ON int_A.unidade_atual_id = u_A.id
          LEFT JOIN municipios m_A_direto ON int_A.municipio_atual_id = m_A_direto.id
          LEFT JOIN estados e_A_direto ON m_A_direto.estado_id = e_A_direto.id
          LEFT JOIN municipios m_A_unidade ON u_A.municipio_id = m_A_unidade.id
          LEFT JOIN estados e_A_unidade ON m_A_unidade.estado_id = e_A_unidade.id
          JOIN (
              SELECT int_B2.policial_id, MIN(int_B2.prioridade) as min_prioridade
              FROM intencoes int_B2
              JOIN policiais p_B_temp ON int_B2.policial_id = p_B_temp.id
              WHERE p_B_temp.status_verificacao = 'VERIFICADO'
              AND (int_B2.unidade_atual_id IS NOT NULL OR int_B2.municipio_atual_id IS NOT NULL)
              GROUP BY int_B2.policial_id
          ) as int_B_match ON int_B_match.policial_id != A.id
          JOIN intencoes int_B ON int_B.policial_id = int_B_match.policial_id 
              AND int_B.prioridade = int_B_match.min_prioridade
          JOIN policiais B ON int_B.policial_id = B.id
          JOIN forcas_policiais f_B ON B.forca_id = f_B.id
          LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
          LEFT JOIN unidades u_B ON int_B.unidade_atual_id = u_B.id
          LEFT JOIN municipios m_B_direto ON int_B.municipio_atual_id = m_B_direto.id
          LEFT JOIN estados e_B_direto ON m_B_direto.estado_id = e_B_direto.id
          LEFT JOIN municipios m_B_unidade ON u_B.municipio_id = m_B_unidade.id
          LEFT JOIN estados e_B_unidade ON m_B_unidade.estado_id = e_B_unidade.id
          WHERE ${forcaMatchCondition}
          AND ${legAtoB}
          AND ${legBtoA}
      `;

            const params = [profile.id];

            // MUDANÇA: A lógica de filtro que existia aqui foi removida.

            query += ' ORDER BY em_destaque DESC, soma_prioridades ASC LIMIT 100';

            const [rows] = await db.execute(query, params);
            return rows;
        } catch (error) {
            console.error('💥 ERRO ao buscar permutas diretas:', error.message);
            if (process.env.NODE_ENV === 'development') {
                console.error('   Stack:', error.stack);
            }
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por permutas diretas.', null, 'DATABASE_ERROR');
        }
    }

    async findTriangulares({ profile, forcaTriangularCondition }) {
        try {
            const allowedForcaConditions = [
                'A.forca_id = B.forca_id AND B.forca_id = C.forca_id',
                'f_A.tipo_permuta = f_B.tipo_permuta AND f_B.tipo_permuta = f_C.tipo_permuta',
            ];
            if (!allowedForcaConditions.includes(forcaTriangularCondition)) {
                throw new ApiError(500, 'Condição de força inválida no findTriangulares');
            }

            const allowEstadoIntention = allowsEstadoIntentionFromForcaCondition(forcaTriangularCondition);
            const legAtoB = sqlMutualIntentionMatch(
                'int_A',
                {
                    unidadeAtual: 'int_B.unidade_atual_id',
                    municipioAtual: 'COALESCE(int_B.municipio_atual_id, u_B.municipio_id)',
                    eDireto: 'e_B_direto',
                    eUnidade: 'e_B_unidade',
                },
                allowEstadoIntention
            );
            const legBtoC = sqlMutualIntentionMatch(
                'int_B',
                {
                    unidadeAtual: 'int_C.unidade_atual_id',
                    municipioAtual: 'COALESCE(int_C.municipio_atual_id, u_C.municipio_id)',
                    eDireto: 'e_C_direto',
                    eUnidade: 'e_C_unidade',
                },
                allowEstadoIntention
            );
            const legCtoA = sqlMutualIntentionMatch(
                'int_C',
                {
                    unidadeAtual: 'int_A.unidade_atual_id',
                    municipioAtual: 'COALESCE(int_A.municipio_atual_id, u_A.municipio_id)',
                    eDireto: 'e_A_direto',
                    eUnidade: 'e_A_unidade',
                },
                allowEstadoIntention
            );

            const query = `
      SELECT DISTINCT 
          B.id as policial_b_id,
          CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END as policial_b_nome,
          CASE WHEN B.ocultar_no_mapa = 0 THEN B.qso ELSE NULL END as policial_b_qso,
          pg_B.nome as policial_b_posto_nome,
          f_B.sigla as policial_b_forca_sigla, u_B.nome as policial_b_unidade, 
          COALESCE(m_B_direto.nome, m_B_unidade.nome) as policial_b_municipio, 
          COALESCE(e_B_direto.sigla, e_B_unidade.sigla) as policial_b_estado,
          B.ocultar_no_mapa as policial_b_ocultar_no_mapa,
          C.id as policial_c_id,
          CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END as policial_c_nome,
          CASE WHEN C.ocultar_no_mapa = 0 THEN C.qso ELSE NULL END as policial_c_qso,
          pg_C.nome as policial_c_posto_nome,
          f_C.sigla as policial_c_forca_sigla, u_C.nome as policial_c_unidade, 
          COALESCE(m_C_direto.nome, m_C_unidade.nome) as policial_c_municipio, 
          COALESCE(e_C_direto.sigla, e_C_unidade.sigla) as policial_c_estado,
          C.ocultar_no_mapa as policial_c_ocultar_no_mapa,
          -- DESCRIÇÕES ESPECÍFICAS COM NOMES REAIS
          CASE 
              WHEN int_A.tipo_intencao = 'UNIDADE' THEN CONCAT('Você quer a unidade ', u_B.nome, ' de ', COALESCE(m_B_direto.nome, m_B_unidade.nome), '-', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
              WHEN int_A.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Você quer o município de ', COALESCE(m_B_direto.nome, m_B_unidade.nome), '-', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
              WHEN int_A.tipo_intencao = 'ESTADO' THEN CONCAT('Você quer o estado de ', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
          END as descricao_a,
          CASE 
              WHEN int_B.tipo_intencao = 'UNIDADE' THEN CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer a unidade ', u_C.nome, ' de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              WHEN int_B.tipo_intencao = 'MUNICIPIO' THEN CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer o município de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              WHEN int_B.tipo_intencao = 'ESTADO' THEN CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer o estado de ', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
          END as descricao_b,
          CASE 
              WHEN int_C.tipo_intencao = 'UNIDADE' THEN CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer sua unidade ', u_A.nome, ' de ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              WHEN int_C.tipo_intencao = 'MUNICIPIO' THEN CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer seu município ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              WHEN int_C.tipo_intencao = 'ESTADO' THEN CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer seu estado ', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
          END as descricao_c
      FROM (
          SELECT int_A2.policial_id, MIN(int_A2.prioridade) as min_prioridade
          FROM intencoes int_A2
          WHERE int_A2.policial_id = ?
          GROUP BY int_A2.policial_id
      ) as int_A_match
      JOIN intencoes int_A ON int_A.policial_id = int_A_match.policial_id 
          AND int_A.prioridade = int_A_match.min_prioridade
      JOIN policiais A ON int_A.policial_id = A.id
      JOIN forcas_policiais f_A ON A.forca_id = f_A.id
      LEFT JOIN unidades u_A ON int_A.unidade_atual_id = u_A.id
      LEFT JOIN municipios m_A_direto ON int_A.municipio_atual_id = m_A_direto.id
      LEFT JOIN estados e_A_direto ON m_A_direto.estado_id = e_A_direto.id
      LEFT JOIN municipios m_A_unidade ON u_A.municipio_id = m_A_unidade.id
      LEFT JOIN estados e_A_unidade ON m_A_unidade.estado_id = e_A_unidade.id
      JOIN (
          SELECT int_B2.policial_id, MIN(int_B2.prioridade) as min_prioridade
          FROM intencoes int_B2
          JOIN policiais p_B_temp ON int_B2.policial_id = p_B_temp.id
          WHERE p_B_temp.status_verificacao = 'VERIFICADO'
          AND (int_B2.unidade_atual_id IS NOT NULL OR int_B2.municipio_atual_id IS NOT NULL)
          GROUP BY int_B2.policial_id
      ) as int_B_match ON int_B_match.policial_id != A.id
      JOIN intencoes int_B ON int_B.policial_id = int_B_match.policial_id 
          AND int_B.prioridade = int_B_match.min_prioridade
      JOIN policiais B ON int_B.policial_id = B.id
      JOIN forcas_policiais f_B ON B.forca_id = f_B.id
      LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
      LEFT JOIN unidades u_B ON int_B.unidade_atual_id = u_B.id
      LEFT JOIN municipios m_B_direto ON int_B.municipio_atual_id = m_B_direto.id
      LEFT JOIN estados e_B_direto ON m_B_direto.estado_id = e_B_direto.id
      LEFT JOIN municipios m_B_unidade ON u_B.municipio_id = m_B_unidade.id
      LEFT JOIN estados e_B_unidade ON m_B_unidade.estado_id = e_B_unidade.id
      JOIN (
          SELECT int_C2.policial_id, MIN(int_C2.prioridade) as min_prioridade
          FROM intencoes int_C2
          JOIN policiais p_C_temp ON int_C2.policial_id = p_C_temp.id
          WHERE p_C_temp.status_verificacao = 'VERIFICADO'
          AND (int_C2.unidade_atual_id IS NOT NULL OR int_C2.municipio_atual_id IS NOT NULL)
          GROUP BY int_C2.policial_id
      ) as int_C_match ON int_C_match.policial_id != B.id AND int_C_match.policial_id != A.id
      JOIN intencoes int_C ON int_C.policial_id = int_C_match.policial_id 
          AND int_C.prioridade = int_C_match.min_prioridade
      JOIN policiais C ON int_C.policial_id = C.id
      JOIN forcas_policiais f_C ON C.forca_id = f_C.id
      LEFT JOIN postos_graduacoes pg_C ON C.posto_graduacao_id = pg_C.id
      LEFT JOIN unidades u_C ON int_C.unidade_atual_id = u_C.id
      LEFT JOIN municipios m_C_direto ON int_C.municipio_atual_id = m_C_direto.id
      LEFT JOIN estados e_C_direto ON m_C_direto.estado_id = e_C_direto.id
      LEFT JOIN municipios m_C_unidade ON u_C.municipio_id = m_C_unidade.id
      LEFT JOIN estados e_C_unidade ON m_C_unidade.estado_id = e_C_unidade.id
  WHERE ${forcaTriangularCondition}
      AND ${legAtoB}
      AND ${legBtoC}
      AND ${legCtoA}
      ORDER BY (int_A.prioridade + int_B.prioridade + int_C.prioridade) ASC
      LIMIT 50
  `;
            const [rows] = await db.execute(query, [profile.id]);
            return rows;
        } catch (error) {
            console.error('💥 ERRO ao buscar permutas triangulares:', error.message);
            if (process.env.NODE_ENV === 'development') {
                console.error('   Stack:', error.stack);
            }
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por permutas triangulares.', null, 'DATABASE_ERROR');
        }
    }

    /**
     * Interessados por proximidade: policiais cuja intenção (com raio_km) cobre
     * o município atual do perfil, sem ser match exato.
     */
    async findProximasInteressados({ profile, forcaCondition, forcaParams, municipioAtualId }) {
        if (!municipioAtualId) return [];

        try {
            let forcaConditionSafe = '';
            if (forcaCondition === 'f2.tipo_permuta = ?') {
                forcaConditionSafe = 'f_temp.tipo_permuta = ?';
            } else if (forcaCondition === 'p2.forca_id = ?') {
                forcaConditionSafe = 'p2.forca_id = ?';
            } else {
                throw new ApiError(500, 'Condição de força inválida no findProximasInteressados');
            }

            const query = `
      SELECT
          p2.id,
          CASE WHEN p2.ocultar_no_mapa = 0 THEN p2.nome ELSE 'Usuário não identificado' END as nome,
          CASE WHEN p2.ocultar_no_mapa = 0 THEN p2.qso ELSE NULL END as qso,
          p2.posto_graduacao_id, p2.ocultar_no_mapa,
          (p2.destaque_ate IS NOT NULL AND p2.destaque_ate > NOW()) as em_destaque,
          pg2.nome as posto_graduacao_nome,
          f2.sigla as forca_sigla, f2.nome as forca_nome,
          u2.nome as unidade_atual,
          COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual,
          COALESCE(e_direto.sigla, e_unidade.sigla) as estado_atual,
          i.prioridade, i.tipo_intencao, i.raio_km,
          m_dest.nome as municipio_referencia,
          ROUND(
            (6371 * ACOS(LEAST(1, GREATEST(-1,
              COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_atual.latitude)) *
              COS(RADIANS(m_atual.longitude) - RADIANS(m_dest.longitude)) +
              SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_atual.latitude))
            )))),
          1) as distancia_km,
          CONCAT(
            'Quer ficar perto de ',
            m_dest.nome, '-', e_dest.sigla,
            ' (raio ', i.raio_km, ' km) — você está a ',
            ROUND(
              (6371 * ACOS(LEAST(1, GREATEST(-1,
                COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_atual.latitude)) *
                COS(RADIANS(m_atual.longitude) - RADIANS(m_dest.longitude)) +
                SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_atual.latitude))
              )))),
            1),
            ' km'
          ) as descricao_interesse,
          'INTERESSADO' as tipo_proximidade
      FROM intencoes i
      JOIN policiais p2 ON i.policial_id = p2.id
      JOIN forcas_policiais f2 ON p2.forca_id = f2.id
      JOIN forcas_policiais f_temp ON p2.forca_id = f_temp.id
      JOIN municipios m_dest ON m_dest.id = i.municipio_id
      JOIN estados e_dest ON m_dest.estado_id = e_dest.id
      JOIN municipios m_atual ON m_atual.id = ?
      LEFT JOIN unidades u2 ON i.unidade_atual_id = u2.id
      LEFT JOIN municipios m_direto ON i.municipio_atual_id = m_direto.id
      LEFT JOIN estados e_direto ON m_direto.estado_id = e_direto.id
      LEFT JOIN municipios m_unidade ON u2.municipio_id = m_unidade.id
      LEFT JOIN estados e_unidade ON m_unidade.estado_id = e_unidade.id
      LEFT JOIN postos_graduacoes pg2 ON p2.posto_graduacao_id = pg2.id
      WHERE p2.id != ?
        AND ${forcaConditionSafe}
        AND p2.status_verificacao = 'VERIFICADO'
        AND i.tipo_intencao = 'MUNICIPIO'
        AND i.raio_km IS NOT NULL
        AND i.municipio_id IS NOT NULL
        AND m_dest.latitude IS NOT NULL AND m_dest.longitude IS NOT NULL
        AND m_atual.latitude IS NOT NULL AND m_atual.longitude IS NOT NULL
        AND i.municipio_id != ?
        AND (6371 * ACOS(LEAST(1, GREATEST(-1,
          COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_atual.latitude)) *
          COS(RADIANS(m_atual.longitude) - RADIANS(m_dest.longitude)) +
          SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_atual.latitude))
        )))) <= i.raio_km
      ORDER BY em_destaque DESC, distancia_km ASC
      LIMIT 100
      `;

            const params = [
                municipioAtualId,
                profile.id,
                ...forcaParams,
                municipioAtualId,
            ];

            const [rows] = await db.execute(query, params);
            return rows;
        } catch (error) {
            console.error('💥 ERRO ao buscar interessados próximos:', error.message);
            if (process.env.NODE_ENV === 'development') {
                console.error('   Stack:', error.stack);
            }
            throw new ApiError(500, 'Erro ao buscar interessados por proximidade.', null, 'DATABASE_ERROR');
        }
    }

    /**
     * Matches por proximidade baseados nas intenções do usuário com raio_km.
     * Inclui diretas próximas (mutual) e candidatos dentro do raio do destino desejado.
     */
    async findProximasPorMinhasIntencoes({
        profile,
        forcaMatchCondition,
        intencoesComRaio,
        municipioAtualId,
    }) {
        if (!intencoesComRaio.length || !municipioAtualId) return [];

        try {
            const results = [];

            for (const intencao of intencoesComRaio) {
                const destinoMunicipioId = intencao.destino_municipio_id;
                if (!destinoMunicipioId) continue;

                const query = `
          SELECT DISTINCT B.id,
              CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END as nome,
              CASE WHEN B.ocultar_no_mapa = 0 THEN B.qso ELSE NULL END as qso,
              B.posto_graduacao_id, B.ocultar_no_mapa,
              (B.destaque_ate IS NOT NULL AND B.destaque_ate > NOW()) as em_destaque,
              pg_B.nome as posto_graduacao_nome,
              f_B.sigla as forca_sigla, f_B.nome as forca_nome,
              u_B.nome as unidade_atual,
              COALESCE(m_B_direto.nome, m_B_unidade.nome) as municipio_atual,
              COALESCE(e_B_direto.sigla, e_B_unidade.sigla) as estado_atual,
              m_dest.nome as municipio_referencia,
              ROUND(
                (6371 * ACOS(LEAST(1, GREATEST(-1,
                  COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_B_curr.latitude)) *
                  COS(RADIANS(m_B_curr.longitude) - RADIANS(m_dest.longitude)) +
                  SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_B_curr.latitude))
                )))),
              1) as distancia_km,
              'DIRETA' as tipo_proximidade,
              CONCAT(
                'Está a ',
                ROUND(
                  (6371 * ACOS(LEAST(1, GREATEST(-1,
                    COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_B_curr.latitude)) *
                    COS(RADIANS(m_B_curr.longitude) - RADIANS(m_dest.longitude)) +
                    SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_B_curr.latitude))
                  )))),
                1),
                ' km de ', m_dest.nome, ' (seu destino). ',
                CASE
                  WHEN int_B2.tipo_intencao = 'UNIDADE' THEN CONCAT('Quer ir para unidade: ', COALESCE(u_B_int_dest.nome, 'não informada'))
                  WHEN int_B2.tipo_intencao = 'MUNICIPIO' THEN CONCAT(
                    'Quer ir para: ',
                    COALESCE(m_B_dest.nome, 'município não informado'),
                    CASE WHEN e_B_dest_int.sigla IS NOT NULL THEN CONCAT('-', e_B_dest_int.sigla) ELSE '' END
                  )
                  WHEN int_B2.tipo_intencao = 'ESTADO' THEN CONCAT('Quer ir para estado: ', COALESCE(e_B_dest_int.sigla, 'não informado'))
                  ELSE 'Intenção de destino não informada'
                END
              ) as descricao_interesse
          FROM intencoes int_B
          JOIN policiais B ON int_B.policial_id = B.id
          JOIN forcas_policiais f_B ON B.forca_id = f_B.id
          JOIN policiais A ON A.id = ?
          JOIN forcas_policiais f_A ON A.forca_id = f_A.id
          JOIN municipios m_dest ON m_dest.id = ?
          JOIN municipios m_me ON m_me.id = ?
          LEFT JOIN unidades u_B ON int_B.unidade_atual_id = u_B.id
          LEFT JOIN municipios m_B_direto ON int_B.municipio_atual_id = m_B_direto.id
          LEFT JOIN estados e_B_direto ON m_B_direto.estado_id = e_B_direto.id
          LEFT JOIN municipios m_B_unidade ON u_B.municipio_id = m_B_unidade.id
          LEFT JOIN estados e_B_unidade ON m_B_unidade.estado_id = e_B_unidade.id
          JOIN municipios m_B_curr ON m_B_curr.id = COALESCE(int_B.municipio_atual_id, u_B.municipio_id)
          LEFT JOIN intencoes int_B2 ON int_B2.policial_id = B.id AND int_B2.prioridade = (
            SELECT MIN(ib.prioridade) FROM intencoes ib WHERE ib.policial_id = B.id
          )
          LEFT JOIN unidades u_B_int_dest ON int_B2.unidade_id = u_B_int_dest.id
          LEFT JOIN municipios m_B_dest ON m_B_dest.id = COALESCE(int_B2.municipio_id, u_B_int_dest.municipio_id)
          LEFT JOIN estados e_B_dest_int ON e_B_dest_int.id = COALESCE(m_B_dest.estado_id, int_B2.estado_id)
          LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
          WHERE B.id != A.id
            AND B.status_verificacao = 'VERIFICADO'
            AND ${forcaMatchCondition}
            AND (int_B.unidade_atual_id IS NOT NULL OR int_B.municipio_atual_id IS NOT NULL)
            AND m_dest.latitude IS NOT NULL AND m_B_curr.latitude IS NOT NULL
            AND COALESCE(int_B.municipio_atual_id, u_B.municipio_id) != ?
            AND (6371 * ACOS(LEAST(1, GREATEST(-1,
              COS(RADIANS(m_dest.latitude)) * COS(RADIANS(m_B_curr.latitude)) *
              COS(RADIANS(m_B_curr.longitude) - RADIANS(m_dest.longitude)) +
              SIN(RADIANS(m_dest.latitude)) * SIN(RADIANS(m_B_curr.latitude))
            )))) <= ?
            AND int_B.raio_km IS NOT NULL
            AND int_B2.id IS NOT NULL
            AND m_B_dest.latitude IS NOT NULL
            AND m_me.latitude IS NOT NULL
            AND (6371 * ACOS(LEAST(1, GREATEST(-1,
              COS(RADIANS(m_B_dest.latitude)) * COS(RADIANS(m_me.latitude)) *
              COS(RADIANS(m_me.longitude) - RADIANS(m_B_dest.longitude)) +
              SIN(RADIANS(m_B_dest.latitude)) * SIN(RADIANS(m_me.latitude))
            )))) <= int_B.raio_km
          ORDER BY em_destaque DESC, distancia_km ASC
          LIMIT 50
        `;

                const params = [
                    profile.id,
                    destinoMunicipioId,
                    municipioAtualId,
                    destinoMunicipioId,
                    intencao.raio_km,
                ];

                const [rows] = await db.execute(query, params);
                results.push(...rows);
            }

            const byId = new Map();
            for (const row of results) {
                const existing = byId.get(row.id);
                if (!existing || row.distancia_km < existing.distancia_km) {
                    byId.set(row.id, row);
                } else if (
                    existing.tipo_proximidade !== 'DIRETA' &&
                    row.tipo_proximidade === 'DIRETA'
                ) {
                    byId.set(row.id, row);
                }
            }

            return Array.from(byId.values()).sort(
                (a, b) => parseFloat(a.distancia_km) - parseFloat(b.distancia_km)
            );
        } catch (error) {
            console.error('💥 ERRO ao buscar próximas por intenção:', error.message);
            throw new ApiError(500, 'Erro ao buscar permutas por proximidade.', null, 'DATABASE_ERROR');
        }
    }

    async findTriangularesProximas({ profile, forcaTriangularCondition }) {
        try {
            const allowedForcaConditions = [
                'A.forca_id = B.forca_id AND B.forca_id = C.forca_id',
                'f_A.tipo_permuta = f_B.tipo_permuta AND f_B.tipo_permuta = f_C.tipo_permuta',
            ];
            if (!allowedForcaConditions.includes(forcaTriangularCondition)) {
                throw new ApiError(500, 'Condição de força inválida no findTriangularesProximas');
            }

            const allowEstadoIntention = allowsEstadoIntentionFromForcaCondition(forcaTriangularCondition);

            const legAb = sqlLegMatch({
                intAlias: 'int_A',
                uTargetAlias: 'u_B',
                mTargetDirAlias: 'm_B_direto',
                mTargetUnitAlias: 'm_B_unidade',
                eTargetDirAlias: 'e_B_direto',
                eTargetUnitAlias: 'e_B_unidade',
                mDestAlias: 'm_dest_A',
                mUnidadeDestAlias: 'm_u_dest_A',
                mCurrAlias: 'm_curr_B',
                allowEstadoIntention,
            });
            const legBc = sqlLegMatch({
                intAlias: 'int_B',
                uTargetAlias: 'u_C',
                mTargetDirAlias: 'm_C_direto',
                mTargetUnitAlias: 'm_C_unidade',
                eTargetDirAlias: 'e_C_direto',
                eTargetUnitAlias: 'e_C_unidade',
                mDestAlias: 'm_dest_B',
                mUnidadeDestAlias: 'm_u_dest_B',
                mCurrAlias: 'm_curr_C',
                allowEstadoIntention,
            });
            const legCa = sqlLegMatch({
                intAlias: 'int_C',
                uTargetAlias: 'u_A',
                mTargetDirAlias: 'm_A_direto',
                mTargetUnitAlias: 'm_A_unidade',
                eTargetDirAlias: 'e_A_direto',
                eTargetUnitAlias: 'e_A_unidade',
                mDestAlias: 'm_dest_C',
                mUnidadeDestAlias: 'm_u_dest_C',
                mCurrAlias: 'm_curr_A',
                allowEstadoIntention,
            });

            const legAbExact = sqlLegExactOnly({
                intAlias: 'int_A',
                uTargetAlias: 'u_B',
                mCurrAlias: 'm_curr_B',
                eTargetDirAlias: 'e_B_direto',
                eTargetUnitAlias: 'e_B_unidade',
                allowEstadoIntention,
            });
            const legBcExact = sqlLegExactOnly({
                intAlias: 'int_B',
                uTargetAlias: 'u_C',
                mCurrAlias: 'm_curr_C',
                eTargetDirAlias: 'e_C_direto',
                eTargetUnitAlias: 'e_C_unidade',
                allowEstadoIntention,
            });
            const legCaExact = sqlLegExactOnly({
                intAlias: 'int_C',
                uTargetAlias: 'u_A',
                mCurrAlias: 'm_curr_A',
                eTargetDirAlias: 'e_A_direto',
                eTargetUnitAlias: 'e_A_unidade',
                allowEstadoIntention,
            });

            const distAb = haversineKm(
                'm_dest_A.latitude',
                'm_dest_A.longitude',
                'm_curr_B.latitude',
                'm_curr_B.longitude'
            );
            const distBc = haversineKm(
                'm_dest_B.latitude',
                'm_dest_B.longitude',
                'm_curr_C.latitude',
                'm_curr_C.longitude'
            );
            const distCa = haversineKm(
                'm_dest_C.latitude',
                'm_dest_C.longitude',
                'm_curr_A.latitude',
                'm_curr_A.longitude'
            );

            const query = `
      SELECT DISTINCT
          B.id as policial_b_id,
          CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END as policial_b_nome,
          CASE WHEN B.ocultar_no_mapa = 0 THEN B.qso ELSE NULL END as policial_b_qso,
          pg_B.nome as policial_b_posto_nome,
          f_B.sigla as policial_b_forca_sigla, u_B.nome as policial_b_unidade,
          COALESCE(m_B_direto.nome, m_B_unidade.nome) as policial_b_municipio,
          COALESCE(e_B_direto.sigla, e_B_unidade.sigla) as policial_b_estado,
          B.ocultar_no_mapa as policial_b_ocultar_no_mapa,
          C.id as policial_c_id,
          CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END as policial_c_nome,
          CASE WHEN C.ocultar_no_mapa = 0 THEN C.qso ELSE NULL END as policial_c_qso,
          pg_C.nome as policial_c_posto_nome,
          f_C.sigla as policial_c_forca_sigla, u_C.nome as policial_c_unidade,
          COALESCE(m_C_direto.nome, m_C_unidade.nome) as policial_c_municipio,
          COALESCE(e_C_direto.sigla, e_C_unidade.sigla) as policial_c_estado,
          C.ocultar_no_mapa as policial_c_ocultar_no_mapa,
          ROUND(GREATEST(
            COALESCE(CASE WHEN NOT (${legAbExact}) THEN ${distAb} END, 0),
            COALESCE(CASE WHEN NOT (${legBcExact}) THEN ${distBc} END, 0),
            COALESCE(CASE WHEN NOT (${legCaExact}) THEN ${distCa} END, 0)
          ), 1) as distancia_km,
          CONCAT(
            CASE
              WHEN int_A.tipo_intencao = 'UNIDADE' THEN CONCAT('Você quer a unidade ', u_B.nome, ' de ', COALESCE(m_B_direto.nome, m_B_unidade.nome), '-', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
              WHEN int_A.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Você quer o município de ', COALESCE(m_B_direto.nome, m_B_unidade.nome), '-', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
              ELSE CONCAT('Você quer o estado de ', COALESCE(e_B_direto.sigla, e_B_unidade.sigla))
            END,
            CASE WHEN NOT (${legAbExact}) THEN CONCAT(' (~', ROUND(${distAb}, 1), ' km)') ELSE '' END
          ) as descricao_a,
          CONCAT(
            CASE
              WHEN int_B.tipo_intencao = 'UNIDADE' THEN CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer a unidade ', u_C.nome, ' de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              WHEN int_B.tipo_intencao = 'MUNICIPIO' THEN CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer o município de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              ELSE CONCAT(CASE WHEN B.ocultar_no_mapa = 0 THEN B.nome ELSE 'Usuário não identificado' END, ' quer o estado de ', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
            END,
            CASE WHEN NOT (${legBcExact}) THEN CONCAT(' (~', ROUND(${distBc}, 1), ' km)') ELSE '' END
          ) as descricao_b,
          CONCAT(
            CASE
              WHEN int_C.tipo_intencao = 'UNIDADE' THEN CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer sua unidade ', u_A.nome, ' de ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              WHEN int_C.tipo_intencao = 'MUNICIPIO' THEN CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer seu município ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              ELSE CONCAT(CASE WHEN C.ocultar_no_mapa = 0 THEN C.nome ELSE 'Usuário não identificado' END, ' quer seu estado ', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
            END,
            CASE WHEN NOT (${legCaExact}) THEN CONCAT(' (~', ROUND(${distCa}, 1), ' km)') ELSE '' END
          ) as descricao_c,
          1 as por_aproximacao
      FROM (
          SELECT int_A2.policial_id, MIN(int_A2.prioridade) as min_prioridade
          FROM intencoes int_A2
          WHERE int_A2.policial_id = ?
          GROUP BY int_A2.policial_id
      ) as int_A_match
      JOIN intencoes int_A ON int_A.policial_id = int_A_match.policial_id
          AND int_A.prioridade = int_A_match.min_prioridade
      JOIN policiais A ON int_A.policial_id = A.id
      JOIN forcas_policiais f_A ON A.forca_id = f_A.id
      LEFT JOIN unidades u_A ON int_A.unidade_atual_id = u_A.id
      LEFT JOIN municipios m_A_direto ON int_A.municipio_atual_id = m_A_direto.id
      LEFT JOIN estados e_A_direto ON m_A_direto.estado_id = e_A_direto.id
      LEFT JOIN municipios m_A_unidade ON u_A.municipio_id = m_A_unidade.id
      LEFT JOIN estados e_A_unidade ON m_A_unidade.estado_id = e_A_unidade.id
      LEFT JOIN municipios m_dest_A ON m_dest_A.id = int_A.municipio_id
      LEFT JOIN unidades u_dest_A ON u_dest_A.id = int_A.unidade_id
      LEFT JOIN municipios m_u_dest_A ON m_u_dest_A.id = u_dest_A.municipio_id
      JOIN municipios m_curr_A ON m_curr_A.id = COALESCE(int_A.municipio_atual_id, u_A.municipio_id)
      JOIN (
          SELECT int_B2.policial_id, MIN(int_B2.prioridade) as min_prioridade
          FROM intencoes int_B2
          JOIN policiais p_B_temp ON int_B2.policial_id = p_B_temp.id
          WHERE p_B_temp.status_verificacao = 'VERIFICADO'
          AND (int_B2.unidade_atual_id IS NOT NULL OR int_B2.municipio_atual_id IS NOT NULL)
          GROUP BY int_B2.policial_id
      ) as int_B_match ON int_B_match.policial_id != A.id
      JOIN intencoes int_B ON int_B.policial_id = int_B_match.policial_id
          AND int_B.prioridade = int_B_match.min_prioridade
      JOIN policiais B ON int_B.policial_id = B.id
      JOIN forcas_policiais f_B ON B.forca_id = f_B.id
      LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
      LEFT JOIN unidades u_B ON int_B.unidade_atual_id = u_B.id
      LEFT JOIN municipios m_B_direto ON int_B.municipio_atual_id = m_B_direto.id
      LEFT JOIN estados e_B_direto ON m_B_direto.estado_id = e_B_direto.id
      LEFT JOIN municipios m_B_unidade ON u_B.municipio_id = m_B_unidade.id
      LEFT JOIN estados e_B_unidade ON m_B_unidade.estado_id = e_B_unidade.id
      LEFT JOIN municipios m_dest_B ON m_dest_B.id = int_B.municipio_id
      LEFT JOIN unidades u_dest_B ON u_dest_B.id = int_B.unidade_id
      LEFT JOIN municipios m_u_dest_B ON m_u_dest_B.id = u_dest_B.municipio_id
      JOIN municipios m_curr_B ON m_curr_B.id = COALESCE(int_B.municipio_atual_id, u_B.municipio_id)
      JOIN (
          SELECT int_C2.policial_id, MIN(int_C2.prioridade) as min_prioridade
          FROM intencoes int_C2
          JOIN policiais p_C_temp ON int_C2.policial_id = p_C_temp.id
          WHERE p_C_temp.status_verificacao = 'VERIFICADO'
          AND (int_C2.unidade_atual_id IS NOT NULL OR int_C2.municipio_atual_id IS NOT NULL)
          GROUP BY int_C2.policial_id
      ) as int_C_match ON int_C_match.policial_id != B.id AND int_C_match.policial_id != A.id
      JOIN intencoes int_C ON int_C.policial_id = int_C_match.policial_id
          AND int_C.prioridade = int_C_match.min_prioridade
      JOIN policiais C ON int_C.policial_id = C.id
      JOIN forcas_policiais f_C ON C.forca_id = f_C.id
      LEFT JOIN postos_graduacoes pg_C ON C.posto_graduacao_id = pg_C.id
      LEFT JOIN unidades u_C ON int_C.unidade_atual_id = u_C.id
      LEFT JOIN municipios m_C_direto ON int_C.municipio_atual_id = m_C_direto.id
      LEFT JOIN estados e_C_direto ON m_C_direto.estado_id = e_C_direto.id
      LEFT JOIN municipios m_C_unidade ON u_C.municipio_id = m_C_unidade.id
      LEFT JOIN estados e_C_unidade ON m_C_unidade.estado_id = e_C_unidade.id
      LEFT JOIN municipios m_dest_C ON m_dest_C.id = int_C.municipio_id
      LEFT JOIN unidades u_dest_C ON u_dest_C.id = int_C.unidade_id
      LEFT JOIN municipios m_u_dest_C ON m_u_dest_C.id = u_dest_C.municipio_id
      JOIN municipios m_curr_C ON m_curr_C.id = COALESCE(int_C.municipio_atual_id, u_C.municipio_id)
      WHERE ${forcaTriangularCondition}
        AND ${legAb}
        AND ${legBc}
        AND ${legCa}
        AND NOT (${legAbExact} AND ${legBcExact} AND ${legCaExact})
        AND (
          int_A.raio_km IS NOT NULL OR int_B.raio_km IS NOT NULL OR int_C.raio_km IS NOT NULL
        )
      ORDER BY distancia_km ASC, (int_A.prioridade + int_B.prioridade + int_C.prioridade) ASC
      LIMIT 30
      `;

            const [rows] = await db.execute(query, [profile.id]);
            return rows;
        } catch (error) {
            console.error('💥 ERRO ao buscar triangulares por proximidade:', error.message);
            if (process.env.NODE_ENV === 'development') {
                console.error('   Stack:', error.stack);
            }
            throw new ApiError(
                500,
                'Ocorreu um erro ao buscar permutas triangulares por proximidade.',
                null,
                'DATABASE_ERROR'
            );
        }
    }
}

module.exports = new PermutasRepository();
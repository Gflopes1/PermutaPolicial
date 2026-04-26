// /src/modules/permutas/permutas.repository.js

const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');

class PermutasRepository {

    // MUDANÇA: 'filters' foi removido da assinatura da função.
    async findInteressados({ profile, forcaCondition, forcaParams }) {
        try {
            if (process.env.NODE_ENV === 'development') {
                console.log('🔍 DEBUG PROFILE no findInteressados:');
                console.log('   Unidade ID:', profile.unidade_atual_id);
                console.log('   Município ID:', profile.municipio_id);
                console.log('   Estado ID:', profile.estado_id);
                console.log('   Força Condition:', forcaCondition);
                console.log('   Força Params:', forcaParams);
            }

            // Busca as intenções do perfil para obter o local de cada intenção
            const [intencoesPerfil] = await db.execute(
                'SELECT unidade_atual_id, municipio_atual_id FROM intencoes WHERE policial_id = ?',
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
                // Fallback seguro: se vier algo inesperado, usa uma condição que sempre falha
                throw new ApiError(500, 'Condição de força inválida no findInteressados');
            }

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
          pg2.nome as posto_graduacao_nome,
          f2.sigla as forca_sigla, f2.nome as forca_nome,
          u2.nome as unidade_atual,
          COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual, 
          COALESCE(e_direto.sigla, e_unidade.sigla) as estado_atual,
          i.prioridade, i.tipo_intencao,
          CASE 
              WHEN i.tipo_intencao = 'UNIDADE' THEN CONCAT('Quer sua unidade específica: ', u2.nome)
              WHEN i.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Quer seu município: ', COALESCE(m_direto.nome, m_unidade.nome), '-', COALESCE(e_direto.sigla, e_unidade.sigla))
              WHEN i.tipo_intencao = 'ESTADO' THEN CONCAT('Quer seu estado: ', COALESCE(e_direto.sigla, e_unidade.sigla))
          END as descricao_interesse
      FROM (
          SELECT i2.policial_id, MIN(i2.prioridade) as min_prioridade
          FROM intencoes i2
          JOIN policiais p_temp ON i2.policial_id = p_temp.id
          JOIN forcas_policiais f_temp ON p_temp.forca_id = f_temp.id
          WHERE p_temp.id != ? 
          AND ${forcaConditionSafe}
          AND p_temp.agente_verificado = 1
          AND (i2.unidade_atual_id IS NOT NULL OR i2.municipio_atual_id IS NOT NULL)
          AND (
              (i2.tipo_intencao = 'UNIDADE' AND i2.unidade_id = ?) OR
              (i2.tipo_intencao = 'MUNICIPIO' AND i2.municipio_id = ?) OR
              (i2.tipo_intencao = 'ESTADO' AND i2.estado_id = ?)
          )
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
      WHERE (
          (i.tipo_intencao = 'UNIDADE' AND i.unidade_id = ?) OR
          (i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?) OR
          (i.tipo_intencao = 'ESTADO' AND i.estado_id = ?)
      )
    `;

            // ✅ CORREÇÃO: Agora usa o local da intenção ao invés do perfil
            // Os parâmetros são duplicados porque aparecem na subquery e na query principal
            const params = [
                profile.id,
                ...forcaParams,
                unidadeAtualId,      // para UNIDADE (subquery)
                municipioAtualId,    // para MUNICIPIO (subquery)
                estadoIdPerfil,      // para ESTADO (subquery)
                unidadeAtualId,      // para UNIDADE (query principal)
                municipioAtualId,    // para MUNICIPIO (query principal)
                estadoIdPerfil       // para ESTADO (query principal)
            ];

            if (process.env.NODE_ENV === 'development') {
                console.log('📋 Query params:', params);
            }

            query += ' ORDER BY i.prioridade ASC';

            const [rows] = await db.execute(query, params);
            
            if (process.env.NODE_ENV === 'development') {
                console.log('✅ Interessados encontrados:', rows.length);
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
            // Usa subqueries para garantir que cada policial apareça apenas uma vez
            // Seleciona a intenção de maior prioridade (menor número) para cada policial
            let query = `
          SELECT DISTINCT B.id, B.nome, 
              CASE WHEN B.ocultar_no_mapa = 0 THEN B.qso ELSE NULL END as qso,
              B.posto_graduacao_id, B.ocultar_no_mapa,
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
          AND (
              (int_A.tipo_intencao = 'UNIDADE' AND int_A.unidade_id = int_B.unidade_atual_id) OR 
              (int_A.tipo_intencao = 'MUNICIPIO' AND int_A.municipio_id = COALESCE(int_B.municipio_atual_id, u_B.municipio_id)) OR 
              (int_A.tipo_intencao = 'ESTADO' AND int_A.estado_id = COALESCE(e_B_direto.id, e_B_unidade.id))
          )
          AND (
              (int_B.tipo_intencao = 'UNIDADE' AND int_B.unidade_id = int_A.unidade_atual_id) OR 
              (int_B.tipo_intencao = 'MUNICIPIO' AND int_B.municipio_id = COALESCE(int_A.municipio_atual_id, u_A.municipio_id)) OR 
              (int_B.tipo_intencao = 'ESTADO' AND int_B.estado_id = COALESCE(e_A_direto.id, e_A_unidade.id))
          )
      `;

            const params = [profile.id];

            // MUDANÇA: A lógica de filtro que existia aqui foi removida.

            query += ' ORDER BY soma_prioridades ASC LIMIT 100';

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

    async findTriangulares({ profile, forcaMatchCondition }) {
        try {
            const forcaTriangularCondition = forcaMatchCondition
                .replace('A.forca_id = B.forca_id', 'A.forca_id = B.forca_id AND B.forca_id = C.forca_id')
                .replace('f_A.tipo_permuta = f_B.tipo_permuta', 'f_A.tipo_permuta = f_B.tipo_permuta AND f_B.tipo_permuta = f_C.tipo_permuta');

            // Usa subqueries para garantir que cada policial apareça apenas uma vez
            // Seleciona a intenção de maior prioridade (menor número) para cada policial
            const query = `
      SELECT DISTINCT 
          B.id as policial_b_id, B.nome as policial_b_nome, B.qso as policial_b_qso, pg_B.nome as policial_b_posto_nome,
          f_B.sigla as policial_b_forca_sigla, u_B.nome as policial_b_unidade, 
          COALESCE(m_B_direto.nome, m_B_unidade.nome) as policial_b_municipio, 
          COALESCE(e_B_direto.sigla, e_B_unidade.sigla) as policial_b_estado,
          B.ocultar_no_mapa as policial_b_ocultar_no_mapa,
          C.id as policial_c_id, C.nome as policial_c_nome, C.qso as policial_c_qso, pg_C.nome as policial_c_posto_nome,
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
              WHEN int_B.tipo_intencao = 'UNIDADE' THEN CONCAT(B.nome, ' quer a unidade ', u_C.nome, ' de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              WHEN int_B.tipo_intencao = 'MUNICIPIO' THEN CONCAT(B.nome, ' quer o município de ', COALESCE(m_C_direto.nome, m_C_unidade.nome), '-', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
              WHEN int_B.tipo_intencao = 'ESTADO' THEN CONCAT(B.nome, ' quer o estado de ', COALESCE(e_C_direto.sigla, e_C_unidade.sigla))
          END as descricao_b,
          CASE 
              WHEN int_C.tipo_intencao = 'UNIDADE' THEN CONCAT(C.nome, ' quer sua unidade ', u_A.nome, ' de ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              WHEN int_C.tipo_intencao = 'MUNICIPIO' THEN CONCAT(C.nome, ' quer seu município ', COALESCE(m_A_direto.nome, m_A_unidade.nome), '-', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
              WHEN int_C.tipo_intencao = 'ESTADO' THEN CONCAT(C.nome, ' quer seu estado ', COALESCE(e_A_direto.sigla, e_A_unidade.sigla))
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
      AND (
          (int_A.tipo_intencao = 'UNIDADE' AND int_A.unidade_id = int_B.unidade_atual_id) OR 
          (int_A.tipo_intencao = 'MUNICIPIO' AND int_A.municipio_id = COALESCE(int_B.municipio_atual_id, u_B.municipio_id)) OR 
          (int_A.tipo_intencao = 'ESTADO' AND int_A.estado_id = COALESCE(e_B_direto.id, e_B_unidade.id))
      )
      AND (
          (int_B.tipo_intencao = 'UNIDADE' AND int_B.unidade_id = int_C.unidade_atual_id) OR 
          (int_B.tipo_intencao = 'MUNICIPIO' AND int_B.municipio_id = COALESCE(int_C.municipio_atual_id, u_C.municipio_id)) OR 
          (int_B.tipo_intencao = 'ESTADO' AND int_B.estado_id = COALESCE(e_C_direto.id, e_C_unidade.id))
      )
      AND (
          (int_C.tipo_intencao = 'UNIDADE' AND int_C.unidade_id = int_A.unidade_atual_id) OR 
          (int_C.tipo_intencao = 'MUNICIPIO' AND int_C.municipio_id = COALESCE(int_A.municipio_atual_id, u_A.municipio_id)) OR 
          (int_C.tipo_intencao = 'ESTADO' AND int_C.estado_id = COALESCE(e_A_direto.id, e_A_unidade.id))
      )
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
}

module.exports = new PermutasRepository();
// /src/modules/permutas/permutas.repository.js

const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');

class PermutasRepository {

    // MUDANÇA: 'filters' foi removido da assinatura da função.
    async findInteressados({ profile, forcaCondition, forcaParams }) {
        try {
            console.log('🔍 DEBUG PROFILE no findInteressados:');
            console.log('   Unidade ID:', profile.unidade_atual_id);
            console.log('   Município ID:', profile.municipio_id);
            console.log('   Estado ID:', profile.estado_id);
            console.log('   Força Condition:', forcaCondition);
            console.log('   Força Params:', forcaParams);

            let query = `
      SELECT DISTINCT 
          p2.id, p2.nome, p2.qso, p2.posto_graduacao_id,
          pg2.nome as posto_graduacao_nome,
          f2.sigla as forca_sigla, f2.nome as forca_nome,
          u2.nome as unidade_atual, m2.nome as municipio_atual, e2.sigla as estado_atual,
          i.prioridade, i.tipo_intencao,
          CASE 
              WHEN i.tipo_intencao = 'UNIDADE' THEN CONCAT('Quer sua unidade específica: ', u2.nome)
              WHEN i.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Quer seu município: ', m2.nome, '-', e2.sigla)
              WHEN i.tipo_intencao = 'ESTADO' THEN CONCAT('Quer seu estado: ', e2.sigla)
          END as descricao_interesse
      FROM policiais p2
      JOIN intencoes i ON p2.id = i.policial_id
      JOIN forcas_policiais f2 ON p2.forca_id = f2.id
      LEFT JOIN unidades u2 ON p2.unidade_atual_id = u2.id
      LEFT JOIN municipios m2 ON u2.municipio_id = m2.id
      LEFT JOIN estados e2 ON m2.estado_id = e2.id
      LEFT JOIN postos_graduacoes pg2 ON p2.posto_graduacao_id = pg2.id
      WHERE p2.id != ? 
      AND ${forcaCondition}
      AND p2.status_verificacao = 'VERIFICADO'
      AND p2.unidade_atual_id IS NOT NULL
      AND (
          (i.tipo_intencao = 'UNIDADE' AND i.unidade_id = ?) OR
          (i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?) OR
          (i.tipo_intencao = 'ESTADO' AND i.estado_id = ?)
      )
    `;

            // ✅ CORREÇÃO: Agora inclui município e estado também
            const params = [
                profile.id,
                ...forcaParams,
                profile.unidade_atual_id,  // para UNIDADE
                profile.municipio_id,      // para MUNICIPIO  
                profile.estado_id          // para ESTADO
            ];

            console.log('📋 Query params:', params);

            query += ' ORDER BY i.prioridade ASC';

            const [rows] = await db.execute(query, params);
            console.log('✅ Interessados encontrados:', rows.length);
            return rows;
        } catch (error) {
            console.error('💥 ERRO DETALHADO:', error.message);
            console.error('   Stack:', error.stack);
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por interessados.');
        }
    }

    // MUDANÇA: 'filters' foi removido da assinatura da função.
    async findDiretas({ profile, forcaMatchCondition }) {
        try {
            let query = `
          SELECT DISTINCT B.id, B.nome, B.qso, B.posto_graduacao_id, pg_B.nome as posto_graduacao_nome,
              f_B.sigla as forca_sigla, f_B.nome as forca_nome, u_B.nome as unidade_atual, 
              m_B.nome as municipio_atual, e_B.sigla as estado_atual,
              (int_A.prioridade + int_B.prioridade) as soma_prioridades
          FROM policiais A
          JOIN intencoes int_A ON A.id = int_A.policial_id
          JOIN forcas_policiais f_A ON A.forca_id = f_A.id
          JOIN unidades u_A ON A.unidade_atual_id = u_A.id
          JOIN municipios m_A ON u_A.municipio_id = m_A.id
          JOIN estados e_A ON m_A.estado_id = e_A.id
          JOIN policiais B ON B.id != A.id
          JOIN forcas_policiais f_B ON B.forca_id = f_B.id
          JOIN intencoes int_B ON B.id = int_B.policial_id
          LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
          JOIN unidades u_B ON B.unidade_atual_id = u_B.id
          JOIN municipios m_B ON u_B.municipio_id = m_B.id
          JOIN estados e_B ON m_B.estado_id = e_B.id
          WHERE A.id = ? AND B.status_verificacao = 'VERIFICADO' AND B.unidade_atual_id IS NOT NULL
          AND ${forcaMatchCondition}
          AND ((int_A.tipo_intencao = 'UNIDADE' AND int_A.unidade_id = B.unidade_atual_id) OR (int_A.tipo_intencao = 'MUNICIPIO' AND int_A.municipio_id = u_B.municipio_id) OR (int_A.tipo_intencao = 'ESTADO' AND int_A.estado_id = m_B.estado_id))
          AND ((int_B.tipo_intencao = 'UNIDADE' AND int_B.unidade_id = A.unidade_atual_id) OR (int_B.tipo_intencao = 'MUNICIPIO' AND int_B.municipio_id = m_A.id) OR (int_B.tipo_intencao = 'ESTADO' AND int_B.estado_id = e_A.id))
      `;

            const params = [profile.id];

            // MUDANÇA: A lógica de filtro que existia aqui foi removida.

            query += ' ORDER BY soma_prioridades ASC LIMIT 100';

            const [rows] = await db.execute(query, params);
            return rows;
        } catch (error) {
            console.error('ERRO NA QUERY FINDDIRETAS:', error);
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por permutas diretas.');
        }
    }

    async findTriangulares({ profile, forcaMatchCondition }) {
        try {
            const forcaTriangularCondition = forcaMatchCondition
                .replace('A.forca_id = B.forca_id', 'A.forca_id = B.forca_id AND B.forca_id = C.forca_id')
                .replace('f_A.tipo_permuta = f_B.tipo_permuta', 'f_A.tipo_permuta = f_B.tipo_permuta AND f_B.tipo_permuta = f_C.tipo_permuta');

            const query = `
      SELECT DISTINCT 
          B.id as policial_b_id, B.nome as policial_b_nome, B.qso as policial_b_qso, pg_B.nome as policial_b_posto_nome,
          f_B.sigla as policial_b_forca_sigla, u_B.nome as policial_b_unidade, m_B.nome as policial_b_municipio, e_B.sigla as policial_b_estado,
          C.id as policial_c_id, C.nome as policial_c_nome, C.qso as policial_c_qso, pg_C.nome as policial_c_posto_nome,
          f_C.sigla as policial_c_forca_sigla, u_C.nome as policial_c_unidade, m_C.nome as policial_c_municipio, e_C.sigla as policial_c_estado,
          -- DESCRIÇÕES ESPECÍFICAS COM NOMES REAIS
          CASE 
              WHEN int_A.tipo_intencao = 'UNIDADE' THEN CONCAT('Você quer a unidade ', u_B.nome, ' de ', m_B.nome, '-', e_B.sigla)
              WHEN int_A.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Você quer o município de ', m_B.nome, '-', e_B.sigla)
              WHEN int_A.tipo_intencao = 'ESTADO' THEN CONCAT('Você quer o estado de ', e_B.sigla)
          END as descricao_a,
          CASE 
              WHEN int_B.tipo_intencao = 'UNIDADE' THEN CONCAT(B.nome, ' quer a unidade ', u_C.nome, ' de ', m_C.nome, '-', e_C.sigla)
              WHEN int_B.tipo_intencao = 'MUNICIPIO' THEN CONCAT(B.nome, ' quer o município de ', m_C.nome, '-', e_C.sigla)
              WHEN int_B.tipo_intencao = 'ESTADO' THEN CONCAT(B.nome, ' quer o estado de ', e_C.sigla)
          END as descricao_b,
          CASE 
              WHEN int_C.tipo_intencao = 'UNIDADE' THEN CONCAT(C.nome, ' quer sua unidade ', u_A.nome, ' de ', m_A.nome, '-', e_A.sigla)
              WHEN int_C.tipo_intencao = 'MUNICIPIO' THEN CONCAT(C.nome, ' quer seu município ', m_A.nome, '-', e_A.sigla)
              WHEN int_C.tipo_intencao = 'ESTADO' THEN CONCAT(C.nome, ' quer seu estado ', e_A.sigla)
          END as descricao_c
      FROM policiais A 
      JOIN intencoes int_A ON A.id = int_A.policial_id
      JOIN forcas_policiais f_A ON A.forca_id = f_A.id
      JOIN unidades u_A ON A.unidade_atual_id = u_A.id 
      JOIN municipios m_A ON u_A.municipio_id = m_A.id 
      JOIN estados e_A ON m_A.estado_id = e_A.id
      JOIN policiais B ON B.id != A.id 
      JOIN forcas_policiais f_B ON B.forca_id = f_B.id
      LEFT JOIN postos_graduacoes pg_B ON B.posto_graduacao_id = pg_B.id
      JOIN unidades u_B ON B.unidade_atual_id = u_B.id 
      JOIN municipios m_B ON u_B.municipio_id = m_B.id 
      JOIN estados e_B ON m_B.estado_id = e_B.id
      JOIN intencoes int_B ON B.id = int_B.policial_id
      JOIN policiais C ON C.id != B.id AND C.id != A.id 
      JOIN forcas_policiais f_C ON C.forca_id = f_C.id
      LEFT JOIN postos_graduacoes pg_C ON C.posto_graduacao_id = pg_C.id
      JOIN unidades u_C ON C.unidade_atual_id = u_C.id 
      JOIN municipios m_C ON u_C.municipio_id = m_C.id 
      JOIN estados e_C ON m_C.estado_id = e_C.id
      JOIN intencoes int_C ON C.id = int_C.policial_id
  WHERE A.id = ?
      AND B.status_verificacao = 'VERIFICADO' AND C.status_verificacao = 'VERIFICADO'
      AND B.unidade_atual_id IS NOT NULL AND C.unidade_atual_id IS NOT NULL
      AND ${forcaTriangularCondition}
      AND ((int_A.tipo_intencao = 'UNIDADE' AND int_A.unidade_id = B.unidade_atual_id) OR (int_A.tipo_intencao = 'MUNICIPIO' AND int_A.municipio_id = u_B.municipio_id) OR (int_A.tipo_intencao = 'ESTADO' AND int_A.estado_id = m_B.estado_id))
      AND ((int_B.tipo_intencao = 'UNIDADE' AND int_B.unidade_id = C.unidade_atual_id) OR (int_B.tipo_intencao = 'MUNICIPIO' AND int_B.municipio_id = u_C.municipio_id) OR (int_B.tipo_intencao = 'ESTADO' AND int_B.estado_id = m_C.estado_id))
      AND ((int_C.tipo_intencao = 'UNIDADE' AND int_C.unidade_id = A.unidade_atual_id) OR (int_C.tipo_intencao = 'MUNICIPIO' AND int_C.municipio_id = m_A.id) OR (int_C.tipo_intencao = 'ESTADO' AND int_C.estado_id = e_A.id))
  `;
            const [rows] = await db.execute(query, [profile.id]);
            return rows;
        } catch (error) {
            console.error('ERRO NA QUERY FINDTRIANGULARES:', error);
            throw new ApiError(500, 'Ocorreu um erro no servidor ao buscar por permutas triangulares.');
        }
    }
}

module.exports = new PermutasRepository();
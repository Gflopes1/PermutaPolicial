// /src/modules/policiais/policiais.repository.js

const db = require('../../config/db');

class PoliciaisRepository {
    async findProfileById(id) {
        try {
        // Query otimizada: busca todos os dados em uma única query com JOINs
        // Usa municipio_atual_id diretamente quando disponível, senão usa o da unidade
            // ✅ Query defensiva: seleciona apenas campos que sabemos que existem
        const query = `
            SELECT 
                p.id, p.id_funcional, p.forca_id, p.nome, p.email, p.qso, 
                p.antiguidade, p.unidade_atual_id, p.municipio_atual_id, p.lotacao_interestadual, 
                    p.ocultar_no_mapa, p.status_verificacao, p.embaixador, 
                    p.criado_em, p.posto_graduacao_id,
                f.nome as forca_nome, f.sigla as forca_sigla, f.tipo_permuta as forca_tipo_permuta,
                pg.nome as posto_graduacao_nome,
                u.nome as unidade_atual_nome,
                COALESCE(p.municipio_atual_id, u.municipio_id) as municipio_id,
                COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual_nome,
                COALESCE(m_direto.estado_id, m_unidade.estado_id) as estado_id,
                COALESCE(es_direto.sigla, es_unidade.sigla) as estado_atual_sigla
            FROM policiais p
            LEFT JOIN forcas_policiais f ON p.forca_id = f.id
            LEFT JOIN postos_graduacoes pg ON p.posto_graduacao_id = pg.id
            LEFT JOIN unidades u ON p.unidade_atual_id = u.id
            LEFT JOIN municipios m_direto ON p.municipio_atual_id = m_direto.id
            LEFT JOIN estados es_direto ON m_direto.estado_id = es_direto.id
            LEFT JOIN municipios m_unidade ON u.municipio_id = m_unidade.id
            LEFT JOIN estados es_unidade ON m_unidade.estado_id = es_unidade.id
            WHERE p.id = ?
        `;
            
        const [rows] = await db.execute(query, [id]);

        if (rows.length === 0) {
            return null;
        }

            const profile = rows[0];

            // ✅ Busca campos opcionais em query separada (pode não existir no banco)
            // Isso evita que a query principal falhe se os campos não existirem
            try {
                // Tenta buscar campos opcionais, mas não falha se não existirem
                const [optionalRows] = await db.execute(
                    `SELECT 
                        COALESCE(is_moderator, 0) as is_moderator,
                        COALESCE(is_premium, 0) as is_premium,
                        COALESCE(agente_verificado, 0) as agente_verificado
                     FROM policiais WHERE id = ?`,
                    [id]
                );
                
                if (optionalRows.length > 0) {
                    profile.is_moderator = optionalRows[0].is_moderator || 0;
                    profile.is_premium = optionalRows[0].is_premium || 0;
                    profile.agente_verificado = optionalRows[0].agente_verificado || 0;
                } else {
                    // Valores padrão
                    profile.is_moderator = 0;
                    profile.is_premium = 0;
                    profile.agente_verificado = 0;
                }
            } catch (optionalError) {
                // Se houver erro (ex: campos não existem), usa valores padrão
                // Verifica se é erro de coluna não encontrada
                if (optionalError.code === 'ER_BAD_FIELD_ERROR' || 
                    optionalError.code === 'ER_NO_SUCH_TABLE' ||
                    optionalError.sqlMessage?.includes('Unknown column')) {
                    // Campos não existem, usa valores padrão silenciosamente
                    profile.is_moderator = 0;
                    profile.is_premium = 0;
                    profile.agente_verificado = 0;
                } else {
                    // Outro tipo de erro, loga apenas em desenvolvimento
                    if (process.env.NODE_ENV === 'development') {
                        console.warn('⚠️ Erro ao buscar campos opcionais:', optionalError.message);
                    }
                    // Ainda assim, usa valores padrão para não quebrar
                    profile.is_moderator = 0;
                    profile.is_premium = 0;
                    profile.agente_verificado = 0;
                }
            }

            return profile;
        } catch (error) {
            // Log detalhado do erro para debug
            console.error('💥 Erro em findProfileById:', {
                id,
                error: error.message,
                code: error.code,
                sqlMessage: error.sqlMessage,
                ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
            });
            // Re-lança o erro para ser tratado pelo service
            throw error;
        }
    }

    async update(id, fieldsToUpdate) {
        if (!fieldsToUpdate || Object.keys(fieldsToUpdate).length === 0) {
            return false;
        }
        
        const setClause = Object.keys(fieldsToUpdate).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(fieldsToUpdate), id];
        const query = `UPDATE policiais SET ${setClause} WHERE id = ?`;
        
        if (process.env.NODE_ENV === 'development') {
            console.log('🔧 UPDATE PERFIL:', { query, values });
        }

        const [result] = await db.execute(query, values);
        return result.affectedRows > 0;
    }
}

module.exports = new PoliciaisRepository();
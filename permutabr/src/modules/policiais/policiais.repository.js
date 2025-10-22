// /src/modules/policiais/policiais.repository.js

const db = require('../../config/db');

class PoliciaisRepository {
    async findProfileById(id) {
        // --- ETAPA 1: Buscar dados primários (sem alterações aqui) ---
        const queryPrincipal = `
            SELECT 
                p.id, p.id_funcional, p.forca_id, p.nome, p.email, p.qso, 
                p.antiguidade, p.unidade_atual_id, p.lotacao_interestadual, 
                p.status_verificacao, p.embaixador, p.criado_em, p.posto_graduacao_id,
                f.nome as forca_nome, f.sigla as forca_sigla, f.tipo_permuta as forca_tipo_permuta,
                pg.nome as posto_graduacao_nome
            FROM policiais p
            LEFT JOIN forcas_policiais f ON p.forca_id = f.id
            LEFT JOIN postos_graduacoes pg ON p.posto_graduacao_id = pg.id
            WHERE p.id = ?
        `;
        const [rows] = await db.execute(queryPrincipal, [id]);

        if (rows.length === 0) {
            return null;
        }

        const profile = rows[0];

        // --- ETAPA 2: CORREÇÃO APLICADA AQUI ---
        if (profile.unidade_atual_id) {
            // ADICIONADO: 'm.estado_id' e 'u.municipio_id' na lista de seleção
            const queryLocalizacao = `
                SELECT 
                    u.nome as unidade_atual_nome,
                    u.municipio_id,
                    m.nome as municipio_atual_nome,
                    m.estado_id,
                    es.sigla as estado_atual_sigla
                FROM unidades u
                LEFT JOIN municipios m ON u.municipio_id = m.id
                LEFT JOIN estados es on m.estado_id = es.id
                WHERE u.id = ?
            `;
            const [localizacaoRows] = await db.execute(queryLocalizacao, [profile.unidade_atual_id]);

            if (localizacaoRows.length > 0) {
                Object.assign(profile, localizacaoRows[0]);
            }
        }

        return profile;
    }

    async update(id, fieldsToUpdate) {
        const setClause = Object.keys(fieldsToUpdate).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(fieldsToUpdate), id];
        const query = `UPDATE policiais SET ${setClause} WHERE id = ?`;
        console.log('============================================');
        console.log('🚨 DEBUG: EXECUTANDO UPDATE DE PERFIL');
        console.log('   QUERY GERADA:', query);
        console.log('   VALORES:', values);
        console.log('============================================');

        const [result] = await db.execute(query, values);
        return result.affectedRows > 0;
    }
}

module.exports = new PoliciaisRepository();
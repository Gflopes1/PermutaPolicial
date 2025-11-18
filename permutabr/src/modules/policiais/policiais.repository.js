// /src/modules/policiais/policiais.repository.js

const db = require('../../config/db');

class PoliciaisRepository {
    async findProfileById(id) {
        // Query otimizada: busca todos os dados em uma única query com JOINs
        const query = `
            SELECT 
                p.id, p.id_funcional, p.forca_id, p.nome, p.email, p.qso, 
                p.antiguidade, p.unidade_atual_id, p.lotacao_interestadual, 
                p.ocultar_no_mapa, p.status_verificacao, p.embaixador, p.criado_em, p.posto_graduacao_id,
                f.nome as forca_nome, f.sigla as forca_sigla, f.tipo_permuta as forca_tipo_permuta,
                pg.nome as posto_graduacao_nome,
                u.nome as unidade_atual_nome,
                u.municipio_id,
                m.nome as municipio_atual_nome,
                m.estado_id,
                es.sigla as estado_atual_sigla
            FROM policiais p
            LEFT JOIN forcas_policiais f ON p.forca_id = f.id
            LEFT JOIN postos_graduacoes pg ON p.posto_graduacao_id = pg.id
            LEFT JOIN unidades u ON p.unidade_atual_id = u.id
            LEFT JOIN municipios m ON u.municipio_id = m.id
            LEFT JOIN estados es ON m.estado_id = es.id
            WHERE p.id = ?
        `;
        const [rows] = await db.execute(query, [id]);

        if (rows.length === 0) {
            return null;
        }

        return rows[0];
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
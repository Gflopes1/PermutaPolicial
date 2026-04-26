// /src/modules/policiais/policiais.oauth.repository.js

const db = require('../../config/db');

// Query base reutilizável para campos de usuário OAuth
const USER_FIELDS = `
    id, nome, email, qso, forca_id, unidade_atual_id, 
    municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
    agente_verificado, status_verificacao, is_premium, auth_provider,
    google_id, microsoft_id, id_funcional, lotacao_interestadual,
    ocultar_no_mapa, criado_em
`;

class PoliciaisOAuthRepository {
    /**
     * Busca usuário por Google ID
     */
    async findByGoogleId(googleId) {
        try {
            const [users] = await db.execute(
                `SELECT ${USER_FIELDS} FROM policiais WHERE google_id = ?`,
                [googleId]
            );
            return users[0] || null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Busca usuário por Microsoft ID
     */
    async findByMicrosoftId(microsoftId) {
        try {
            const [users] = await db.execute(
                `SELECT ${USER_FIELDS} FROM policiais WHERE microsoft_id = ?`,
                [microsoftId]
            );
            return users[0] || null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Busca usuário por email
     */
    async findByEmail(email) {
        try {
            const [users] = await db.execute(
                `SELECT ${USER_FIELDS} FROM policiais WHERE email = ?`,
                [email]
            );
            return users[0] || null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Busca usuário por ID (para deserialize)
     */
    async findById(id) {
        try {
            const [users] = await db.execute(
                `SELECT ${USER_FIELDS} FROM policiais WHERE id = ?`,
                [id]
            );
            return users[0] || null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Cria novo usuário OAuth
     */
    async create(userData) {
        try {
            const {
                nome, email, googleId, microsoftId, forcaId,
                authProvider, statusVerificacao, agenteVerificado,
                idFuncional, postoGraduacaoId
            } = userData;

            const fields = ['nome', 'email', 'auth_provider', 'status_verificacao', 'agente_verificado'];
            const values = [nome, email, authProvider, statusVerificacao, agenteVerificado];
            const placeholders = ['?', '?', '?', '?', '?'];

            if (googleId) {
                fields.push('google_id');
                values.push(googleId);
                placeholders.push('?');
            }

            if (microsoftId) {
                fields.push('microsoft_id');
                values.push(microsoftId);
                placeholders.push('?');
            }

            if (forcaId) {
                fields.push('forca_id');
                values.push(forcaId);
                placeholders.push('?');
            }

            if (idFuncional) {
                fields.push('id_funcional');
                values.push(idFuncional);
                placeholders.push('?');
            }

            if (postoGraduacaoId) {
                fields.push('posto_graduacao_id');
                values.push(postoGraduacaoId);
                placeholders.push('?');
            }

            const [result] = await db.execute(
                `INSERT INTO policiais (${fields.join(', ')}) VALUES (${placeholders.join(', ')})`,
                values
            );

            return this.findById(result.insertId);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Atualiza Google ID do usuário
     */
    async updateGoogleId(userId, googleId, agenteVerificado, statusVerificacao) {
        try {
            await db.execute(
                'UPDATE policiais SET google_id = ?, agente_verificado = ?, status_verificacao = ? WHERE id = ?',
                [googleId, agenteVerificado, statusVerificacao, userId]
            );
        } catch (error) {
            throw error;
        }
    }

    /**
     * Atualiza Microsoft ID do usuário
     */
    async updateMicrosoftId(userId, microsoftId, agenteVerificado, statusVerificacao) {
        try {
            await db.execute(
                'UPDATE policiais SET microsoft_id = ?, agente_verificado = ?, status_verificacao = ? WHERE id = ?',
                [microsoftId, agenteVerificado, statusVerificacao, userId]
            );
        } catch (error) {
            throw error;
        }
    }

    /**
     * Busca força por sigla
     */
    async findForcaBySigla(sigla) {
        try {
            const [forcas] = await db.execute(
                'SELECT id FROM forcas_policiais WHERE sigla = ?',
                [sigla]
            );
            return forcas[0] || null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Busca posto por nome
     */
    async findPostoByNome(nome) {
        try {
            const [postos] = await db.execute(
                'SELECT id FROM postos_graduacoes WHERE nome = ?',
                [nome]
            );
            return postos[0] || null;
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new PoliciaisOAuthRepository();


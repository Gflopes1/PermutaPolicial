// /src/modules/auth/auth.service.js

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const emailService = require('../../core/services/email.service');
const ApiError = require('../../core/utils/ApiError');

// Função auxiliar para gerar código de 6 dígitos
const generateSixDigitCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

class AuthService {

    async registrar(dadosDoUsuario) {
        const { nome, id_funcional, forca_id, email, qso, senha } = dadosDoUsuario;

        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();

            const [existing] = await connection.execute('SELECT id, status_verificacao FROM policiais WHERE email = ?', [email]);
            if (existing.length > 0) {
                if (existing[0].status_verificacao !== 'AGUARDANDO_VERIFICACAO_EMAIL') {
                    throw new ApiError(409, 'Este e-mail já está cadastrado e verificado.'); // 409 Conflict
                }
                await connection.execute('DELETE FROM policiais WHERE id = ?', [existing[0].id]);
            }

            const senha_hash = await bcrypt.hash(senha, 10);
            const [result] = await connection.execute(
                `INSERT INTO policiais (nome, id_funcional, forca_id, email, qso, senha_hash, status_verificacao) 
                 VALUES (?, ?, ?, ?, ?, ?, 'AGUARDANDO_VERIFICACAO_EMAIL')`,
                [nome, id_funcional, forca_id, email, qso, senha_hash]
            );

            const newUserId = result.insertId;
            const codigoVerificacao = generateSixDigitCode();
            const expiracao = new Date(Date.now() + 3600000); // 1 hora

            await connection.execute(
                `INSERT INTO codigos_recuperacao (policial_id, codigo, expira_em) VALUES (?, ?, ?)
                 ON DUPLICATE KEY UPDATE codigo = ?, expira_em = ?, usado = FALSE`,
                [newUserId, codigoVerificacao, expiracao, codigoVerificacao, expiracao]
            );

            await emailService.sendVerificationCodeEmail(email, codigoVerificacao);
            await connection.commit();

            return {
                message: `Registro quase concluído! Enviamos um código de 6 dígitos para ${email}. Informe o código para ativar sua conta.`
            };
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            if (connection) connection.release();
        }
    }

    async confirmarEmail({ email, codigo }) {
        const [rows] = await db.execute(
            `SELECT cr.id, cr.policial_id, cr.expira_em, p.status_verificacao
             FROM codigos_recuperacao cr JOIN policiais p ON cr.policial_id = p.id
             WHERE p.email = ? AND cr.codigo = ? AND cr.usado = FALSE`,
            [email, codigo]
        );

        if (rows.length === 0) throw new ApiError(400, 'Código inválido ou já utilizado.');

        const recuperacao = rows[0];
        if (new Date() > new Date(recuperacao.expira_em)) throw new ApiError(400, 'Código expirado. Por favor, registre-se novamente.');
        if (recuperacao.status_verificacao !== 'AGUARDANDO_VERIFICACAO_EMAIL') throw new ApiError(400, 'Este e-mail já foi verificado.');

        await db.execute(`UPDATE policiais SET status_verificacao = 'VERIFICADO' WHERE id = ?`, [recuperacao.policial_id]);
        await db.execute('UPDATE codigos_recuperacao SET usado = TRUE WHERE id = ?', [recuperacao.id]);

        return { message: 'E-mail verificado com sucesso! Você já pode fazer login.' };
    }

    async login({ email, senha }) {
        const [rows] = await db.execute('SELECT * FROM policiais WHERE email = ?', [email]);
        if (rows.length === 0) throw new ApiError(401, 'Credenciais inválidas.');

        const policial = rows[0];

        const statusErrorMap = {
            'AGUARDANDO_VERIFICACAO_EMAIL': 'Sua conta ainda não foi ativada. Verifique o código enviado para o seu email.',
            'REJEITADO': 'Sua conta foi rejeitada por um administrador.',
            'PENDENTE': 'Sua conta está pendente de verificação por um administrador.'
        };

        if (statusErrorMap[policial.status_verificacao]) {
            throw new ApiError(403, statusErrorMap[policial.status_verificacao]); // 403 Forbidden
        }

        const isMatch = await bcrypt.compare(senha, policial.senha_hash);
        if (!isMatch) throw new ApiError(401, 'Credenciais inválidas.');

        const payload = { policial_id: policial.id }; // Usando a chave que o auth.middleware espera
        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN,
        });

        return {
            token,
            utilizador: {
                id: policial.id,
                nome: policial.nome,
                embaixador: policial.embaixador === 1
            }
        };
    }

    async solicitarRecuperacao({ email }) {
        const [rows] = await db.execute('SELECT id FROM policiais WHERE email = ?', [email]);

        if (rows.length > 0) {
            const policial = rows[0];
            const codigoRecuperacao = generateSixDigitCode();
            const expiracao = new Date(Date.now() + 3600000); // 1 hora

            await db.execute(
                `INSERT INTO codigos_recuperacao (policial_id, codigo, expira_em) VALUES (?, ?, ?)
                 ON DUPLICATE KEY UPDATE codigo = ?, expira_em = ?, usado = FALSE`,
                [policial.id, codigoRecuperacao, expiracao, codigoRecuperacao, expiracao]
            );

            await emailService.sendRecoveryCodeEmail(email, codigoRecuperacao);
        }

        return { message: 'Se um e-mail cadastrado for informado, um código de recuperação será enviado.' };
    }

    async validarCodigo({ email, codigo }) {
        const [rows] = await db.execute(
            `SELECT cr.policial_id, cr.expira_em
             FROM codigos_recuperacao cr JOIN policiais p ON cr.policial_id = p.id
             WHERE p.email = ? AND cr.codigo = ? AND cr.usado = FALSE`,
            [email, codigo]
        );

        if (rows.length === 0) throw new ApiError(400, 'Código inválido ou expirado.');

        const recuperacao = rows[0];
        if (new Date() > new Date(recuperacao.expira_em)) throw new ApiError(400, 'Código expirado.');

        const token = jwt.sign(
            { policial_id: recuperacao.policial_id, tipo: 'recuperacao' },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );

        return {
            message: 'Código válido.',
            token_recuperacao: token
        };
    }

    async redefinirSenha({ token_recuperacao, nova_senha }) {
        let decoded;
        try {
            decoded = jwt.verify(token_recuperacao, process.env.JWT_SECRET);
        } catch (error) {
            throw new ApiError(401, 'Token inválido ou expirado.');
        }

        if (decoded.tipo !== 'recuperacao') {
            throw new ApiError(403, 'Token inválido para esta operação.');
        }

        const senha_hash = await bcrypt.hash(nova_senha, 10);
        await db.execute('UPDATE policiais SET senha_hash = ? WHERE id = ?', [senha_hash, decoded.policial_id]);

        await db.execute('UPDATE codigos_recuperacao SET usado = TRUE WHERE policial_id = ?', [decoded.policial_id]);

        return { message: 'Senha redefinida com sucesso.' };
    }


    async handleOAuthLogin(user) {
        if (!user) {
            throw new ApiError(401, 'Falha na autenticação OAuth.');
        }

        // --- CORREÇÃO APLICADA AQUI ---
        // Padronizamos o payload para usar apenas 'policial_id',
        // assim como na função de login padrão.
        const payload = {
            policial_id: user.id
        };
        // --- FIM DA CORREÇÃO ---

        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN,
        });

        return {
            token,
            utilizador: {
                id: user.id,
                nome: user.nome,
                email: user.email,
                embaixador: user.embaixador === 1,
                perfilCompleto: user.forca_id != null && user.unidade_atual_id != null
            }
        };
    }
}

module.exports = new AuthService();
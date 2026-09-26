// /src/modules/auth/auth.service.js

const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const emailService = require('../../core/services/email.service');
const ApiError = require('../../core/utils/ApiError');
const analyticsService = require('../analytics/analytics.service');
const referralService = require('../referral/referral.service');
const { isGovBrEmail } = require('../../core/utils/email.utils');
const { buildJwtPayload } = require('./auth.utils');
const { consumeCode } = require('../../core/services/oauth-code.store');

const generateSixDigitCode = () =>
    crypto.randomInt(100000, 1000000).toString();

// Todos os e-mails exigem confirmação por código (inclui .gov.br)
function determinarStatusVerificacao() {
    return 'AGUARDANDO_VERIFICACAO_EMAIL';
}

class AuthService {

    async registrar(dadosDoUsuario) {
        const { nome, id_funcional, forca_id, email, qso, senha, referral_code: referralCode } = dadosDoUsuario;

        // Validação de campos feita em auth.validation.js (celebrate)
        const statusVerificacao = determinarStatusVerificacao();

        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();

            // Verifica se email já existe
            const [existingEmail] = await connection.execute('SELECT id, status_verificacao FROM policiais WHERE email = ?', [email]);
            if (existingEmail.length > 0) {
                // Se a conta existente está verificada ou não verificada (mas não aguardando verificação de email)
                if (existingEmail[0].status_verificacao === 'VERIFICADO' || existingEmail[0].status_verificacao === 'NAO_VERIFICADO') {
                    throw new ApiError(409, 'Este e-mail já está cadastrado.', null, 'EMAIL_ALREADY_EXISTS');
                }
                // Se está aguardando verificação de email, permite re-registro
                if (existingEmail[0].status_verificacao === 'AGUARDANDO_VERIFICACAO_EMAIL') {
                    const { cleanupPolicialDependencies } = require('../../core/utils/policial-cleanup');
                    await cleanupPolicialDependencies(connection, existingEmail[0].id);
                    await connection.execute('DELETE FROM policiais WHERE id = ?', [existingEmail[0].id]);
                }
            }

            // Verifica se id_funcional já existe na mesma força
            const [existingIdFuncional] = await connection.execute(
                'SELECT id FROM policiais WHERE id_funcional = ? AND forca_id = ?', 
                [id_funcional, forca_id]
            );
            if (existingIdFuncional.length > 0) {
                throw new ApiError(409, 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.', null, 'ID_FUNCIONAL_ALREADY_EXISTS');
            }

            // Verifica se forca_id existe
            const [forcaExists] = await connection.execute('SELECT id FROM forcas_policiais WHERE id = ?', [forca_id]);
            if (forcaExists.length === 0) {
                throw new ApiError(400, 'Força policial inválida.', null, 'INVALID_FORCA');
            }

            let senha_hash;
            try {
                senha_hash = await bcrypt.hash(senha, 10);
            } catch (hashError) {
                console.error('Erro ao fazer hash da senha:', hashError);
                throw new ApiError(500, 'Erro ao processar senha. Tente novamente.', null, 'PASSWORD_HASH_ERROR');
            }
            
            const statusInicial = 'AGUARDANDO_VERIFICACAO_EMAIL';
            const agenteVerificado = 0;
            
            let result;
            try {
                [result] = await connection.execute(
                    `INSERT INTO policiais (nome, id_funcional, forca_id, email, qso, senha_hash, status_verificacao, agente_verificado) 
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                    [nome.trim(), id_funcional.trim(), forca_id, email.trim().toLowerCase(), qso?.trim() || null, senha_hash, statusInicial, agenteVerificado]
                );
            } catch (dbError) {
                // Trata erros específicos do banco de dados
                if (dbError.code === 'ER_DUP_ENTRY') {
                    const sqlMessage = dbError.sqlMessage || '';
                    if (sqlMessage.includes('email') || sqlMessage.includes('EMAIL')) {
                        throw new ApiError(409, 'Este e-mail já está cadastrado.', null, 'EMAIL_ALREADY_EXISTS');
                    } else if (sqlMessage.includes('id_funcional') || sqlMessage.includes('ID_FUNCIONAL')) {
                        throw new ApiError(409, 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.', null, 'ID_FUNCIONAL_ALREADY_EXISTS');
                    } else {
                        throw new ApiError(409, 'Já existe um registro com estes dados. Verifique os dados e tente novamente.', null, 'DUPLICATE_ENTRY');
                    }
                } else if (dbError.code === 'ER_NO_REFERENCED_ROW_2') {
                    throw new ApiError(400, 'Força policial inválida.', null, 'INVALID_FORCA');
                } else if (dbError.code === 'ER_DATA_TOO_LONG') {
                    throw new ApiError(400, 'Um ou mais campos excedem o tamanho máximo permitido.', null, 'DATA_TOO_LONG');
                }
                // Re-lança outros erros de banco
                throw dbError;
            }

            const newUserId = result.insertId;
            
            const codigoVerificacao = generateSixDigitCode();
            const expiracao = new Date(Date.now() + 3600000);

            try {
                await connection.execute(
                    `INSERT INTO codigos_recuperacao (policial_id, codigo, expira_em) VALUES (?, ?, ?)
                     ON DUPLICATE KEY UPDATE codigo = ?, expira_em = ?, usado = FALSE`,
                    [newUserId, codigoVerificacao, expiracao, codigoVerificacao, expiracao]
                );
            } catch (codeError) {
                console.error('Erro ao salvar código de verificação:', codeError);
                throw new ApiError(500, 'Erro ao gerar código de verificação. Tente novamente.', null, 'CODE_GENERATION_ERROR');
            }

            await connection.commit();

            analyticsService.registrarEvento({
                usuario_id: newUserId,
                evento_tipo: 'ACCOUNT_CREATED',
                metadata: { email, forca_id },
                ip_address: null,
                user_agent: null,
            }).catch((err) => console.error('Erro ao registrar evento:', err));

            if (referralCode) {
                const normalizedCode = String(referralCode).trim().toUpperCase();
                referralService.trackSignupStarted({
                    usuario_id: newUserId,
                    referral_code: normalizedCode,
                }).catch(() => {});
                try {
                    const referralResult = await referralService.createReferralOnSignup(
                        newUserId,
                        normalizedCode,
                        { alreadyVerified: false }
                    );
                    if (!referralResult.created) {
                        console.warn('Referral não criado no cadastro:', referralResult.reason, {
                            userId: newUserId,
                            referralCode: normalizedCode,
                        });
                    }
                } catch (err) {
                    console.error('Erro ao criar referral no cadastro:', err);
                }
            }

            let emailSent = true;
            try {
                await emailService.sendVerificationCodeEmail(email, codigoVerificacao);
            } catch (emailError) {
                emailSent = false;
                console.error('Erro ao enviar email de verificação:', emailError.message || emailError);
            }

            const emailNormalizado = email.trim().toLowerCase();

            if (!emailSent) {
                throw new ApiError(
                    500,
                    'Conta criada, mas não foi possível enviar o email de verificação. Use "Esqueci minha senha" na tela de login para receber um novo código, ou entre em contato com o suporte.',
                    null,
                    'EMAIL_SEND_ERROR'
                );
            }

            return {
                message: `Registro quase concluído! Enviamos um código de 6 dígitos para ${emailNormalizado}. Informe o código para ativar sua conta. Verifique também a caixa de spam.`,
                requires_email_confirmation: true,
                agente_verificado: false,
            };
        } catch (error) {
            await connection.rollback();
            // Se já for ApiError, apenas re-lança
            if (error instanceof ApiError) {
                throw error;
            }
            // Trata outros erros inesperados
            console.error('Erro inesperado ao registrar usuário:', error);
            throw new ApiError(500, 'Erro inesperado ao criar conta. Tente novamente mais tarde.', null, 'UNEXPECTED_ERROR');
        } finally {
            if (connection) connection.release();
        }
    }

    async confirmarEmail({ email, codigo, referral_code: referralCode }) {
        const [rows] = await db.execute(
            `SELECT cr.id, cr.policial_id, cr.expira_em, p.status_verificacao
             FROM codigos_recuperacao cr JOIN policiais p ON cr.policial_id = p.id
             WHERE p.email = ? AND cr.codigo = ? AND cr.usado = FALSE`,
            [email, codigo]
        );

        if (rows.length === 0) {
            throw new ApiError(400, 'Código inválido ou já utilizado.', null, 'INVALID_CODE');
        }

        const recuperacao = rows[0];
        if (new Date() > new Date(recuperacao.expira_em)) {
            throw new ApiError(400, 'Código expirado. Por favor, registre-se novamente.', null, 'EXPIRED_CODE');
        }
        if (recuperacao.status_verificacao !== 'AGUARDANDO_VERIFICACAO_EMAIL') {
            throw new ApiError(400, 'Este e-mail já foi verificado.', null, 'ALREADY_VERIFIED');
        }

        const agenteVerificado = isGovBrEmail(email) ? 1 : 0;
        await db.execute(
            `UPDATE policiais SET status_verificacao = 'VERIFICADO', agente_verificado = ? WHERE id = ?`,
            [agenteVerificado, recuperacao.policial_id]
        );
        await db.execute('UPDATE codigos_recuperacao SET usado = TRUE WHERE id = ?', [recuperacao.id]);

        try {
            await referralService.ensureReferralAfterEmailConfirm(
                recuperacao.policial_id,
                referralCode
            );
        } catch (err) {
            console.error('Erro ao processar referral na confirmação de e-mail:', err);
        }

        return { message: 'E-mail verificado com sucesso! Você já pode fazer login.' };
    }

    async login({ email, senha }) {
        // ✅ SEGURANÇA: Seleciona apenas campos necessários, incluindo senha_hash para verificação
        const [rows] = await db.execute(
            `SELECT id, nome, email, qso, forca_id, unidade_atual_id, 
             municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
             agente_verificado, status_verificacao, is_premium, auth_provider,
             google_id, microsoft_id, id_funcional, lotacao_interestadual,
             ocultar_no_mapa, criado_em, senha_hash
             FROM policiais WHERE email = ?`,
            [email]
        );
        if (rows.length === 0) throw new ApiError(401, 'Credenciais inválidas.');

        const policial = rows[0];

        // Corrige contas .gov.br que ficaram presas aguardando confirmação por email
        if (isGovBrEmail(email) && policial.status_verificacao === 'AGUARDANDO_VERIFICACAO_EMAIL') {
            await db.execute(
                `UPDATE policiais SET status_verificacao = 'VERIFICADO', agente_verificado = 1 WHERE id = ?`,
                [policial.id]
            );
            policial.status_verificacao = 'VERIFICADO';
            policial.agente_verificado = 1;
            referralService.markVerified(policial.id).catch(() => {});
        }

        // Verifica status de verificação de email
        if (policial.status_verificacao === 'AGUARDANDO_VERIFICACAO_EMAIL') {
            throw new ApiError(403, 'Sua conta ainda não foi ativada. Verifique o código enviado para o seu email. Confira também a caixa de spam.');
        }

        // Verifica se o email foi verificado (status_verificacao deve ser 'VERIFICADO' para permitir login)
        if (policial.status_verificacao !== 'VERIFICADO') {
            throw new ApiError(403, 'Sua conta não foi verificada. Verifique seu email para ativar sua conta.');
        }

        if (!policial.senha_hash) {
            throw new ApiError(401, 'Esta conta usa login social. Entre com Google ou Microsoft.', null, 'OAUTH_ACCOUNT');
        }

        const isMatch = await bcrypt.compare(senha, policial.senha_hash);
        if (!isMatch) {
            throw new ApiError(401, 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.', null, 'INVALID_CREDENTIALS');
        }

        const payload = buildJwtPayload(policial);
        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN || '7d',
        });

        // Registra evento de login (sem await para não bloquear)
        analyticsService.registrarEvento({
            usuario_id: policial.id,
            evento_tipo: 'LOGIN',
            metadata: { email },
            ip_address: null,
            user_agent: null,
        }).catch(err => console.error('Erro ao registrar evento:', err));

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

        if (rows.length === 0) {
            throw new ApiError(400, 'Código inválido ou expirado.', null, 'INVALID_CODE');
        }

        const recuperacao = rows[0];
        if (new Date() > new Date(recuperacao.expira_em)) {
            throw new ApiError(400, 'Código expirado.', null, 'EXPIRED_CODE');
        }

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


    async loginWithGoogleIdToken({ id_token: idToken, referral_code: referralCode }) {
        const { verifyGoogleIdToken } = require('./google-id-token.utils');
        const oauthService = require('./oauth.service');

        const profile = await verifyGoogleIdToken(idToken);
        const user = await oauthService.processOAuth({
            providerId: profile.sub,
            providerName: 'google',
            email: profile.email,
            nome: profile.name,
            referralCode,
        });

        return this.handleOAuthLogin(user);
    }

    async handleOAuthLogin(user) {
        if (!user) {
            throw new ApiError(401, 'Falha na autenticação OAuth.');
        }

        const payload = buildJwtPayload(user);
        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN || '7d',
        });

        analyticsService.registrarEvento({
            usuario_id: user.id,
            evento_tipo: 'LOGIN',
            metadata: { provider: user.auth_provider || 'oauth', email: user.email },
            ip_address: null,
            user_agent: null,
        }).catch(err => console.error('Erro ao registrar evento:', err));

        return {
            token,
            utilizador: {
                id: user.id,
                nome: user.nome,
                email: user.email,
                embaixador: user.embaixador === 1,
                perfilCompleto: user.forca_id != null && (user.unidade_atual_id != null || user.municipio_atual_id != null)
            }
        };
    }

    async exchangeOAuthCode(code) {
        const payload = consumeCode(code);
        if (!payload?.token) {
            throw new ApiError(400, 'Código OAuth inválido ou expirado.', null, 'OAUTH_CODE_INVALID');
        }
        return {
            token: payload.token,
            completar: payload.completar,
            next: payload.next,
        };
    }
}

module.exports = new AuthService();

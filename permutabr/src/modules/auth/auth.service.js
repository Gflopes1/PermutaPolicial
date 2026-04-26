// /src/modules/auth/auth.service.js

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const emailService = require('../../core/services/email.service');
const ApiError = require('../../core/utils/ApiError');
const analyticsService = require('../analytics/analytics.service');

// Função auxiliar para gerar código de 6 dígitos
const generateSixDigitCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// Função para determinar status de verificação baseado no domínio do email
function determinarStatusVerificacao(email) {
    if (!email || typeof email !== 'string') {
        return 'NAO_VERIFICADO';
    }
    const dominio = email.toLowerCase().split('@')[1];
    // Se o domínio termina em gov.br, a conta é verificada automaticamente
    if (dominio && dominio.endsWith('.gov.br')) {
        return 'VERIFICADO';
    }
    // Caso contrário, a conta fica como não verificada
    return 'NAO_VERIFICADO';
}

class AuthService {

    async registrar(dadosDoUsuario) {
        const { nome, id_funcional, forca_id, email, qso, senha } = dadosDoUsuario;

        // Validações básicas antes de processar
        if (!nome || !nome.trim()) {
            throw new ApiError(400, 'Nome é obrigatório.', null, 'VALIDATION_ERROR');
        }
        if (!id_funcional || !id_funcional.trim()) {
            throw new ApiError(400, 'ID Funcional é obrigatório.', null, 'VALIDATION_ERROR');
        }
        if (!email || !email.trim()) {
            throw new ApiError(400, 'Email é obrigatório.', null, 'VALIDATION_ERROR');
        }
        if (!forca_id) {
            throw new ApiError(400, 'Força policial é obrigatória.', null, 'VALIDATION_ERROR');
        }
        if (!senha || senha.length < 8) {
            throw new ApiError(400, 'Senha deve ter no mínimo 8 caracteres.', null, 'VALIDATION_ERROR');
        }

        // Determina o status de verificação baseado no domínio do email
        const statusVerificacao = determinarStatusVerificacao(email);

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
            
            // Se o status for VERIFICADO (gov.br), cria direto como VERIFICADO
            // Caso contrário, cria como AGUARDANDO_VERIFICACAO_EMAIL para envio de código
            const statusInicial = statusVerificacao === 'VERIFICADO' ? 'VERIFICADO' : 'AGUARDANDO_VERIFICACAO_EMAIL';
            // Agente verificado: TRUE se for gov.br, FALSE caso contrário
            const agenteVerificado = statusVerificacao === 'VERIFICADO' ? 1 : 0;
            
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
            
            // Só envia código de verificação se a conta não for verificada automaticamente
            if (statusInicial === 'AGUARDANDO_VERIFICACAO_EMAIL') {
                const codigoVerificacao = generateSixDigitCode();
                const expiracao = new Date(Date.now() + 3600000); // 1 hora

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

                try {
                    await emailService.sendVerificationCodeEmail(email, codigoVerificacao);
                } catch (emailError) {
                    console.error('Erro ao enviar email de verificação:', emailError);
                    // Se falhar o envio do email, ainda commitamos a conta mas informamos o usuário
                    // A conta fica criada e o usuário pode solicitar um novo código depois
                    await connection.commit();
                    throw new ApiError(500, 'Conta criada, mas não foi possível enviar o email de verificação. Entre em contato com o suporte ou tente fazer login e solicitar um novo código.', null, 'EMAIL_SEND_ERROR');
                }
            }
            
            await connection.commit();

            // Registra evento de criação de conta (sem await para não bloquear)
            analyticsService.registrarEvento({
                usuario_id: newUserId,
                evento_tipo: 'ACCOUNT_CREATED',
                metadata: { email, forca_id },
                ip_address: null,
                user_agent: null,
            }).catch(err => console.error('Erro ao registrar evento:', err));

            // Mensagem diferente dependendo do status
            if (statusInicial === 'VERIFICADO') {
                return {
                    message: `Conta criada com sucesso! Você já pode fazer login.`
                };
            } else {
                return {
                    message: `Registro quase concluído! Enviamos um código de 6 dígitos para ${email}. Informe o código para ativar sua conta.`
                };
            }
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

    async confirmarEmail({ email, codigo }) {
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

        await db.execute(`UPDATE policiais SET status_verificacao = 'VERIFICADO' WHERE id = ?`, [recuperacao.policial_id]);
        await db.execute('UPDATE codigos_recuperacao SET usado = TRUE WHERE id = ?', [recuperacao.id]);

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

        // Verifica status de verificação de email
        if (policial.status_verificacao === 'AGUARDANDO_VERIFICACAO_EMAIL') {
            throw new ApiError(403, 'Sua conta ainda não foi ativada. Verifique o código enviado para o seu email.');
        }

        // Verifica se o email foi verificado (status_verificacao deve ser 'VERIFICADO' para permitir login)
        if (policial.status_verificacao !== 'VERIFICADO') {
            throw new ApiError(403, 'Sua conta não foi verificada. Verifique seu email para ativar sua conta.');
        }

        const isMatch = await bcrypt.compare(senha, policial.senha_hash);
        if (!isMatch) {
            throw new ApiError(401, 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.', null, 'INVALID_CREDENTIALS');
        }

        const payload = { policial_id: policial.id }; // Usando a chave que o auth.middleware espera
        // ✅ NOTA: JWT_EXPIRES_IN pode ser configurado no .env (ex: '7d', '30d', '90d', '1y')
        // Formato aceito: número + unidade (s=segundos, m=minutos, h=horas, d=dias, y=anos)
        // Exemplo: '30d' = 30 dias, '1y' = 1 ano
        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN || '30d', // Padrão: 30 dias se não configurado
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

        // ✅ NOTA: JWT_EXPIRES_IN pode ser configurado no .env (ex: '7d', '30d', '90d', '1y')
        // Formato aceito: número + unidade (s=segundos, m=minutos, h=horas, d=dias, y=anos)
        // Exemplo: '30d' = 30 dias, '1y' = 1 ano
        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN || '30d', // Padrão: 30 dias se não configurado
        });

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
}

module.exports = new AuthService();
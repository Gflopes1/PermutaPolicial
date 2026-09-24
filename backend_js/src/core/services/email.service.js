// /src/core/services/email.service.js

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const { escapeHtml } = require('../utils/html.utils');

/**
 * Nome TLS/SNI para validação do certificado SMTP.
 * Quando MAIL_HOST é mail.dominio.com mas o cert cobre só dominio.com,
 * informe MAIL_TLS_SERVERNAME=dominio.com ou deixe o fallback remover o prefixo mail.
 */
function resolveTlsServername() {
    if (process.env.MAIL_TLS_SERVERNAME) {
        return process.env.MAIL_TLS_SERVERNAME;
    }
    const host = process.env.MAIL_HOST || '';
    if (host.startsWith('mail.')) {
        return host.slice(5);
    }
    return undefined;
}

function isMailConfigured() {
    return !!(process.env.MAIL_HOST && process.env.MAIL_USER && process.env.MAIL_PASS);
}

function buildTlsOptions() {
    const tlsServername = resolveTlsServername();
    const rejectUnauthorized =
        process.env.MAIL_REJECT_UNAUTHORIZED === 'false'
            ? false
            : process.env.NODE_ENV === 'production';

    const tlsOptions = { rejectUnauthorized };
    if (tlsServername) {
        tlsOptions.servername = tlsServername;
    }
    return tlsOptions;
}

function createTransporter() {
    const port = parseInt(process.env.MAIL_PORT || '587', 10);
    const secure = port === 465 || process.env.MAIL_SECURE === 'true';

    return nodemailer.createTransport({
        host: process.env.MAIL_HOST,
        port,
        secure,
        requireTLS: !secure && process.env.MAIL_REQUIRE_TLS !== 'false',
        auth: {
            user: process.env.MAIL_USER,
            pass: process.env.MAIL_PASS,
        },
        tls: buildTlsOptions(),
        connectionTimeout: 15000,
        greetingTimeout: 15000,
        socketTimeout: 20000,
    });
}

let transporter = null;

function getTransporter() {
    if (!isMailConfigured()) {
        throw new Error('SMTP não configurado (MAIL_HOST, MAIL_USER, MAIL_PASS).');
    }
    if (!transporter) {
        transporter = createTransporter();
    }
    return transporter;
}

function formatSmtpError(error) {
    const parts = [error.message];
    if (error.code) parts.push(`code=${error.code}`);
    if (error.responseCode) parts.push(`responseCode=${error.responseCode}`);
    if (error.command) parts.push(`command=${error.command}`);
    if (error.response) parts.push(`response=${String(error.response).slice(0, 200)}`);
    return parts.join(' | ');
}

async function verifySmtpConnection() {
    const tx = getTransporter();
    await tx.verify();
    return { ok: true, host: process.env.MAIL_HOST, port: process.env.MAIL_PORT };
}

const DEFAULT_FRONTEND_URL = () =>
    process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';

/**
 * Wrapper HTML reutilizável para emails transacionais.
 */
function buildEmailLayout({ title, titleColor = '#1a73e8', bodyHtml, ctaLabel, ctaUrl, footerExtra = '' }) {
    const ctaBlock =
        ctaLabel && ctaUrl
            ? `<div style="text-align: center; margin: 30px 0;">
          <a href="${ctaUrl}"
             style="background-color: ${titleColor}; color: white; padding: 12px 30px;
                    text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
            ${ctaLabel}
          </a>
        </div>`
            : '';

    return `<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <h1 style="color: ${titleColor}; border-bottom: 2px solid ${titleColor}; padding-bottom: 10px;">${title}</h1>
      ${bodyHtml}
      ${ctaBlock}
      <p style="font-size: 14px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
        Este é um email automático. Por favor, não responda diretamente a este email.
        ${footerExtra}
      </p>
    </div>`;
}

function buildCodeBlock(code) {
    return `<p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; text-align: center;">${code}</p>`;
}

/**
 * Envia o email com o código de verificação de 6 dígitos.
 * @param {string} to - Email do destinatário.
 * @param {string} code - Código de 6 dígitos.
 */
const sendVerificationCodeEmail = async (to, code) => {
    const fromAddress = process.env.MAIL_FROM || process.env.MAIL_USER;
    const mailOptions = {
        from: `"Permuta Policial" <${fromAddress}>`,
        to: to,
        subject: 'Seu Código de Ativação de Conta',
        html: buildEmailLayout({
            title: 'Bem-vindo ao Permuta Policial!',
            bodyHtml: `
                <p>Use o código abaixo para ativar sua conta na plataforma.</p>
                ${buildCodeBlock(code)}
                <p>Este código é válido por 1 hora. Se você não se registrou, ignore este email.</p>
            `,
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de verificação com código enviado', { to });
    } catch (error) {
        const detail = formatSmtpError(error);
        logger.error('Erro ao enviar email de verificação', {
            to,
            smtpHost: process.env.MAIL_HOST,
            smtpPort: process.env.MAIL_PORT,
            detail,
        });
        const wrapped = new Error(`Falha ao enviar o email de verificação: ${detail}`);
        wrapped.cause = error;
        throw wrapped;
    }
};

/**
 * Envia o email com o código de recuperação de senha.
 * @param {string} to - Email do destinatário.
 * @param {string} code - Código de 6 dígitos.
 */
const sendRecoveryCodeEmail = async (to, code) => {
    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Seu Código de Recuperação de Senha',
        html: buildEmailLayout({
            title: 'Recuperação de Senha',
            bodyHtml: `
                <p>Você solicitou a redefinição da sua senha. Use o código abaixo para continuar.</p>
                ${buildCodeBlock(code)}
                <p>Este código é válido por 1 hora. Se você não solicitou esta alteração, ignore este email.</p>
            `,
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de recuperação enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de recuperação', { detail: formatSmtpError(error) });
        throw new Error(`Falha ao enviar o email de recuperação: ${formatSmtpError(error)}`);
    }
};

/**
 * Envia email de notificação quando alguém solicita contato através do mapa.
 * @param {string} to - Email do destinatário.
 * @param {object} dados - Dados do solicitante e contexto.
 * @param {string} dados.solicitanteNome - Nome do solicitante.
 * @param {string} dados.solicitanteForca - Força do solicitante.
 * @param {string} dados.solicitanteEstado - Estado do solicitante.
 * @param {string} dados.solicitanteCidade - Cidade do solicitante.
 */
const sendContactRequestFromMapEmail = async (to, dados) => {
    const { solicitanteNome, solicitanteForca, solicitanteEstado, solicitanteCidade } = dados;

    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Nova Solicitação de Contato - Mapa',
        html: buildEmailLayout({
            title: 'Nova Solicitação de Contato',
            bodyHtml: `
                <p>Olá,</p>
                <p>Você recebeu uma nova solicitação de contato através do <strong>Mapa de Permutas</strong>.</p>
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h2 style="color: #333; margin-top: 0;">Informações do Solicitante:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${escapeHtml(solicitanteNome)}</p>
                    ${solicitanteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${escapeHtml(solicitanteForca)}</p>` : ''}
                    ${solicitanteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${escapeHtml(solicitanteEstado)}</p>` : ''}
                    ${solicitanteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${escapeHtml(solicitanteCidade)}</p>` : ''}
                </div>
                <p>Para visualizar e responder, acesse a plataforma e verifique suas notificações.</p>
            `,
            ctaLabel: 'Acessar Plataforma',
            ctaUrl: DEFAULT_FRONTEND_URL(),
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de solicitação de contato (mapa) enviado com sucesso');
    } catch (error) {
        logger.error('Erro ao enviar email de solicitação de contato (mapa)', {
            error: error.message,
            stack: error.stack
        });
        // Re-lança o erro para que a camada superior possa logar adequadamente
        throw error;
    }
};

/**
 * Envia email de notificação quando alguém solicita contato através de permuta fechada.
 * @param {string} to - Email do destinatário.
 * @param {object} dados - Dados do solicitante e contexto.
 * @param {string} dados.solicitanteNome - Nome do solicitante.
 * @param {string} dados.solicitanteForca - Força do solicitante.
 * @param {string} dados.solicitanteEstado - Estado do solicitante.
 * @param {string} dados.solicitanteCidade - Cidade do solicitante.
 * @param {string} dados.tipoPermuta - Tipo de permuta (diretas, triangulares, etc).
 */
const sendContactRequestFromPermutaEmail = async (to, dados) => {
    const { solicitanteNome, solicitanteForca, solicitanteEstado, solicitanteCidade, tipoPermuta } = dados;

    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Nova Solicitação de Contato - Permuta Fechada',
        html: buildEmailLayout({
            title: 'Nova Solicitação de Contato',
            titleColor: '#34a853',
            bodyHtml: `
                <p>Olá,</p>
                <p>Você recebeu uma nova solicitação de contato através de uma <strong>Permuta Fechada</strong>.</p>
                <div style="background-color: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #34a853;">
                    <p style="margin: 0; font-weight: bold; color: #2e7d32;">
                        Tipo de Permuta: ${escapeHtml(tipoPermuta || 'Permuta Fechada')}
                    </p>
                </div>
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h2 style="color: #333; margin-top: 0;">Informações do Solicitante:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${escapeHtml(solicitanteNome)}</p>
                    ${solicitanteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${escapeHtml(solicitanteForca)}</p>` : ''}
                    ${solicitanteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${escapeHtml(solicitanteEstado)}</p>` : ''}
                    ${solicitanteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${escapeHtml(solicitanteCidade)}</p>` : ''}
                </div>
                <p>Para visualizar e responder, acesse a plataforma e verifique suas notificações.</p>
            `,
            ctaLabel: 'Acessar Plataforma',
            ctaUrl: DEFAULT_FRONTEND_URL(),
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de solicitação de contato (permuta) enviado com sucesso');
    } catch (error) {
        logger.error('Erro ao enviar email de solicitação de contato (permuta)', {
            error: error.message,
            stack: error.stack
        });
        // Re-lança o erro para que a camada superior possa logar adequadamente
        throw error;
    }
};

/**
 * Envia email de notificação quando uma solicitação de contato é aceita.
 * @param {string} to - Email do solicitante.
 * @param {object} dados - Dados do respondente que aceitou.
 * @param {string} dados.respondenteNome - Nome do respondente.
 * @param {string} dados.respondenteForca - Força do respondente.
 * @param {string} dados.respondenteEstado - Estado do respondente.
 * @param {string} dados.respondenteCidade - Cidade do respondente.
 * @param {string} dados.respondenteUnidade - Unidade do respondente.
 * @param {string} dados.respondentePosto - Posto/Graduação do respondente.
 * @param {string} dados.respondenteTelefone - Telefone do respondente (se não estiver oculto).
 */
const sendContactRequestAcceptedEmail = async (to, dados) => {
    const { 
        respondenteNome, 
        respondenteForca, 
        respondenteEstado, 
        respondenteCidade, 
        respondenteUnidade, 
        respondentePosto, 
        respondenteTelefone 
    } = dados;
    
    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Solicitação de Contato Aceita',
        html: buildEmailLayout({
            title: 'Solicitação de Contato Aceita',
            titleColor: '#34a853',
            bodyHtml: `
                <p>Olá,</p>
                <p>Sua solicitação de contato foi <strong>aceita</strong> por <strong>${escapeHtml(respondenteNome)}</strong>.</p>
                <div style="background-color: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #34a853;">
                    <h2 style="color: #2e7d32; margin-top: 0;">Informações de Contato:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${escapeHtml(respondenteNome)}</p>
                    ${respondenteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${escapeHtml(respondenteForca)}</p>` : ''}
                    ${respondentePosto ? `<p style="margin: 8px 0;"><strong>Posto/Graduação:</strong> ${escapeHtml(respondentePosto)}</p>` : ''}
                    ${respondenteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${escapeHtml(respondenteEstado)}</p>` : ''}
                    ${respondenteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${escapeHtml(respondenteCidade)}</p>` : ''}
                    ${respondenteUnidade ? `<p style="margin: 8px 0;"><strong>Unidade:</strong> ${escapeHtml(respondenteUnidade)}</p>` : ''}
                    ${respondenteTelefone ? `<p style="margin: 8px 0;"><strong>Telefone:</strong> ${escapeHtml(respondenteTelefone)}</p>` : ''}
                </div>
                <p>Entre em contato pela plataforma ou pelos dados acima.</p>
            `,
            ctaLabel: 'Acessar Plataforma',
            ctaUrl: DEFAULT_FRONTEND_URL(),
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de solicitação aceita enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de solicitação aceita', { error: error.message });
        // Não lança erro para não quebrar o fluxo principal
    }
};

/**
 * Envia email de notificação quando uma solicitação de contato é negada.
 * @param {string} to - Email do solicitante.
 * @param {object} dados - Dados do respondente que negou.
 * @param {string} dados.respondenteNome - Nome do respondente.
 */
const sendContactRequestRejectedEmail = async (to, dados) => {
    const { respondenteNome } = dados;
    
    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Solicitação de Contato Negada',
        html: buildEmailLayout({
            title: 'Solicitação de Contato Negada',
            titleColor: '#ea4335',
            bodyHtml: `
                <p>Olá,</p>
                <p>Sua solicitação de contato foi <strong>negada</strong> por <strong>${escapeHtml(respondenteNome || 'o usuário')}</strong>.</p>
                <div style="background-color: #fce8e6; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ea4335;">
                    <p style="margin: 0; color: #c5221f;">
                        Não se preocupe! Você pode continuar buscando outras oportunidades de permuta na plataforma.
                    </p>
                </div>
                <p>Continue explorando a plataforma para encontrar outras combinações de permuta.</p>
            `,
            ctaLabel: 'Continuar Explorando',
            ctaUrl: DEFAULT_FRONTEND_URL(),
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de solicitação negada enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de solicitação negada', { error: error.message });
        // Não lança erro para não quebrar o fluxo principal
    }
};

/**
 * Avisa que as intenções de permuta expiram em breve.
 */
const sendIntencoesExpiringSoonEmail = async (to, dados) => {
    const {
        nome,
        quantidadeIntencoes = 1,
        diasRestantes = 7,
        expiraEm,
    } = dados;

    const dataExpiracao = expiraEm
        ? new Date(expiraEm).toLocaleDateString('pt-BR')
        : 'em breve';

    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to,
        subject: 'Suas intenções de permuta expiram em breve',
        html: buildEmailLayout({
            title: 'Aviso de expiração de intenções',
            titleColor: '#e37400',
            bodyHtml: `
                <p>Olá, <strong>${escapeHtml(nome || 'usuário')}</strong>,</p>
                <p>
                    Você tem <strong>${quantidadeIntencoes}</strong> intenção(ões) de permuta que
                    <strong>expira(m) em ${diasRestantes} dia(s)</strong> (${dataExpiracao}).
                </p>
                <div style="background-color: #fff8e1; padding: 16px; border-radius: 8px; border-left: 4px solid #f9a825; margin: 20px 0;">
                    <p style="margin: 0;">
                        Se você ainda está buscando permuta, renove suas intenções no site para mantê-las ativas no mapa.
                        Caso contrário, elas serão removidas automaticamente.
                    </p>
                </div>
            `,
            ctaLabel: 'Renovar minhas intenções',
            ctaUrl: `${DEFAULT_FRONTEND_URL()}/meus-dados`,
            footerExtra: ' Verifique também a caixa de spam caso não encontre nossas mensagens.',
        }),
    };

    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('Email de aviso de expiração de intenções enviado', { to });
    } catch (error) {
        logger.error('Erro ao enviar email de expiração de intenções', { error: error.message });
        throw new Error('Falha ao enviar email de aviso de expiração.');
    }
};

/**
 * Email de comunicado em massa enviado pelo painel admin.
 * @param {string} to
 * @param {{ subject: string, bodyHtml: string, bodyText?: string }} dados
 */
const sendAdminBroadcastEmail = async (to, dados) => {
    const { subject, bodyHtml, bodyText } = dados;
    const frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';

    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to,
        subject,
        text: bodyText || undefined,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="border-bottom: 2px solid #1a73e8; padding-bottom: 12px; margin-bottom: 20px;">
                    <h1 style="color: #1a73e8; margin: 0; font-size: 22px;">Permuta Policial</h1>
                </div>
                ${bodyHtml}
                <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
                <p style="font-size: 13px; color: #666; line-height: 1.5;">
                    Você recebeu este e-mail por estar cadastrado na plataforma
                    <a href="${frontendUrl}" style="color: #1a73e8;">Permuta Policial</a>.
                    Para alteração de dados ou exclusão de conta, entre em contato pelo WhatsApp:
                    <a href="https://wa.me/51986200626">(51) 98620-0626</a>.
                </p>
            </div>
        `,
    };

    await getTransporter().sendMail(mailOptions);
};

/**
 * Convite para grupo do mapa tático.
 */
const sendMapaTaticoInviteEmail = async (to, groupName, groupId) => {
    if (!isMailConfigured()) {
        logger.debug('[email] SMTP não configurado — convite mapa tático não enviado');
        return;
    }
    const frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to,
        subject: `Convite para o mapa tático: ${groupName}`,
        html: `
            <h1>Convite — Mapa Tático</h1>
            <p>Você foi convidado para participar do grupo <strong>${escapeHtml(groupName)}</strong> no Mapa Tático e Logístico.</p>
            <p>Acesse o app e abra <strong>Mapa Tático → Grupo → Convites</strong> para aceitar.</p>
            <p><a href="${frontendUrl}/mapa-tatico">Abrir Permuta Policial</a></p>
            <p style="font-size:12px;color:#666;">Grupo #${groupId}</p>
        `,
    };
    try {
        await getTransporter().sendMail(mailOptions);
        logger.debug('[email] Convite mapa tático enviado', { to, groupId });
    } catch (error) {
        logger.error('[email] Falha convite mapa tático', { to, error: error.message });
        throw error;
    }
};

// Exporta as funções para serem usadas em outros lugares da aplicação
module.exports = {
    isMailConfigured,
    verifySmtpConnection,
    sendVerificationCodeEmail,
    sendRecoveryCodeEmail,
    sendContactRequestFromMapEmail,
    sendContactRequestFromPermutaEmail,
    sendContactRequestAcceptedEmail,
    sendContactRequestRejectedEmail,
    sendIntencoesExpiringSoonEmail,
    sendAdminBroadcastEmail,
    sendMapaTaticoInviteEmail,
};
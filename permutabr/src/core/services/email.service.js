// /src/core/services/email.service.js

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

// Configura o "transportador" de email uma única vez, lendo as variáveis de ambiente
const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: process.env.MAIL_PORT,
    secure: process.env.MAIL_PORT == 465, // true para porta 465, false para outras
    auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
    },
    tls: {
        rejectUnauthorized: false
    }
});

/**
 * Envia o email com o código de verificação de 6 dígitos.
 * @param {string} to - Email do destinatário.
 * @param {string} code - Código de 6 dígitos.
 */
const sendVerificationCodeEmail = async (to, code) => {
    const mailOptions = {
        from: `"Permuta Policial" <${process.env.MAIL_USER}>`,
        to: to,
        subject: 'Seu Código de Ativação de Conta',
        html: `
            <h1>Bem-vindo ao Permuta Policial!</h1>
            <p>Use o código abaixo para ativar sua conta na plataforma.</p>
            <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; text-align: center;">${code}</p>
            <p>Este código é válido por 1 hora. Se você não se registrou, por favor, ignore este email.</p>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        logger.debug('Email de verificação com código enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de verificação', { error: error.message });
        // Lança o erro para que a camada de serviço que o chamou possa tratá-lo
        throw new Error('Falha ao enviar o email de verificação.');
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
        html: `
            <h1>Recuperação de Senha</h1>
            <p>Você solicitou a redefinição da sua senha. Use o código abaixo para continuar o processo.</p>
            <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; text-align: center;">${code}</p>
            <p>Este código é válido por 1 hora. Se você não solicitou esta alteração, por favor, ignore este email.</p>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        logger.debug('Email de recuperação enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de recuperação', { error: error.message });
        throw new Error('Falha ao enviar o email de recuperação.');
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
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #1a73e8; border-bottom: 2px solid #1a73e8; padding-bottom: 10px;">
                    Nova Solicitação de Contato
                </h1>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Olá,
                </p>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Você recebeu uma nova solicitação de contato através do <strong>Mapa de Permutas</strong>.
                </p>
                
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h2 style="color: #333; margin-top: 0;">Informações do Solicitante:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${solicitanteNome}</p>
                    ${solicitanteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${solicitanteForca}</p>` : ''}
                    ${solicitanteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${solicitanteEstado}</p>` : ''}
                    ${solicitanteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${solicitanteCidade}</p>` : ''}
                </div>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Para visualizar e responder a esta solicitação, acesse a plataforma Permuta Policial e verifique suas notificações.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}" 
                       style="background-color: #1a73e8; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                        Acessar Plataforma
                    </a>
                </div>
                
                <p style="font-size: 14px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
                    Este é um email automático. Por favor, não responda diretamente a este email.
                </p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
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
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #34a853; border-bottom: 2px solid #34a853; padding-bottom: 10px;">
                    Nova Solicitação de Contato
                </h1>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Olá,
                </p>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Você recebeu uma nova solicitação de contato através de uma <strong>Permuta Fechada</strong>.
                </p>
                
                <div style="background-color: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #34a853;">
                    <p style="margin: 0; font-weight: bold; color: #2e7d32;">
                        Tipo de Permuta: ${tipoPermuta || 'Permuta Fechada'}
                    </p>
                </div>
                
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h2 style="color: #333; margin-top: 0;">Informações do Solicitante:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${solicitanteNome}</p>
                    ${solicitanteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${solicitanteForca}</p>` : ''}
                    ${solicitanteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${solicitanteEstado}</p>` : ''}
                    ${solicitanteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${solicitanteCidade}</p>` : ''}
                </div>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Esta solicitação foi feita porque você foi identificado como uma possível combinação de permuta. Para visualizar e responder a esta solicitação, acesse a plataforma Permuta Policial e verifique suas notificações.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}" 
                       style="background-color: #34a853; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                        Acessar Plataforma
                    </a>
                </div>
                
                <p style="font-size: 14px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
                    Este é um email automático. Por favor, não responda diretamente a este email.
                </p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
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
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #34a853; border-bottom: 2px solid #34a853; padding-bottom: 10px;">
                    Solicitação de Contato Aceita
                </h1>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Olá,
                </p>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Sua solicitação de contato foi <strong>aceita</strong> por <strong>${respondenteNome}</strong>.
                </p>
                
                <div style="background-color: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #34a853;">
                    <h2 style="color: #2e7d32; margin-top: 0;">Informações de Contato:</h2>
                    <p style="margin: 8px 0;"><strong>Nome:</strong> ${respondenteNome}</p>
                    ${respondenteForca ? `<p style="margin: 8px 0;"><strong>Força:</strong> ${respondenteForca}</p>` : ''}
                    ${respondentePosto ? `<p style="margin: 8px 0;"><strong>Posto/Graduação:</strong> ${respondentePosto}</p>` : ''}
                    ${respondenteEstado ? `<p style="margin: 8px 0;"><strong>Estado:</strong> ${respondenteEstado}</p>` : ''}
                    ${respondenteCidade ? `<p style="margin: 8px 0;"><strong>Cidade:</strong> ${respondenteCidade}</p>` : ''}
                    ${respondenteUnidade ? `<p style="margin: 8px 0;"><strong>Unidade:</strong> ${respondenteUnidade}</p>` : ''}
                    ${respondenteTelefone ? `<p style="margin: 8px 0;"><strong>Telefone:</strong> ${respondenteTelefone}</p>` : ''}
                </div>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Agora você pode entrar em contato diretamente com esta pessoa através da plataforma ou pelos dados fornecidos acima.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}" 
                       style="background-color: #34a853; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                        Acessar Plataforma
                    </a>
                </div>
                
                <p style="font-size: 14px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
                    Este é um email automático. Por favor, não responda diretamente a este email.
                </p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
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
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #ea4335; border-bottom: 2px solid #ea4335; padding-bottom: 10px;">
                    Solicitação de Contato Negada
                </h1>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Olá,
                </p>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Infelizmente, sua solicitação de contato foi <strong>negada</strong> por <strong>${respondenteNome || 'o usuário'}</strong>.
                </p>
                
                <div style="background-color: #fce8e6; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ea4335;">
                    <p style="margin: 0; color: #c5221f;">
                        Não se preocupe! Você pode continuar buscando outras oportunidades de permuta na plataforma.
                    </p>
                </div>
                
                <p style="font-size: 16px; line-height: 1.6;">
                    Continue explorando a plataforma para encontrar outras combinações de permuta que possam ser de seu interesse.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}" 
                       style="background-color: #1a73e8; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                        Continuar Explorando
                    </a>
                </div>
                
                <p style="font-size: 14px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
                    Este é um email automático. Por favor, não responda diretamente a este email.
                </p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        logger.debug('Email de solicitação negada enviado');
    } catch (error) {
        logger.error('Erro ao enviar email de solicitação negada', { error: error.message });
        // Não lança erro para não quebrar o fluxo principal
    }
};

// Exporta as funções para serem usadas em outros lugares da aplicação
module.exports = {
    sendVerificationCodeEmail,
    sendRecoveryCodeEmail,
    sendContactRequestFromMapEmail,
    sendContactRequestFromPermutaEmail,
    sendContactRequestAcceptedEmail,
    sendContactRequestRejectedEmail,
};
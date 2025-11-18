// /src/core/services/email.service.js

const nodemailer = require('nodemailer');

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
        console.log('Email de verificação com código enviado para:', to);
    } catch (error) {
        console.error('Erro ao enviar email de verificação:', error);
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
        console.log('Email de recuperação enviado para:', to);
    } catch (error) {
        console.error('Erro ao enviar email de recuperação:', error);
        throw new Error('Falha ao enviar o email de recuperação.');
    }
};

// Exporta as funções para serem usadas em outros lugares da aplicação
module.exports = {
    sendVerificationCodeEmail,
    sendRecoveryCodeEmail,
};
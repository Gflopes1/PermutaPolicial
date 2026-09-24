#!/usr/bin/env node
/**
 * Testa conexão SMTP e envio de e-mail de verificação.
 * Uso: node scripts/test-smtp.js [email-destino]
 */
require('dotenv').config();

const emailService = require('../src/core/services/email.service');

async function main() {
    const to = process.argv[2] || process.env.MAIL_USER;

    console.log('--- Diagnóstico SMTP ---');
    console.log('MAIL_HOST:', process.env.MAIL_HOST || '(não definido)');
    console.log('MAIL_PORT:', process.env.MAIL_PORT || '587');
    console.log('MAIL_USER:', process.env.MAIL_USER || '(não definido)');
    console.log('MAIL_TLS_SERVERNAME:', process.env.MAIL_TLS_SERVERNAME || '(auto)');
    console.log('Destino teste:', to);
    console.log('');

    if (!emailService.isMailConfigured()) {
        console.error('ERRO: Configure MAIL_HOST, MAIL_USER e MAIL_PASS no .env');
        process.exit(1);
    }

    try {
        console.log('1) Verificando conexão SMTP...');
        await emailService.verifySmtpConnection();
        console.log('   OK — servidor SMTP respondeu.');
    } catch (err) {
        console.error('   FALHOU — conexão SMTP:', err.message);
        console.error('');
        console.error('Dicas comuns:');
        console.error('- Porta 587: MAIL_PORT=587 (STARTTLS)');
        console.error('- Porta 465: MAIL_PORT=465 (SSL)');
        console.error('- Certificado: MAIL_TLS_SERVERNAME=permutapolicial.com.br');
        console.error('- Cert self-signed: MAIL_REJECT_UNAUTHORIZED=false');
        process.exit(1);
    }

    try {
        console.log('2) Enviando e-mail de teste...');
        await emailService.sendVerificationCodeEmail(to, '123456');
        console.log('   OK — e-mail enviado. Verifique a caixa de entrada/spam.');
    } catch (err) {
        console.error('   FALHOU — envio:', err.message);
        process.exit(1);
    }
}

main();

// Utilitários compartilhados para validação de domínio de email

function getEmailDomain(email) {
    if (!email || typeof email !== 'string') return null;
    const parts = email.trim().toLowerCase().split('@');
    if (parts.length !== 2 || !parts[1]) return null;
    return parts[1];
}

function isGovBrEmail(email) {
    const dominio = getEmailDomain(email);
    if (!dominio) return false;
    return dominio === 'gov.br' || dominio.endsWith('.gov.br');
}

module.exports = {
    getEmailDomain,
    isGovBrEmail,
};

// /src/modules/auth/auth.utils.js

const { resolveSafeFrontendOrigin } = require('../../core/utils/frontend-url.utils');

function detectPlatform(req) {
    const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;

    if (platformParam === 'mobile') return 'mobile';
    if (platformParam === 'pwa') return 'pwa';

    const userAgent = req.headers['user-agent'] || '';
    const isPWA =
        userAgent.includes('wv') ||
        req.headers['x-pwa'] === 'true' ||
        req.headers['sec-fetch-site'] === 'none';

    if (isPWA && !platformParam) return 'pwa';
    return 'web';
}

function getOAuthFrontendUrl(req, defaultUrl) {
    const fallback = defaultUrl || process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    return resolveSafeFrontendOrigin(req.session?.oauthOrigin, fallback);
}

function buildOAuthAuthPath(queryParams) {
    const qs = new URLSearchParams(queryParams).toString();
    return qs ? `/auth?${qs}` : '/auth';
}

function buildOAuthErrorUrl(req, platform, errorCode, message) {
    const encodedMessage = encodeURIComponent(message || errorCode);
    if (platform === 'mobile') {
        return `permutapolicial://auth/callback?error=${errorCode}&message=${encodedMessage}`;
    }
    const frontendUrl = getOAuthFrontendUrl(req);
    return `${frontendUrl}${buildOAuthAuthPath({
        error: errorCode,
        message: message || errorCode,
    })}`;
}

function buildJwtPayload(policial) {
    return {
        v: 1,
        policial_id: policial.id,
        nome: policial.nome,
        email: policial.email,
        qso: policial.qso ?? null,
        forca_id: policial.forca_id ?? null,
        unidade_atual_id: policial.unidade_atual_id ?? null,
        municipio_atual_id: policial.municipio_atual_id ?? null,
        posto_graduacao_id: policial.posto_graduacao_id ?? null,
        embaixador: policial.embaixador ?? 0,
        is_moderator: policial.is_moderator ?? 0,
        agente_verificado: policial.agente_verificado ?? 0,
        status_verificacao: policial.status_verificacao,
        is_premium: policial.is_premium ?? 0,
        auth_provider: policial.auth_provider ?? null,
        google_id: policial.google_id ?? null,
        microsoft_id: policial.microsoft_id ?? null,
        id_funcional: policial.id_funcional ?? null,
        lotacao_interestadual: policial.lotacao_interestadual ?? null,
        ocultar_no_mapa: policial.ocultar_no_mapa ?? 0,
    };
}

function userFromJwtClaims(decoded) {
    if (!decoded?.policial_id) return null;
    if (decoded.v !== 1 && decoded.status_verificacao === undefined) return null;

    return {
        id: decoded.policial_id,
        nome: decoded.nome,
        email: decoded.email,
        qso: decoded.qso,
        forca_id: decoded.forca_id,
        unidade_atual_id: decoded.unidade_atual_id,
        municipio_atual_id: decoded.municipio_atual_id,
        posto_graduacao_id: decoded.posto_graduacao_id,
        embaixador: decoded.embaixador,
        is_moderator: decoded.is_moderator,
        agente_verificado: decoded.agente_verificado,
        status_verificacao: decoded.status_verificacao,
        is_premium: decoded.is_premium,
        auth_provider: decoded.auth_provider,
        google_id: decoded.google_id,
        microsoft_id: decoded.microsoft_id,
        id_funcional: decoded.id_funcional,
        lotacao_interestadual: decoded.lotacao_interestadual,
        ocultar_no_mapa: decoded.ocultar_no_mapa,
    };
}

module.exports = {
    detectPlatform,
    getOAuthFrontendUrl,
    buildOAuthAuthPath,
    buildOAuthErrorUrl,
    buildJwtPayload,
    userFromJwtClaims,
};

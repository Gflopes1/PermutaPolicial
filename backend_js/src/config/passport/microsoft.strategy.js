// /src/config/passport/microsoft.strategy.js

const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;
const axios = require('axios');
const oauthService = require('../../modules/auth/oauth.service');
const logger = require('../../core/utils/logger');

/** Issuers v2/v1 emitidos pela Microsoft para tenants Azure AD. */
const MICROSOFT_ISSUER_V2 =
    /^https:\/\/login\.microsoftonline\.com\/[0-9a-f-]{36}\/v2\.0\/?$/i;
const MICROSOFT_ISSUER_V1 =
    /^https:\/\/sts\.windows\.net\/[0-9a-f-]{36}\/?$/i;

function resolveMicrosoftOidcConfig() {
    const tenantId = (process.env.MICROSOFT_TENANT_ID || '').trim();

    // Tenant único: validateIssuer nativo do passport-azure-ad funciona.
    if (tenantId) {
        return {
            identityMetadata:
                `https://login.microsoftonline.com/${tenantId}/v2.0/.well-known/openid-configuration`,
            validateIssuer: true,
            multiTenant: false,
        };
    }

    // Multi-tenant (/common): passport exige validateIssuer:false; validamos iss manualmente no callback.
    return {
        identityMetadata:
            'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
        validateIssuer: false,
        multiTenant: true,
    };
}

function assertValidMicrosoftIssuer(profile) {
    const iss = profile?._json?.iss || profile?.iss;
    if (!iss || typeof iss !== 'string') {
        throw new Error('Issuer ausente no token Microsoft.');
    }
    if (!MICROSOFT_ISSUER_V2.test(iss) && !MICROSOFT_ISSUER_V1.test(iss)) {
        throw new Error(`Issuer Microsoft não reconhecido: ${iss}`);
    }
    return iss;
}

function createMicrosoftStrategy(options = {}) {
    const microsoftCallbackURL = process.env.MICROSOFT_CALLBACK_URL ||
        `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/microsoft/callback`;

    const oidcConfig = resolveMicrosoftOidcConfig();

    logger.debug('Microsoft OAuth config', {
        callbackUrl: microsoftCallbackURL,
        multiTenant: oidcConfig.multiTenant,
        validateIssuer: oidcConfig.validateIssuer,
    });

    if (oidcConfig.multiTenant) {
        logger.info(
            'Microsoft OAuth multi-tenant (/common): validateIssuer=false no passport (esperado). '
            + 'Issuer validado manualmente no callback.'
        );
    }

    const allowHttp = options.allowHttpForRedirectUrl !== undefined
        ? options.allowHttpForRedirectUrl
        : false;

    return new OIDCStrategy({
        identityMetadata: oidcConfig.identityMetadata,
        clientID: process.env.MICROSOFT_CLIENT_ID,
        clientSecret: process.env.MICROSOFT_CLIENT_SECRET,
        redirectUrl: microsoftCallbackURL,
        responseType: 'code',
        responseMode: 'form_post',
        scope: ['openid', 'profile', 'email', 'User.Read'],
        allowHttpForRedirectUrl: allowHttp,
        validateIssuer: oidcConfig.validateIssuer,
        passReqToCallback: true,
        loggingLevel: process.env.NODE_ENV === 'production' ? 'warn' : 'info',
        loggingNoPII: process.env.NODE_ENV === 'production',
        customParams: {
            prompt: 'select_account',
        },
    },
    async (req, iss, sub, profile, accessToken, refreshToken, done) => {
        try {
            if (oidcConfig.multiTenant) {
                assertValidMicrosoftIssuer(profile);
            }
        } catch (issuerError) {
            logger.error('Microsoft OAuth: issuer inválido', { error: issuerError.message });
            return done(issuerError, false);
        }

        logger.info('Microsoft OAuth: id_token recebido, iniciando pós-processamento', {
            oid: profile?.oid || profile?.sub,
            hasAccessToken: !!accessToken,
        });

        let graphProfile = null;
        if (accessToken) {
            graphProfile = await fetchGraphProfile(accessToken);
        }

        const identity = buildMicrosoftIdentity(profile, graphProfile);

        logger.info('Microsoft OAuth: identidade resolvida', {
            source: graphProfile ? 'graph_api' : 'id_token_fallback',
            email: identity.email ? `${identity.email.slice(0, 3)}***` : null,
            microsoftId: identity.microsoftId,
        });

        if (!identity.email) {
            logger.error('Microsoft OAuth: e-mail ausente no Graph e no id_token');
            return done(new Error('O e-mail não foi fornecido pela Microsoft.'), false);
        }
        if (!identity.microsoftId) {
            logger.error('Microsoft OAuth: ID ausente no token');
            return done(new Error('O ID de usuário não foi fornecido pela Microsoft.'), false);
        }

        try {
            const processOAuthPromise = oauthService.processOAuth({
                providerId: identity.microsoftId,
                providerName: 'microsoft',
                email: identity.email,
                nome: identity.nome,
                idFuncional: identity.idFuncional,
                postoGraduacaoNome: identity.postoGraduacaoNome,
                referralCode: req.session?.oauthReferralCode || null,
            });

            const timeoutPromise = new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Timeout ao processar autenticação OAuth')), 15000);
            });

            const user = await Promise.race([processOAuthPromise, timeoutPromise]);

            if (!user) {
                logger.error('Microsoft OAuth: processOAuth não retornou usuário', {
                    microsoftId: identity.microsoftId,
                });
                return done(new Error('Falha ao processar autenticação: usuário não foi criado/encontrado'), false);
            }

            logger.info('Microsoft OAuth: login concluído com sucesso', {
                userId: user.id,
                email: user.email,
            });
            return done(null, user);
        } catch (error) {
            logger.error('Microsoft OAuth: erro ao persistir usuário', {
                error: error.message,
                stack: error.stack,
                microsoftId: identity.microsoftId,
            });
            return done(new Error(`Erro ao processar autenticação Microsoft: ${error.message}`), false);
        }
    });
}

async function fetchGraphProfile(accessToken) {
    const maxRetries = 3;
    let retryCount = 0;

    while (retryCount < maxRetries) {
        try {
            const graphResponse = await axios.get(
                'https://graph.microsoft.com/v1.0/me?$select=displayName,userPrincipalName,businessPhones,officeLocation,city,mail,jobTitle',
                {
                    headers: { Authorization: `Bearer ${accessToken}` },
                    timeout: 10000,
                }
            );
            logger.debug('Microsoft Graph API: perfil obtido', { attempt: retryCount + 1 });
            return graphResponse.data;
        } catch (graphError) {
            retryCount++;
            const status = graphError.response?.status;
            const errorMessage = graphError.response?.data || graphError.message;
            const isRetryable = graphError.code === 'ECONNABORTED'
                || graphError.code === 'ETIMEDOUT'
                || status === 429
                || (status >= 500 && status < 600);

            logger.warn('Microsoft Graph API: falha ao buscar perfil', {
                attempt: retryCount,
                maxRetries,
                status,
                code: graphError.code,
                error: errorMessage,
            });

            if (retryCount >= maxRetries || !isRetryable) {
                logger.warn('Microsoft Graph API: usando fallback do id_token');
                return null;
            }

            await new Promise((resolve) => setTimeout(resolve, 1000 * retryCount));
        }
    }

    return null;
}

function buildMicrosoftIdentity(profile, graphProfile) {
    const claims = profile?._json || profile || {};

    const microsoftId = profile?.oid || profile?.sub || claims.oid || claims.sub || null;

    const emailFromGraph = graphProfile?.mail || graphProfile?.userPrincipalName || null;
    const emailFromToken = claims.email
        || claims.preferred_username
        || claims.upn
        || profile?.upn
        || profile?.email
        || null;

    const nomeFromGraph = graphProfile?.displayName || null;
    const nomeFromToken = claims.name
        || profile?.displayName
        || [claims.given_name, claims.family_name].filter(Boolean).join(' ')
        || null;

    return {
        microsoftId,
        email: (emailFromGraph || emailFromToken || '').trim().toLowerCase() || null,
        nome: (nomeFromGraph || nomeFromToken || 'Usuário Microsoft').trim(),
        idFuncional: graphProfile?.officeLocation || claims.office_location || null,
        postoGraduacaoNome: graphProfile?.jobTitle || claims.jobTitle || null,
    };
}

module.exports = createMicrosoftStrategy;

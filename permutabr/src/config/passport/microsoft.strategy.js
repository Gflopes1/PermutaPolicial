// /src/config/passport/microsoft.strategy.js

const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;
const axios = require('axios');
const oauthService = require('../../modules/auth/oauth.service');
const logger = require('../../core/utils/logger');

function createMicrosoftStrategy(options = {}) {
    const microsoftCallbackURL = process.env.MICROSOFT_CALLBACK_URL || 
                                 `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/microsoft/callback`;
    
    logger.debug(`URL de Callback da Microsoft: ${microsoftCallbackURL}`);
    
    if (process.env.NODE_ENV !== 'production') {
        logger.warn('═══════════════════════════════════════════════════════════════');
        logger.warn('⚠️  CONFIGURAÇÃO MICROSOFT OAUTH - AMBIENTE DEV');
        logger.warn('═══════════════════════════════════════════════════════════════');
        logger.warn(`📍 URL de Callback configurada: ${microsoftCallbackURL}`);
        logger.warn('');
        logger.warn('✅ AÇÃO NECESSÁRIA: Esta URL DEVE estar registrada no Azure AD');
        logger.warn('');
        logger.warn('📋 Passos para configurar:');
        logger.warn('   1. Acesse: https://portal.azure.com');
        logger.warn('   2. Vá em: Azure Active Directory > App registrations');
        logger.warn('   3. Selecione seu App (ou crie um novo)');
        logger.warn('   4. Vá em: Authentication');
        logger.warn('   5. Em "Redirect URIs", adicione:');
        logger.warn(`      ${microsoftCallbackURL}`);
        logger.warn('');
        logger.warn('⚠️  IMPORTANTE:');
        logger.warn('   - A URL deve ser EXATAMENTE igual (incluindo http/https)');
        logger.warn('   - Se usar HTTP em dev, marque "Allow public client flows"');
        logger.warn('   - Após adicionar, salve e aguarde alguns segundos');
        logger.warn('═══════════════════════════════════════════════════════════════');
    }

    // Permite HTTP em desenvolvimento se especificado nas opções
    const allowHttp = options.allowHttpForRedirectUrl !== undefined 
        ? options.allowHttpForRedirectUrl 
        : false;

    return new OIDCStrategy({
        identityMetadata: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
        clientID: process.env.MICROSOFT_CLIENT_ID,
        clientSecret: process.env.MICROSOFT_CLIENT_SECRET,
        redirectUrl: microsoftCallbackURL,
        responseType: 'code',
        responseMode: 'form_post',
        scope: ['openid', 'profile', 'email', 'User.Read'],
        allowHttpForRedirectUrl: allowHttp,
        validateIssuer: false,
        passReqToCallback: false,
        loggingLevel: 'info',
        customParams: {
            prompt: 'select_account' // ✅ Força a tela de seleção de conta
        }
    },
    async (iss, sub, profile, accessToken, refreshToken, done) => {
        logger.debug('Estratégia Microsoft OAuth executada - AccessToken recebido para Graph API');

        let graphProfile;
        const maxRetries = 3;
        let retryCount = 0;
        
        // ✅ CORREÇÃO: Retry logic para Graph API (resolve problemas intermitentes)
        while (retryCount < maxRetries) {
            try {
                const graphResponse = await axios.get(
                    'https://graph.microsoft.com/v1.0/me?$select=displayName,userPrincipalName,businessPhones,officeLocation,city,mail,jobTitle',
                    {
                        headers: { 
                            'Authorization': `Bearer ${accessToken}` 
                        },
                        timeout: 10000 // ✅ Timeout de 10 segundos para evitar espera infinita
                    }
                );
                graphProfile = graphResponse.data;
                logger.debug('Perfil do Graph API obtido', { 
                    graphProfile,
                    retryAttempt: retryCount + 1
                });
                break; // Sucesso, sai do loop
            } catch (graphError) {
                retryCount++;
                const errorMessage = graphError.response ? graphError.response.data : graphError.message;
                logger.warn(`Tentativa ${retryCount}/${maxRetries} falhou ao buscar perfil do Graph API`, {
                    error: errorMessage,
                    code: graphError.code,
                    isTimeout: graphError.code === 'ECONNABORTED'
                });
                
                // Se não for timeout ou se já tentou todas as vezes, retorna erro
                if (retryCount >= maxRetries || (graphError.code !== 'ECONNABORTED' && graphError.code !== 'ETIMEDOUT')) {
                    logger.error('ERRO ao buscar perfil do Graph API após todas as tentativas', {
                        error: errorMessage,
                        attempts: retryCount
                    });
                    return done(new Error(`Erro ao buscar perfil do Microsoft: ${errorMessage}`), false);
                }
                
                // Aguarda antes de tentar novamente (backoff exponencial)
                await new Promise(resolve => setTimeout(resolve, 1000 * retryCount));
            }
        }

        try {
            const microsoftId = profile.oid || profile.sub;
            const email = graphProfile.mail || graphProfile.userPrincipalName;
            const nome = graphProfile.displayName || 'Usuário Microsoft';
            const idFuncional = graphProfile.officeLocation || null;
            const postoGraduacaoNome = graphProfile.jobTitle || null;

            logger.debug('Dados extraídos do Graph API', {
                microsoftId,
                email,
                nome,
                idFuncional,
                postoGraduacaoNome
            });

            if (!email) {
                logger.error('Email não fornecido pelo Graph API');
                return done(new Error('O email não foi fornecido pela Microsoft.'), false);
            }
            if (!microsoftId) {
                logger.error('ID não fornecido pelo token Microsoft');
                return done(new Error('O ID de usuário não foi fornecido pela Microsoft.'), false);
            }

            // ✅ CORREÇÃO: Timeout para processOAuth (evita espera infinita)
            const processOAuthPromise = oauthService.processOAuth({
                providerId: microsoftId,
                providerName: 'microsoft',
                email,
                nome,
                idFuncional,
                postoGraduacaoNome
            });

            // Timeout de 15 segundos para processamento OAuth
            const timeoutPromise = new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Timeout ao processar autenticação OAuth')), 15000);
            });

            const user = await Promise.race([processOAuthPromise, timeoutPromise]);

            if (!user) {
                logger.error('Usuário não retornado pelo processOAuth', {
                    microsoftId,
                    email
                });
                return done(new Error('Falha ao processar autenticação: usuário não foi criado/encontrado'), false);
            }

            logger.debug('Usuário Microsoft criado/encontrado com sucesso', {
                userId: user.id,
                email: user.email
            });
            return done(null, user);
        } catch (error) {
            logger.error('ERRO na estratégia Microsoft (lógica de BD)', {
                error: error.message,
                stack: error.stack,
                microsoftId: profile?.oid || profile?.sub,
                email: graphProfile?.mail || graphProfile?.userPrincipalName
            });
            // ✅ CORREÇÃO: Retorna erro mais descritivo
            return done(new Error(`Erro ao processar autenticação Microsoft: ${error.message}`), false);
        }
    });
}

module.exports = createMicrosoftStrategy;


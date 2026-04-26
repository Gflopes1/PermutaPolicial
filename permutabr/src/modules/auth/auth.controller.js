// /src/modules/auth/auth.controller.js

const authService = require('./auth.service');
const logger = require('../../core/utils/logger');

// ✅ FUNÇÃO AUXILIAR: Detecta a plataforma (web/pwa/mobile)
function detectPlatform(req) {
    // Prioridade: query param > body > session > headers
    const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
    
    if (platformParam === 'mobile') {
        return 'mobile';
    }
    if (platformParam === 'pwa') {
        return 'pwa';
    }
    
    // Detecta PWA via User-Agent ou headers específicos
    const userAgent = req.headers['user-agent'] || '';
    const isPWA = userAgent.includes('wv') || // Android WebView
                  req.headers['x-pwa'] === 'true' ||
                  req.headers['sec-fetch-site'] === 'none'; // PWA geralmente tem este header
    
    if (isPWA && !platformParam) {
        return 'pwa';
    }
    
    // Padrão: web
    return 'web';
}

// Usamos uma função auxiliar para evitar repetir o try/catch
const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    next(error); // Passa o erro para o middleware de erro central
  }
};

const googleCallbackHandler = async (req, res, next) => {
    try {
        logger.debug('GOOGLE CALLBACK HANDLER', {
            url: req.url,
            query: req.query,
            origin: req.headers.origin || 'não fornecido',
            sessionId: req.sessionID || 'não presente',
            oauthOrigin: req.session?.oauthOrigin || 'não salvo',
            hasUser: !!req.user
        });

        if (req.user) {
            logger.debug('Dados do usuário no callback', {
                id: req.user.id,
                email: req.user.email,
                nome: req.user.nome,
                forcaId: req.user.forca_id,
                unidadeId: req.user.unidade_atual_id
            });
        }

        if (!req.user) {
            logger.warn('Google Callback: Usuário não autenticado');
            const platform = detectPlatform(req);
            if (platform === 'mobile') {
                return res.redirect(`permutapolicial://auth/callback?error=oauth_failed`);
            }
            // ✅ CORREÇÃO: Usa origem dinâmica também para erros (web e PWA)
            let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
            if (req.session?.oauthOrigin) {
                frontendUrl = req.session.oauthOrigin;
            } else if (req.headers.origin) {
                // ✅ CORREÇÃO: Ignora origins de provedores OAuth
                const oauthDomains = [
                    'login.microsoftonline.com',
                    'accounts.google.com',
                    'oauth.google.com',
                    'login.live.com'
                ];
                const originHost = new URL(req.headers.origin).hostname;
                const isOAuthDomain = oauthDomains.some(domain => originHost.includes(domain));
                if (!isOAuthDomain) {
                    frontendUrl = req.headers.origin;
                }
            }
            return res.redirect(`${frontendUrl}?error=oauth_failed`);
        }

        logger.debug('Gerando token para OAuth login');
        const result = await authService.handleOAuthLogin(req.user);
        logger.debug('Token gerado com sucesso');

        // Verifica se o perfil está completo (unidade OU município)
        const perfilCompleto = req.user.forca_id != null && 
                              (req.user.unidade_atual_id != null || req.user.municipio_atual_id != null);
        logger.debug('Verificação de perfil completo', {
            perfilCompleto,
            forcaId: req.user.forca_id,
            unidadeId: req.user.unidade_atual_id,
            municipioId: req.user.municipio_atual_id
        });

        // ✅ CORREÇÃO: Detecta plataforma corretamente (web/pwa/mobile)
        const platform = detectPlatform(req);
        logger.debug('Plataforma detectada', {
            platform,
            description: platform === 'mobile' ? 'Mobile (APK)' : platform === 'pwa' ? 'PWA (Instalado)' : 'Web (Navegador)'
        });
        
        // ✅ CORREÇÃO: Detecta a origem do frontend dinamicamente
        // Prioridade: 1) Sessão (salva no início do OAuth), 2) Header Origin (se não for OAuth), 3) FRONTEND_URL env, 4) Fallback
        let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        
        if (platform !== 'mobile') {
            // Para web e PWA, tenta usar a origem salva na sessão ou o header Origin
            if (req.session?.oauthOrigin) {
                frontendUrl = req.session.oauthOrigin;
                logger.debug('Usando origem da sessão', { frontendUrl });
            } else if (req.headers.origin) {
                // ✅ CORREÇÃO CRÍTICA: Ignora origins de provedores OAuth (Microsoft, Google, etc.)
                const oauthDomains = [
                    'login.microsoftonline.com',
                    'accounts.google.com',
                    'oauth.google.com',
                    'login.live.com'
                ];
                const originHost = new URL(req.headers.origin).hostname;
                const isOAuthDomain = oauthDomains.some(domain => originHost.includes(domain));
                
                if (!isOAuthDomain) {
                    frontendUrl = req.headers.origin;
                    logger.debug('Usando origem do header', { frontendUrl });
                } else {
                    logger.warn('Origin do header é um domínio OAuth, ignorando', { 
                        origin: req.headers.origin,
                        usingDefault: frontendUrl 
                    });
                }
            } else {
                logger.debug('Usando FRONTEND_URL padrão', { frontendUrl });
            }
        }
        
        // ✅ ENCODE do token para evitar problemas com caracteres especiais na URL
        const encodedToken = encodeURIComponent(result.token);
        
        // ✅ CORREÇÃO: Redireciona para a plataforma correta
        let redirectUrl;
        if (platform === 'mobile') {
            // Mobile (APK): usa deep link customizado para abrir o app
            const appScheme = 'permutapolicial';
            redirectUrl = perfilCompleto
                ? `${appScheme}://auth/callback?token=${encodedToken}`
                : `${appScheme}://auth/callback?token=${encodedToken}&completar=true`;
        } else {
            // Web e PWA: redireciona para a mesma origem (não tenta abrir APK)
            // PWA instalado deve continuar no PWA, não tentar abrir o APK
            redirectUrl = perfilCompleto
                ? `${frontendUrl}/auth/callback?token=${encodedToken}`
                : `${frontendUrl}/auth/callback?token=${encodedToken}&completar=true`;
        }

        logger.debug('Redirecionando após OAuth', {
            redirectUrl,
            tokenPreview: result.token.substring(0, 20) + '...',
            platform
        });

        // ✅ CRÍTICO: Garante que a resposta é enviada corretamente
        // Com form_post, o Microsoft espera uma resposta adequada
        // Usa 302 (temporary redirect) para garantir que o navegador segue o redirect
        try {
            res.redirect(302, redirectUrl);
        } catch (redirectError) {
            logger.error('ERRO ao redirecionar após OAuth', { error: redirectError.message });
            // Se o redirect falhar, tenta enviar uma resposta HTML com redirect automático
            res.status(200).send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <meta http-equiv="refresh" content="0;url=${redirectUrl}">
                    <script>window.location.href = "${redirectUrl}";</script>
                </head>
                <body>
                    <p>Redirecionando...</p>
                    <a href="${redirectUrl}">Clique aqui se não for redirecionado automaticamente</a>
                </body>
                </html>
            `);
        }

    } catch (error) {
        logger.error('ERRO NO GOOGLE CALLBACK HANDLER', {
            message: error.message,
            stack: error.stack
        });

        // ✅ CORREÇÃO: Detecta plataforma para redirecionar corretamente em caso de erro
        const platform = detectPlatform(req);
        if (platform === 'mobile') {
            return res.redirect(`permutapolicial://auth/callback?error=oauth_failed&message=${encodeURIComponent(error.message)}`);
        }
        // Para web e PWA: usa origem dinâmica
        let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        if (req.session?.oauthOrigin) {
            frontendUrl = req.session.oauthOrigin;
        } else if (req.headers.origin) {
            // ✅ CORREÇÃO: Ignora origins de provedores OAuth
            const oauthDomains = [
                'login.microsoftonline.com',
                'accounts.google.com',
                'oauth.google.com',
                'login.live.com'
            ];
            const originHost = new URL(req.headers.origin).hostname;
            const isOAuthDomain = oauthDomains.some(domain => originHost.includes(domain));
            if (!isOAuthDomain) {
                frontendUrl = req.headers.origin;
            }
        }
        res.redirect(`${frontendUrl}?error=oauth_failed&message=${encodeURIComponent(error.message)}`);
    }
};


module.exports = {
  registrar: handleRequest((req) => authService.registrar(req.body), 201),
  
  confirmarEmail: handleRequest((req) => authService.confirmarEmail(req.body), 200),

  login: handleRequest((req) => authService.login(req.body), 200),
  
  solicitarRecuperacao: handleRequest((req) => authService.solicitarRecuperacao(req.body), 200),

  validarCodigo: handleRequest((req) => authService.validarCodigo(req.body), 200),

    redefinirSenha: handleRequest((req) => authService.redefinirSenha(req.body), 200),

    googleCallback: googleCallbackHandler,


};


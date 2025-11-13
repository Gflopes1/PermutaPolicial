// /src/modules/auth/auth.controller.js

const authService = require('./auth.service');

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
        console.log('═══════════════════════════════════════');
        console.log('🔍 GOOGLE CALLBACK HANDLER');
        console.log('═══════════════════════════════════════');
        console.log('📍 URL:', req.url);
        console.log('📍 Query:', req.query);
        console.log('📍 User:', req.user ? '✅ Presente' : '❌ Ausente');

        if (req.user) {
            console.log('👤 Dados do usuário:');
            console.log('   - ID:', req.user.id);
            console.log('   - Email:', req.user.email);
            console.log('   - Nome:', req.user.nome);
            console.log('   - Força ID:', req.user.forca_id);
            console.log('   - Unidade ID:', req.user.unidade_atual_id);
        }

        if (!req.user) {
            console.log('❌ Google Callback: Usuário não autenticado');
            const frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
            return res.redirect(`${frontendUrl}?error=oauth_failed`);
        }

        console.log('🔐 Gerando token...');
        const result = await authService.handleOAuthLogin(req.user);
        console.log('✅ Token gerado com sucesso');

        // Verifica se o perfil está completo
        const perfilCompleto = req.user.forca_id != null && req.user.unidade_atual_id != null;
        console.log('📋 Perfil completo:', perfilCompleto);

        const frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        const redirectUrl = perfilCompleto
            ? `${frontendUrl}/auth/callback?token=${result.token}`
            : `${frontendUrl}/auth/callback?token=${result.token}&completar=true`;

        console.log('🔗 Redirecionando para:', redirectUrl);
        console.log('═══════════════════════════════════════');

        res.redirect(redirectUrl);

    } catch (error) {
        console.error('💥 ERRO NO GOOGLE CALLBACK HANDLER:');
        console.error('   Mensagem:', error.message);
        console.error('   Stack:', error.stack);
        console.log('═══════════════════════════════════════');

        const frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
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


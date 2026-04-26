const paymentsRepository = require('../../modules/questions/payments.repository');
const ApiError = require('../utils/ApiError');

module.exports = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const subscription = await paymentsRepository.getUserActiveSubscription(userId);

    // Verifica se tem assinatura ativa OU se o campo is_premium está marcado no banco
    const hasSubscription = !!subscription;
    const hasDirectPremium = req.user.is_premium === 1 || req.user.is_premium === true;
    
    req.user.is_premium = hasSubscription || hasDirectPremium;
    req.user.subscription = subscription;

    next();
  } catch (error) {
    // Em caso de erro, verifica o campo direto do banco como fallback
    req.user.is_premium = req.user.is_premium === 1 || req.user.is_premium === true;
    req.user.subscription = null;
    next();
  }
};

module.exports.requirePremium = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const subscription = await paymentsRepository.getUserActiveSubscription(userId);

    // Verifica se tem assinatura ativa OU se o campo is_premium está marcado no banco
    const hasSubscription = !!subscription;
    const hasDirectPremium = req.user.is_premium === 1 || req.user.is_premium === true;
    const isPremium = hasSubscription || hasDirectPremium;

    if (!isPremium) {
      return next(new ApiError(403, 'Recurso disponível apenas para usuários premium'));
    }

    req.user.is_premium = true;
    req.user.subscription = subscription;

    next();
  } catch (error) {
    // Em caso de erro, verifica o campo direto do banco como fallback
    const hasDirectPremium = req.user.is_premium === 1 || req.user.is_premium === true;
    if (!hasDirectPremium) {
      return next(new ApiError(403, 'Recurso disponível apenas para usuários premium'));
    }
    req.user.is_premium = true;
    req.user.subscription = null;
    next();
  }
};



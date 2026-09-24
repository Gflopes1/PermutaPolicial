const ApiError = require('../utils/ApiError');

function isPremiumUser(user) {
    return user?.is_premium === 1 || user?.is_premium === true;
}

module.exports = async (req, res, next) => {
    req.user.is_premium = isPremiumUser(req.user);
    req.user.subscription = null;
    next();
};

module.exports.requirePremium = async (req, res, next) => {
    if (!isPremiumUser(req.user)) {
        return next(new ApiError(403, 'Recurso disponível apenas para usuários premium'));
    }
    req.user.is_premium = true;
    req.user.subscription = null;
    next();
};

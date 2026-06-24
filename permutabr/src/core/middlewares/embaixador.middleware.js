// /src/core/middlewares/embaixador.middleware.js
// Apenas embaixadores (admin principal) — moderadores não passam

const ApiError = require('../utils/ApiError');

module.exports = (req, res, next) => {
  const isEmbaixador = req.user && (req.user.embaixador === 1 || req.user.isEmbaixador === true);

  if (!req.user || !isEmbaixador) {
    return next(new ApiError(403, 'Acesso negado. Recurso restrito ao administrador principal.'));
  }

  next();
};

const db = require('../../config/db'); // Ajusta o caminho se necessário
const ApiError = require('../utils/ApiError'); // Ajusta o caminho se necessário

const soldadoAuth = async (req, res, next) => {
  try {
    // Pré-requisito 1: Estar logado (o 'auth.middleware' normal já deve ter feito isto)
    if (!req.user) {
      throw new ApiError(401, 'Acesso não autorizado. Faça o login.');
    }

    const policialId = req.user.id;
    const authProvider = req.user.auth_provider;

    // Pré-requisito 2: Estar logado via Microsoft
    if (authProvider !== 'microsoft') {
      throw new ApiError(403, 'Acesso restrito. Esta funcionalidade requer autenticação via Microsoft.');
    }

    // Pré-requisito 3: ID estar na tabela novos_soldados
    const [soldados] = await db.execute(
      'SELECT * FROM novos_soldados WHERE policial_id = ?',
      [policialId]
    );

    if (soldados.length === 0) {
      throw new ApiError(403, 'Acesso restrito. O seu utilizador não está na lista de novos soldados autorizados.');
    }

    // Se passou tudo, anexa os dados do soldado ao request e continua
    req.soldado_info = soldados[0];
    next();

  } catch (error) {
    // Envia o erro para o error handler
    next(error);
  }
};

module.exports = soldadoAuth;
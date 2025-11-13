const db = require('../../config/db'); 
const ApiError = require('../utils/ApiError'); 

const soldadoAuth = async (req, res, next) => {
  try {
    // Pré-requisito 1: Estar logado (o 'auth.middleware' já deve ter feito isto)
    if (!req.user) {
      throw new ApiError(401, 'Acesso não autorizado. Faça o login.');
    }

    // === INÍCIO DA CORREÇÃO ===
    // Pré-requisito 2: Ter se autenticado via Microsoft.
    // Verificamos se a coluna 'microsoft_id' no perfil do usuário está preenchida.
    // O req.user é o objeto completo da tabela 'policiais' (fornecido pelo auth.middleware)
    if (!req.user.microsoft_id) {
      throw new ApiError(403, 'Acesso restrito. Esta funcionalidade requer autenticação via Microsoft.');
    }
    // === FIM DA CORREÇÃO ===

    // Pré-requisito 3: Estar na lista de soldados
    // (A verificação anterior, usando id_funcional, estava correta)
    const idFuncional = req.user.id_funcional;
    const forcaId = req.user.forca_id;

    const [soldados] = await db.execute(
      'SELECT * FROM novos_soldados WHERE policial_id = ?',
      [idFuncional]
    );

    if (soldados.length === 0) {
      throw new ApiError(403, 'Acesso restrito. O seu ID Funcional não está na lista de novos soldados autorizados para esta funcionalidade.');
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
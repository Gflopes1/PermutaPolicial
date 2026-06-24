const ApiError = require('../../core/utils/ApiError');
const editaisRepository = require('./editais.repository');

/**
 * Exige agente_verificado=1 e id_funcional na lista do edital.
 * Deve rodar após auth.middleware.
 */
async function editalAccessMiddleware(req, res, next) {
  try {
    if (!req.user) {
      throw new ApiError(401, 'Usuário não autenticado.');
    }

    if (!req.user.agente_verificado || req.user.agente_verificado === 0) {
      throw new ApiError(
        403,
        'Acesso restrito. Sua conta precisa ser verificada para participar deste edital.'
      );
    }

    const editalId = parseInt(req.params.id, 10);
    if (!editalId) {
      throw new ApiError(400, 'ID do edital inválido.');
    }

    if (!req.user.id_funcional) {
      throw new ApiError(403, 'ID funcional não cadastrado no seu perfil.');
    }

    const participante = await editaisRepository.findParticipanteByEditalAndIdFuncional(
      editalId,
      String(req.user.id_funcional)
    );

    if (!participante) {
      throw new ApiError(403, 'Você não está na lista de participantes deste edital.');
    }

    req.edital_participante = participante;
    next();
  } catch (error) {
    next(error);
  }
}

module.exports = editalAccessMiddleware;

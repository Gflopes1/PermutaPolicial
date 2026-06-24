const editaisService = require('./editais.service');

const handle = (fn, status = 200) => async (req, res, next) => {
  try {
    const data = await fn(req);
    res.status(status).json({ status: 'success', data });
  } catch (e) {
    next(e);
  }
};

module.exports = {
  getWhatsappConfig: handle(() => editaisService.getWhatsappConfig()),

  listEditais: handle((req) =>
    editaisService.listForUser(req.user, { aba: req.query.aba || 'abertos' })
  ),

  getEdital: handle((req) => editaisService.getDetalhe(parseInt(req.params.id, 10), req.user)),

  getDadosTela: handle((req) =>
    editaisService.getDadosTela(
      parseInt(req.params.id, 10),
      req.user,
      req.edital_participante
    )
  ),

  salvarIntencoes: handle((req) =>
    editaisService.salvarIntencoes(parseInt(req.params.id, 10), req.user, req.body)
  ),

  analisarVaga: handle((req) =>
    editaisService.analisarVaga(
      parseInt(req.params.id, 10),
      parseInt(req.params.vagaId, 10),
      req.edital_participante
    )
  ),

  // Admin
  adminList: handle(() => editaisService.listAllAdmin()),

  adminCreate: handle((req) => editaisService.createEdital(req.body), 201),

  adminUpdate: handle((req) =>
    editaisService.updateEdital(parseInt(req.params.id, 10), req.body)
  ),

  adminDelete: handle((req) =>
    editaisService.deleteEdital(parseInt(req.params.id, 10))
  ),

  adminImportVagas: handle((req) =>
    editaisService.importarVagas(
      parseInt(req.params.id, 10),
      req.body.csv,
      req.body.modo || 'substituir'
    )
  ),

  adminImportParticipantes: handle((req) =>
    editaisService.importarParticipantes(
      parseInt(req.params.id, 10),
      req.body.csv,
      req.body.modo || 'substituir'
    )
  ),

  adminUpdateWhatsapp: handle((req) => editaisService.updateWhatsappConfig(req.body)),
};

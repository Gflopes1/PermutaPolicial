const express = require('express');
const { celebrate } = require('celebrate');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const editaisValidation = require('./editais.validation');
const editaisController = require('./editais.controller');

const router = express.Router();

router.use(authMiddleware, adminMiddleware);

router.get('/', editaisController.adminList);
router.post('/', celebrate(editaisValidation.adminCreateEdital), editaisController.adminCreate);
router.put('/:id', celebrate(editaisValidation.adminUpdateEdital), editaisController.adminUpdate);
router.delete('/:id', editaisController.adminDelete);

router.post(
  '/:id/importar-vagas',
  celebrate(editaisValidation.adminImportCsv),
  editaisController.adminImportVagas
);

router.post(
  '/:id/importar-participantes',
  celebrate(editaisValidation.adminImportCsv),
  editaisController.adminImportParticipantes
);

router.put(
  '/config/whatsapp',
  celebrate(editaisValidation.adminWhatsapp),
  editaisController.adminUpdateWhatsapp
);

module.exports = router;

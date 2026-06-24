const { Joi, Segments } = require('celebrate');

const editalBody = {
  tipo: Joi.string().valid('FORMACAO', 'TRANSFERENCIA_INTERNA').required(),
  forca_id: Joi.number().integer().required(),
  titulo: Joi.string().max(255).required(),
  resumo: Joi.string().allow('', null).optional(),
  link_pdf: Joi.string().uri().allow('', null).optional(),
  data_abertura: Joi.date().iso().allow(null).optional(),
  data_encerramento: Joi.date().iso().allow(null).optional(),
  status: Joi.string().valid('RASCUNHO', 'ABERTO', 'ENCERRADO').optional(),
  criterio_prioridade: Joi.string()
    .valid('CLASSIFICACAO_CURSO', 'ANTIGUIDADE', 'PONTUACAO', 'OUTRO')
    .optional(),
  criterio_label: Joi.string().max(120).optional(),
  max_opcoes: Joi.number().integer().min(1).max(5).optional(),
};

module.exports = {
  listEditais: {
    [Segments.QUERY]: Joi.object({
      aba: Joi.string().valid('abertos', 'encerrados').default('abertos'),
    }),
  },

  salvarIntencoes: {
    [Segments.BODY]: Joi.object({
      escolha_1_id: Joi.number().integer().allow(null).optional(),
      escolha_2_id: Joi.number().integer().allow(null).optional(),
      escolha_3_id: Joi.number().integer().allow(null).optional(),
    }),
  },

  adminCreateEdital: {
    [Segments.BODY]: Joi.object(editalBody),
  },

  adminUpdateEdital: {
    [Segments.BODY]: Joi.object({
      tipo: Joi.string().valid('FORMACAO', 'TRANSFERENCIA_INTERNA').optional(),
      forca_id: Joi.number().integer().optional(),
      titulo: Joi.string().max(255).optional(),
      resumo: Joi.string().allow('', null).optional(),
      link_pdf: Joi.string().allow('', null).optional(),
      data_abertura: Joi.date().iso().allow(null).optional(),
      data_encerramento: Joi.date().iso().allow(null).optional(),
      status: Joi.string().valid('RASCUNHO', 'ABERTO', 'ENCERRADO').optional(),
      criterio_prioridade: Joi.string()
        .valid('CLASSIFICACAO_CURSO', 'ANTIGUIDADE', 'PONTUACAO', 'OUTRO')
        .optional(),
      criterio_label: Joi.string().max(120).optional(),
      max_opcoes: Joi.number().integer().min(1).max(5).optional(),
    }),
  },

  adminImportCsv: {
    [Segments.BODY]: Joi.object({
      csv: Joi.string().min(3).required(),
      modo: Joi.string().valid('substituir', 'adicionar').default('substituir'),
    }),
  },

  adminWhatsapp: {
    [Segments.BODY]: Joi.object({
      numero: Joi.string().max(20).optional(),
      mensagem: Joi.string().max(500).optional(),
    }),
  },
};

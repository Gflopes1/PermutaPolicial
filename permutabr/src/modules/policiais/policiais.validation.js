// /src/modules/policiais/policiais.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
    // PUT /api/policiais/me
    updateMyProfile: {
        [Segments.BODY]: Joi.object().keys({
            // 1. CORREÇÃO PRINCIPAL: Permitir explicitamente o id_funcional
            id_funcional: Joi.string().allow('', null).optional(),

            qso: Joi.string().allow('', null).optional(),
            antiguidade: Joi.string().allow('', null).optional(),
            unidade_atual_id: Joi.number().integer().allow(null).optional(),
            lotacao_interestadual: Joi.boolean().optional(),
            ocultar_no_mapa: Joi.boolean().optional(),
            forca_id: Joi.number().integer().optional(),
            posto_graduacao_id: Joi.number().integer().allow(null).optional(),
        })
            // 2. ADIÇÃO PARA DEPURAÇÃO: Permite temporariamente outros campos não conhecidos.
            // Isso fará com que a validação passe e, se ainda houver um erro, 
            // ele acontecerá na camada do banco de dados, e veremos os logs de "🚨 DEBUG" que adicionamos antes.
            .unknown(true),
    },
};
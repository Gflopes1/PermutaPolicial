// /src/modules/policiais/policiais.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
    // PUT /api/policiais/me
    updateMyProfile: {
        [Segments.BODY]: Joi.object().keys({
            // Campos básicos editáveis
            nome: Joi.string().min(2).max(255).optional(),
            email: Joi.string().email().max(255).optional(),
            
            // Campos profissionais
            id_funcional: Joi.string().allow('', null).optional(),
            qso: Joi.string().allow('', null).optional(),
            antiguidade: Joi.string().allow('', null).optional(),
            unidade_atual_id: Joi.number().integer().allow(null).optional(),
            lotacao_interestadual: Joi.boolean().optional(),
            forca_id: Joi.number().integer().optional(),
            posto_graduacao_id: Joi.number().integer().allow(null).optional(),
        })
            .unknown(false), // Não permite campos não conhecidos para maior segurança
    },
};
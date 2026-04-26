// /src/modules/policiais/policiais.service.js

const policiaisRepository = require('./policiais.repository');
const paymentsRepository = require('../questions/payments.repository');
const ApiError = require('../../core/utils/ApiError');

class PoliciaisService {
    async getProfileById(policialId) {
        try {
        const profile = await policiaisRepository.findProfileById(policialId);
        if (!profile) {
            throw new ApiError(404, 'Perfil não encontrado.');
        }

        // Adiciona informação de assinatura Premium
        try {
            const subscription = await paymentsRepository.getUserActiveSubscription(policialId);
            // Verifica se tem assinatura ativa OU se o campo is_premium está marcado no banco
                const isPremiumFromDb = profile.is_premium === 1 || profile.is_premium === true || profile.is_premium === '1';
                const hasSubscription = !!subscription;
                profile.is_premium = hasSubscription || isPremiumFromDb;
            profile.subscription = subscription || null;
                
                // Debug log
                console.log('🔍 PoliciaisService.getProfileById - Premium Status:', {
                    policialId,
                    isPremiumFromDb,
                    hasSubscription,
                    subscriptionId: subscription?.id,
                    finalIsPremium: profile.is_premium,
                    is_premium_raw: profile.is_premium
                });
        } catch (error) {
            // Se houver erro ao verificar assinatura, verifica o campo direto do banco como fallback
                console.error('💥 Erro ao verificar assinatura premium:', {
                    policialId,
                    error: error.message,
                    is_premium_raw: profile.is_premium
                });
                // Garante que is_premium sempre tenha um valor booleano
                profile.is_premium = profile.is_premium === 1 || profile.is_premium === true || profile.is_premium === '1' || false;
            profile.subscription = null;
                
                console.log('🔍 PoliciaisService.getProfileById - Fallback Premium Status:', {
                    policialId,
                    is_premium_raw: profile.is_premium,
                    finalIsPremium: profile.is_premium
                });
        }

        return profile;
        } catch (error) {
            // Log detalhado do erro para debug
            if (process.env.NODE_ENV === 'development') {
                console.error('💥 Erro em getProfileById:', {
                    policialId,
                    error: error.message,
                    stack: error.stack,
                    code: error.code
                });
            }
            // Re-lança o erro para ser tratado pelo error handler
            throw error;
        }
    }

    // --- SUBSTITUA ESTA FUNÇÃO PELA VERSÃO ABAIXO ---
   async updateProfile(policialId, updateData) {
        const currentProfile = await policiaisRepository.findProfileById(policialId);
        if (!currentProfile) {
            throw new ApiError(404, 'Perfil não encontrado para atualização.');
        }

        // LISTA BRANCA DE CAMPOS PERMITIDOS
        const allowedFields = [
            'qso', 'antiguidade', 'unidade_atual_id', 'municipio_id', 
            'lotacao_interestadual', 'ocultar_no_mapa', 'forca_id', 
            'posto_graduacao_id', 'id_funcional'
        ];

        const fieldsToUpdate = {};
        
        // Apenas copia o que estiver na lista permitida
        Object.keys(updateData).forEach(key => {
            if (allowedFields.includes(key)) {
                fieldsToUpdate[key] = updateData[key];
            }
        });

        const { forca_id, unidade_atual_id, municipio_id, id_funcional, ...restData } = fieldsToUpdate;
        const filteredFieldsToUpdate = { ...restData };

        // === NOVA LÓGICA DE LOTAÇÃO ===
        // 1. Se uma unidade específica foi enviada (e não é nula)
        if (unidade_atual_id !== undefined && unidade_atual_id !== null) {
            const db = require('../../config/db');
            const [unidadeRows] = await db.execute('SELECT municipio_id FROM unidades WHERE id = ?', [unidade_atual_id]);
            
            if (unidadeRows.length > 0) {
                filteredFieldsToUpdate.municipio_atual_id = unidadeRows[0].municipio_id;
            }
            filteredFieldsToUpdate.unidade_atual_id = unidade_atual_id;
        } 
        // 2. Se a unidade foi enviada como nula (ex: lotação genérica só a nível de cidade)
        else if (unidade_atual_id === null) {
            filteredFieldsToUpdate.unidade_atual_id = null;
            if (municipio_id !== undefined) {
                filteredFieldsToUpdate.municipio_atual_id = municipio_id;
            } else {
                filteredFieldsToUpdate.municipio_atual_id = null;
            }
        } 
        // 3. Se não mexeu na unidade, mas enviou apenas o município
        else if (municipio_id !== undefined) {
            filteredFieldsToUpdate.municipio_atual_id = municipio_id;
        }

        // === LÓGICA DA FORÇA POLICIAL ===
        if (forca_id !== undefined) {
            filteredFieldsToUpdate.forca_id = forca_id;
        }

        // === VALIDAÇÃO DE ID FUNCIONAL ===
        if (id_funcional !== undefined && id_funcional !== null && id_funcional.trim() !== '') {
            const forcaIdParaVerificar = filteredFieldsToUpdate.forca_id || currentProfile.forca_id;
            if (forcaIdParaVerificar) {
                const db = require('../../config/db');
                const [existing] = await db.execute(
                    'SELECT id FROM policiais WHERE id_funcional = ? AND forca_id = ? AND id != ?',
                    [id_funcional.trim(), forcaIdParaVerificar, policialId]
                );
                if (existing.length > 0) {
                    throw new ApiError(409, 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.', null, 'ID_FUNCIONAL_ALREADY_EXISTS');
                }
            }
            filteredFieldsToUpdate.id_funcional = id_funcional.trim();
        } else if (id_funcional === '' || id_funcional === null) {
            // Permite limpar o ID se enviado vazio
            filteredFieldsToUpdate.id_funcional = null;
        }

        if (Object.keys(filteredFieldsToUpdate).length === 0) {
            return { message: 'Nenhum campo para atualizar foi fornecido.' };
        }

        try {
            const updated = await policiaisRepository.update(policialId, filteredFieldsToUpdate);
            if (!updated) {
                throw new ApiError(500, 'A atualização do perfil no banco de dados falhou.');
            }
        } catch (error) {
            if (error.code === 'ER_DUP_ENTRY') {
                const sqlMessage = error.sqlMessage || '';
                if (sqlMessage.includes('id_funcional') || sqlMessage.includes('ID_FUNCIONAL')) {
                    throw new ApiError(409, 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.', null, 'ID_FUNCIONAL_ALREADY_EXISTS');
                } else if (sqlMessage.includes('email') || sqlMessage.includes('EMAIL')) {
                    throw new ApiError(409, 'Este e-mail já está cadastrado.', null, 'EMAIL_ALREADY_EXISTS');
                } else {
                    throw new ApiError(409, 'Já existe um registro com estes dados. Verifique os dados e tente novamente.', null, 'DUPLICATE_ENTRY');
                }
            }
            throw error;
        }

        return { message: 'Perfil atualizado com sucesso.' };
    }
}

module.exports = new PoliciaisService();
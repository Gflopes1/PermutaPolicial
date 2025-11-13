// /src/modules/policiais/policiais.service.js

const policiaisRepository = require('./policiais.repository');
const ApiError = require('../../core/utils/ApiError');

class PoliciaisService {
    async getProfileById(policialId) {
        const profile = await policiaisRepository.findProfileById(policialId);
        if (!profile) {
            throw new ApiError(404, 'Perfil não encontrado.');
        }
        return profile;
    }

    // --- SUBSTITUA ESTA FUNÇÃO PELA VERSÃO ABAIXO ---
    async updateProfile(policialId, updateData) {
        const currentProfile = await policiaisRepository.findProfileById(policialId);
        if (!currentProfile) {
            throw new ApiError(404, 'Perfil não encontrado para atualização.');
        }

        const { forca_id, unidade_atual_id, ...restData } = updateData;
        const fieldsToUpdate = { ...restData };

        const isChangingForca = forca_id !== undefined &&
            forca_id !== currentProfile.forca_id &&
            currentProfile.forca_id !== null;

        if (isChangingForca) {
            fieldsToUpdate.forca_id = forca_id;
            fieldsToUpdate.unidade_atual_id = null;
        } else {
            if (forca_id !== undefined) {
                fieldsToUpdate.forca_id = forca_id;
            }
            if (unidade_atual_id !== undefined) {
                fieldsToUpdate.unidade_atual_id = unidade_atual_id;
            }
        }

        if (Object.keys(fieldsToUpdate).length === 0) {
            return { message: 'Nenhum campo para atualizar foi fornecido.' };
        }

        // --- INÍCIO DA CORREÇÃO ---
        try {
            const updated = await policiaisRepository.update(policialId, fieldsToUpdate);
            if (!updated) {
                throw new ApiError(500, 'A atualização do perfil no banco de dados falhou.');
            }
        } catch (error) {
            // Verifica se o erro é de entrada duplicada do MySQL/MariaDB
            if (error.code === 'ER_DUP_ENTRY') {
                // Lança um erro específico e amigável que será convertido para um status 409
                throw new ApiError(409, 'Este ID Funcional/Matrícula já está em uso nesta Força Policial. Verifique os dados e tente novamente.', null, 'DUPLICATE_ENTRY');
            }
            // Se for outro tipo de erro, lança-o para ser tratado pelo handler geral
            throw error;
        }
        // --- FIM DA CORREÇÃO ---

        return { message: 'Perfil atualizado com sucesso.' };
    }
}

module.exports = new PoliciaisService();
// /src/modules/parceiros/parceiros.service.js

const parceirosRepository = require('./parceiros.repository');
const ApiError = require('../../core/utils/ApiError');

class ParceirosService {
  async getAll() {
    return await parceirosRepository.findAll();
  }

  async getById(id) {
    const parceiro = await parceirosRepository.findById(id);
    if (!parceiro) {
      throw new ApiError(404, 'Parceiro não encontrado.', null, 'NOT_FOUND');
    }
    return parceiro;
  }

  async create(parceiroData) {
    if (!parceiroData.imagem_url) {
      throw new ApiError(400, 'URL da imagem é obrigatória.', null, 'VALIDATION_ERROR');
    }
    const id = await parceirosRepository.create(parceiroData);
    return await parceirosRepository.findById(id);
  }

  async update(id, parceiroData) {
    const existe = await parceirosRepository.findById(id);
    if (!existe) {
      throw new ApiError(404, 'Parceiro não encontrado.', null, 'NOT_FOUND');
    }
    if (!parceiroData.imagem_url) {
      throw new ApiError(400, 'URL da imagem é obrigatória.', null, 'VALIDATION_ERROR');
    }
    const sucesso = await parceirosRepository.update(id, parceiroData);
    if (!sucesso) {
      throw new ApiError(500, 'Erro ao atualizar parceiro.', null, 'UPDATE_ERROR');
    }
    return await parceirosRepository.findById(id);
  }

  async delete(id) {
    const existe = await parceirosRepository.findById(id);
    if (!existe) {
      throw new ApiError(404, 'Parceiro não encontrado.', null, 'NOT_FOUND');
    }
    const sucesso = await parceirosRepository.delete(id);
    if (!sucesso) {
      throw new ApiError(500, 'Erro ao excluir parceiro.', null, 'DELETE_ERROR');
    }
    return { message: 'Parceiro excluído com sucesso.' };
  }

  async getConfig() {
    return await parceirosRepository.getConfig();
  }

  async updateConfig(exibirCard) {
    await parceirosRepository.updateConfig(exibirCard);
    return { message: 'Configuração atualizada com sucesso.' };
  }
}

module.exports = new ParceirosService();


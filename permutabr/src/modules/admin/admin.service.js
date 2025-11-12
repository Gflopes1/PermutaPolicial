// /src/modules/admin/admin.service.js

const adminRepository = require('./admin.repository');
const ApiError = require('../../core/utils/ApiError');

class AdminService {
  async getEstatisticas() {
    return adminRepository.getEstatisticas();
  }

  async getSugestoes() {
    return adminRepository.findSugestoesPendentes();
  }

  async aprovarSugestao(sugestaoId) {
    await adminRepository.aprovarSugestao(sugestaoId);
    return { message: 'Sugestão aprovada e nova unidade criada.' };
  }

  async rejeitarSugestao(sugestaoId) {
    const success = await adminRepository.updateStatusSugestao(sugestaoId, 'REJEITADA');
    if (!success) {
      throw new ApiError(404, 'Sugestão não encontrada ou já processada.');
    }
    return { message: 'Sugestão rejeitada.' };
  }

  async getVerificacoes() {
    return adminRepository.findVerificacoesPendentes();
  }

  async verificarPolicial(policialId) {
    const success = await adminRepository.updateStatusPolicial(policialId, 'VERIFICADO');
    if (!success) {
      throw new ApiError(404, 'Policial não encontrado ou já processado.');
    }
    return { message: 'Policial verificado com sucesso.' };
  }
  
  async rejeitarPolicial(policialId) {
    const success = await adminRepository.updateStatusPolicial(policialId, 'REJEITADO');
    if (!success) {
        throw new ApiError(404, 'Policial não encontrado ou já processado.');
    }
    return { message: 'Policial rejeitado com sucesso.' };
  }

  async getAllPoliciais(page, limit, search) {
    return adminRepository.findAllPoliciais(page, limit, search);
  }

  async getAllParceiros() {
    return adminRepository.findAllParceiros();
  }

  async createParceiro(parceiro) {
    const id = await adminRepository.createParceiro(parceiro);
    // Busca o parceiro criado para retornar completo
    const parceiros = await adminRepository.findAllParceiros();
    const novoParceiro = parceiros.find(p => p.id === id);
    return novoParceiro || { id, ...parceiro };
  }

  async updateParceiro(id, parceiro) {
    const success = await adminRepository.updateParceiro(id, parceiro);
    if (!success) {
      throw new ApiError(404, 'Parceiro não encontrado.');
    }
    return { message: 'Parceiro atualizado com sucesso.' };
  }

  async deleteParceiro(id) {
    const success = await adminRepository.deleteParceiro(id);
    if (!success) {
      throw new ApiError(404, 'Parceiro não encontrado.');
    }
    return { message: 'Parceiro removido com sucesso.' };
  }

  async getParceirosConfig() {
    return adminRepository.getParceirosConfig();
  }

  async updateParceirosConfig(exibirCard) {
    await adminRepository.updateParceirosConfig(exibirCard);
    return { message: 'Configuração atualizada com sucesso.' };
  }
}

module.exports = new AdminService();
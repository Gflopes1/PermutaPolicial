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

  async getAllPoliciais(filters) {
    const [policiais, total] = await Promise.all([
      adminRepository.findAllPoliciais(filters),
      adminRepository.countPoliciais(filters),
    ]);
    return { policiais, total };
  }

  async updatePolicial(policialId, updateData) {
    const success = await adminRepository.updatePolicial(policialId, updateData);
    if (!success) {
      throw new ApiError(404, 'Policial não encontrado ou nenhum campo válido para atualizar.');
    }
    return { message: 'Policial atualizado com sucesso.' };
  }
}

module.exports = new AdminService();
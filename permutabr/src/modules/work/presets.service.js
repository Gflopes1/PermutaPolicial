// /src/modules/work/presets.service.js

const presetsRepository = require('./presets.repository');
const ApiError = require('../../core/utils/ApiError');

class PresetsService {
  // Busca todos os presets do usuário
  async getPresets(policialId) {
    const presets = await presetsRepository.findByPolicialId(policialId);
    
    // Processa intervalos JSON
    return presets.map(preset => {
      if (preset.intervals_json) {
        try {
          preset.intervals = JSON.parse(`[${preset.intervals_json}]`);
        } catch (e) {
          preset.intervals = [];
        }
      } else {
        preset.intervals = [];
      }
      delete preset.intervals_json;
      return preset;
    });
  }

  // Busca um preset específico
  async getPresetById(policialId, presetId) {
    const preset = await presetsRepository.findById(presetId, policialId);
    if (!preset) {
      throw new ApiError(404, 'Preset não encontrado.');
    }

    const intervals = await presetsRepository.findIntervalsByPresetId(presetId);
    preset.intervals = intervals;

    return preset;
  }

  // Cria um novo preset
  async createPreset(policialId, presetData) {
    // Validações
    if (!presetData.nome || presetData.nome.trim() === '') {
      throw new ApiError(400, 'Nome do preset é obrigatório.');
    }

    if (!presetData.cor) {
      throw new ApiError(400, 'Cor do preset é obrigatória.');
    }

    const intervals = presetData.intervals || [];
    const presetId = await presetsRepository.create(policialId, presetData, intervals);

    return await this.getPresetById(policialId, presetId);
  }

  // Atualiza um preset
  async updatePreset(policialId, presetId, presetData) {
    const preset = await presetsRepository.findById(presetId, policialId);
    if (!preset) {
      throw new ApiError(404, 'Preset não encontrado.');
    }

    const intervals = presetData.intervals !== undefined ? presetData.intervals : null;
    await presetsRepository.update(presetId, policialId, presetData, intervals);

    return await this.getPresetById(policialId, presetId);
  }

  // Deleta um preset
  async deletePreset(policialId, presetId) {
    const preset = await presetsRepository.findById(presetId, policialId);
    if (!preset) {
      throw new ApiError(404, 'Preset não encontrado.');
    }

    return await presetsRepository.delete(presetId, policialId);
  }

  // Cria presets iniciais (chamado quando usuário cria settings pela primeira vez)
  async createInitialPresets(policialId) {
    // Verifica se já tem presets
    const existing = await presetsRepository.findByPolicialId(policialId);
    if (existing.length > 0) {
      return existing; // Já tem presets, não cria novamente
    }

    await presetsRepository.createInitialPresets(policialId);
    return await this.getPresets(policialId);
  }
}

module.exports = new PresetsService();



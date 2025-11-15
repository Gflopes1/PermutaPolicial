// /src/modules/marketplace/marketplace.service.js

const marketplaceRepository = require('./marketplace.repository');
const ApiError = require('../../core/utils/ApiError');

class MarketplaceService {
  async getAll({ tipo, search, page, limit }) {
    return await marketplaceRepository.findAll({ tipo, search, page, limit, apenasAprovados: true });
  }

  async getById(id) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    return item;
  }

  async getByUsuario(policialId) {
    return await marketplaceRepository.findByUsuario(policialId);
  }

  async create(dados) {
    const { titulo, descricao, valor, tipo, fotos } = dados;
    
    if (!titulo || !descricao || !valor || !tipo) {
      throw new ApiError(400, 'Título, descrição, valor e tipo são obrigatórios.', null, 'VALIDATION_ERROR');
    }
    
    if (!fotos || fotos.length === 0) {
      throw new ApiError(400, 'Pelo menos uma foto é obrigatória.', null, 'VALIDATION_ERROR');
    }
    
    if (fotos.length > 3) {
      throw new ApiError(400, 'Máximo de 3 fotos permitidas.', null, 'VALIDATION_ERROR');
    }
    
    const tiposPermitidos = ['armas', 'veiculos', 'equipamentos'];
    if (!tiposPermitidos.includes(tipo)) {
      throw new ApiError(400, 'Tipo inválido. Use: armas, veiculos ou equipamentos.', null, 'VALIDATION_ERROR');
    }
    
    const valorNum = parseFloat(valor);
    if (isNaN(valorNum) || valorNum <= 0) {
      throw new ApiError(400, 'Valor deve ser um número positivo.', null, 'VALIDATION_ERROR');
    }
    
    const id = await marketplaceRepository.create({
      ...dados,
      valor: valorNum,
      status: 'PENDENTE'
    });
    
    return await marketplaceRepository.findById(id);
  }

  async update(id, dados, policialId) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    
    if (item.policial_id !== policialId) {
      throw new ApiError(403, 'Você não tem permissão para editar este item.', null, 'FORBIDDEN');
    }
    
    if (dados.valor) {
      const valorNum = parseFloat(dados.valor);
      if (isNaN(valorNum) || valorNum <= 0) {
        throw new ApiError(400, 'Valor deve ser um número positivo.', null, 'VALIDATION_ERROR');
      }
      dados.valor = valorNum;
    }
    
    if (dados.tipo) {
      const tiposPermitidos = ['armas', 'veiculos', 'equipamentos'];
      if (!tiposPermitidos.includes(dados.tipo)) {
        throw new ApiError(400, 'Tipo inválido. Use: armas, veiculos ou equipamentos.', null, 'VALIDATION_ERROR');
      }
    }
    
    // Se novas fotos foram enviadas, mantém apenas elas. Caso contrário, mantém as existentes
    if (dados.fotos && dados.fotos.length > 0) {
      if (dados.fotos.length > 3) {
        throw new ApiError(400, 'Máximo de 3 fotos permitidas.', null, 'VALIDATION_ERROR');
      }
    } else {
      // Mantém as fotos existentes
      dados.fotos = item.fotos;
    }
    
    // Se foi editado, volta para pendente
    dados.status = 'PENDENTE';
    
    const sucesso = await marketplaceRepository.update(id, dados);
    if (!sucesso) {
      throw new ApiError(500, 'Erro ao atualizar item.', null, 'UPDATE_ERROR');
    }
    
    return await marketplaceRepository.findById(id);
  }

  async delete(id, policialId) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    
    if (item.policial_id !== policialId) {
      throw new ApiError(403, 'Você não tem permissão para excluir este item.', null, 'FORBIDDEN');
    }
    
    const sucesso = await marketplaceRepository.delete(id);
    if (!sucesso) {
      throw new ApiError(500, 'Erro ao excluir item.', null, 'DELETE_ERROR');
    }
    
    return { message: 'Item excluído com sucesso.' };
  }

  async getAllAdmin({ status, page, limit }) {
    return await marketplaceRepository.findAll({ status, page, limit, apenasAprovados: false });
  }

  async aprovar(id) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    
    await marketplaceRepository.updateStatus(id, 'APROVADO');
    return await marketplaceRepository.findById(id);
  }

  async rejeitar(id) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    
    await marketplaceRepository.updateStatus(id, 'REJEITADO');
    return await marketplaceRepository.findById(id);
  }

  async deleteAdmin(id) {
    const item = await marketplaceRepository.findById(id);
    if (!item) {
      throw new ApiError(404, 'Item não encontrado.', null, 'NOT_FOUND');
    }
    
    const sucesso = await marketplaceRepository.delete(id);
    if (!sucesso) {
      throw new ApiError(500, 'Erro ao excluir item.', null, 'DELETE_ERROR');
    }
    
    return { message: 'Item excluído com sucesso.' };
  }
}

module.exports = new MarketplaceService();



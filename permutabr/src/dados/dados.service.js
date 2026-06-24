// /src/modules/dados/dados.service.js

const dadosRepository = require('./dados.repository');

class DadosService {
  async getForcas() {
    return dadosRepository.findAllForcas();
  }

  async getEstados() {
    return dadosRepository.findAllEstados();
  }

  async getMunicipiosByEstadoId(estadoId) {
    return dadosRepository.findMunicipiosByEstadoId(estadoId);
  }

  async getUnidades({ municipio_id, forca_id }) {
    return dadosRepository.findUnidades(municipio_id, forca_id);
  }

  async sugerirUnidade(sugeridoPorId, dadosDaSugestao) {
    const { nome_sugerido, municipio_id, forca_id } = dadosDaSugestao;
    await dadosRepository.createSugestao({
      nome_sugerido,
      municipio_id,
      forca_id,
      sugerido_por_policial_id: sugeridoPorId,
    });
    return { message: 'Sugestão enviada para análise. Obrigado por contribuir!' };
  }

  async getPostosByForca(tipoPermuta) {
    return dadosRepository.findPostosByForca(tipoPermuta);
  }
}

module.exports = new DadosService();
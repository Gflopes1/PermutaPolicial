// /src/modules/dados/dados.repository.js

const db = require('../../config/db');

class DadosRepository {
  async findAllForcas() {
    const [rows] = await db.query('SELECT id, nome, sigla, tipo, tipo_permuta FROM forcas_policiais ORDER BY nome');
    return rows;
  }

  async findAllEstados() {
    const [rows] = await db.query('SELECT id, nome, sigla FROM estados ORDER BY nome');
    return rows;
  }

  async findMunicipiosByEstadoId(estadoId) {
    const [rows] = await db.execute('SELECT id, nome FROM municipios WHERE estado_id = ? ORDER BY nome', [estadoId]);
    return rows;
  }

  async findUnidades(municipioId, forcaId) {
    const query = 'SELECT id, nome, generica FROM unidades WHERE municipio_id = ? AND (forca_id = ? OR generica = TRUE) ORDER BY nome';
    const [rows] = await db.execute(query, [municipioId, forcaId]);
    return rows;
  }

  async createSugestao(sugestao) {
    const { nome_sugerido, municipio_id, forca_id, sugerido_por_policial_id } = sugestao;
    const query = `
        INSERT INTO sugestoes_unidades (nome_sugerido, municipio_id, forca_id, sugerido_por_policial_id, status) 
        VALUES (?, ?, ?, ?, 'PENDENTE')
    `;
    await db.execute(query, [nome_sugerido, municipio_id, forca_id, sugerido_por_policial_id]);
  }

  async findPostosByForca(tipoPermuta) {
    const query = 'SELECT id, nome FROM postos_graduacoes WHERE tipo_forca = ? ORDER BY id';
    const [rows] = await db.execute(query, [tipoPermuta]);
    return rows;
  }
}

module.exports = new DadosRepository();
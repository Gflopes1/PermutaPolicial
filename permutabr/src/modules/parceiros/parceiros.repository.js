// /src/modules/parceiros/parceiros.repository.js

const db = require('../../config/db');

class ParceirosRepository {
  async findAll() {
    const [parceiros] = await db.query(
      'SELECT *, ordem as ordem_exibicao FROM parceiros ORDER BY ordem ASC, id DESC'
    );
    return parceiros;
  }

  async findById(id) {
    const [parceiros] = await db.query('SELECT * FROM parceiros WHERE id = ?', [id]);
    return parceiros[0] || null;
  }

  async create(parceiro) {
    const { imagem_url, link_url, ordem_exibicao, ativo } = parceiro;
    const [result] = await db.execute(
      'INSERT INTO parceiros (imagem_url, link_url, ordem, ativo) VALUES (?, ?, ?, ?)',
      [imagem_url, link_url || null, ordem_exibicao || 0, ativo !== false ? 1 : 0]
    );
    return result.insertId;
  }

  async update(id, parceiro) {
    const { imagem_url, link_url, ordem_exibicao, ativo } = parceiro;
    const [result] = await db.execute(
      'UPDATE parceiros SET imagem_url = ?, link_url = ?, ordem = ?, ativo = ? WHERE id = ?',
      [imagem_url, link_url || null, ordem_exibicao || 0, ativo !== false ? 1 : 0, id]
    );
    return result.affectedRows > 0;
  }

  async delete(id) {
    const [result] = await db.execute('DELETE FROM parceiros WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  async getConfig() {
    // Usa a tabela configuracoes_gerais que existe no banco
    const [config] = await db.query('SELECT valor FROM configuracoes_gerais WHERE chave = ?', ['exibir_card_parceiros']);
    const exibirCard = config.length > 0 && config[0].valor === '1';
    
    const parceiros = await this.findAll();
    const parceirosAtivos = parceiros.filter(p => p.ativo === 1 || p.ativo === true);
    
    return {
      exibir_card: exibirCard,
      parceiros: parceirosAtivos,
    };
  }

  async updateConfig(exibirCard) {
    // Usa a tabela configuracoes_gerais que existe no banco
    await db.execute(
      'INSERT INTO configuracoes_gerais (chave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?',
      ['exibir_card_parceiros', exibirCard ? '1' : '0', exibirCard ? '1' : '0']
    );
    return true;
  }
}

module.exports = new ParceirosRepository();


// /src/modules/marketplace/marketplace.repository.js

const db = require('../../config/db');

class MarketplaceRepository {
  async findAll({ tipo, search, status, estado, cidade, page, limit, apenasAprovados = true }) {
    let query = `
      SELECT 
        m.*,
        p.nome as policial_nome,
        p.email as policial_email,
        p.qso as policial_telefone
      FROM marketplace m
      LEFT JOIN policiais p ON m.policial_id = p.id
      LEFT JOIN unidades u ON p.unidade_atual_id = u.id
      LEFT JOIN municipios mun ON u.municipio_id = mun.id
      LEFT JOIN estados est ON mun.estado_id = est.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (apenasAprovados) {
      query += ' AND m.status = ?';
      params.push('APROVADO');
    } else if (status) {
      query += ' AND m.status = ?';
      params.push(status);
    }
    
    if (tipo) {
      query += ' AND m.tipo = ?';
      params.push(tipo);
    }
    
    if (search) {
      query += ' AND (m.titulo LIKE ? OR m.descricao LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    
    if (estado) {
      query += ' AND est.sigla = ? AND est.sigla IS NOT NULL';
      params.push(estado);
    }
    
    if (cidade) {
      query += ' AND mun.nome = ? AND mun.nome IS NOT NULL';
      params.push(cidade);
    }
    
    query += ' ORDER BY m.criado_em DESC';
    
    if (page && limit) {
      const offset = (page - 1) * limit;
      query += ' LIMIT ? OFFSET ?';
      params.push(limit, offset);
    }
    
    const [rows] = await db.execute(query, params);
    
    // Processa as fotos (JSON string para array)
    return rows.map(row => ({
      ...row,
      fotos: row.fotos ? JSON.parse(row.fotos) : []
    }));
  }

  async findById(id) {
    const [rows] = await db.execute(
      `SELECT 
        m.*,
        p.nome as policial_nome,
        p.email as policial_email,
        p.qso as policial_telefone
      FROM marketplace m
      LEFT JOIN policiais p ON m.policial_id = p.id
      WHERE m.id = ?`,
      [id]
    );
    
    if (rows.length === 0) return null;
    
    const item = rows[0];
    return {
      ...item,
      fotos: item.fotos ? JSON.parse(item.fotos) : []
    };
  }

  async findByUsuario(policialId) {
    const [rows] = await db.execute(
      'SELECT * FROM marketplace WHERE policial_id = ? ORDER BY criado_em DESC',
      [policialId]
    );
    
    return rows.map(row => ({
      ...row,
      fotos: row.fotos ? JSON.parse(row.fotos) : []
    }));
  }

  async create(dados) {
    const { titulo, descricao, valor, tipo, fotos, policial_id, status } = dados;
    
    const [result] = await db.execute(
      `INSERT INTO marketplace (titulo, descricao, valor, tipo, fotos, policial_id, status)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [titulo, descricao, valor, tipo, JSON.stringify(fotos || []), policial_id, status || 'PENDENTE']
    );
    
    return result.insertId;
  }

  async update(id, dados) {
    const campos = [];
    const valores = [];
    
    if (dados.titulo !== undefined) {
      campos.push('titulo = ?');
      valores.push(dados.titulo);
    }
    if (dados.descricao !== undefined) {
      campos.push('descricao = ?');
      valores.push(dados.descricao);
    }
    if (dados.valor !== undefined) {
      campos.push('valor = ?');
      valores.push(dados.valor);
    }
    if (dados.tipo !== undefined) {
      campos.push('tipo = ?');
      valores.push(dados.tipo);
    }
    if (dados.fotos !== undefined) {
      campos.push('fotos = ?');
      valores.push(JSON.stringify(dados.fotos));
    }
    if (dados.status !== undefined) {
      campos.push('status = ?');
      valores.push(dados.status);
    }
    
    if (campos.length === 0) return false;
    
    valores.push(id);
    
    const [result] = await db.execute(
      `UPDATE marketplace SET ${campos.join(', ')}, atualizado_em = NOW() WHERE id = ?`,
      valores
    );
    
    return result.affectedRows > 0;
  }

  async updateStatus(id, status) {
    const [result] = await db.execute(
      'UPDATE marketplace SET status = ?, atualizado_em = NOW() WHERE id = ?',
      [status, id]
    );
    
    return result.affectedRows > 0;
  }

  async delete(id) {
    const [result] = await db.execute('DELETE FROM marketplace WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }
}

module.exports = new MarketplaceRepository();





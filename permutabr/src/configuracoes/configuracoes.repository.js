// /src/modules/configuracoes/configuracoes.repository.js

const db = require('../../config/db');
const crypto = require('crypto');

class ConfiguracoesRepository {
  async getNotaAtualizacao() {
    try {
      const [rows] = await db.execute(
        'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
        ['nota_atualizacao']
      );
      
      if (rows.length === 0 || !rows[0].valor) {
        return { nota: null, versao: null };
      }
      
      const valor = rows[0].valor;
      
      // Usa hash do conteúdo como versão
      // Isso garante que a versão mude apenas quando o conteúdo mudar
      const hash = crypto.createHash('md5').update(valor).digest('hex');
      
      return { 
        nota: valor,
        versao: hash
      };
    } catch (error) {
      // Se a tabela não existir ou houver erro, retorna valores padrão
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_TABLE_ERROR') {
        if (process.env.NODE_ENV === 'development') {
          console.warn('⚠️ Tabela configuracoes_gerais não encontrada, retornando valores padrão');
        }
        return { nota: null, versao: null };
      }
      // Re-lança outros erros
      throw error;
    }
  }
}

module.exports = new ConfiguracoesRepository();


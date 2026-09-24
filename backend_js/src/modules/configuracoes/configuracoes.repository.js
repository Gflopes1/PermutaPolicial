// /src/modules/configuracoes/configuracoes.repository.js

const db = require('../../config/db');
const crypto = require('crypto');

class ConfiguracoesRepository {
  async getAppConfig() {
    try {
      const [rows] = await db.execute(
        'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
        ['dashboard_interface']
      );
      const raw = rows.length > 0 ? String(rows[0].valor || '').trim().toLowerCase() : 'antiga';
      const dashboardInterface = raw === 'nova' ? 'nova' : 'antiga';
      return { dashboard_interface: dashboardInterface };
    } catch (error) {
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_TABLE_ERROR') {
        return { dashboard_interface: 'antiga' };
      }
      throw error;
    }
  }

  async getApoio() {
    try {
      const [rows] = await db.execute(
        'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
        ['chave_pix_apoio']
      );
      const fromDb = rows.length > 0 ? String(rows[0].valor || '').trim() : '';
      const chavePix = fromDb || process.env.PIX_CHAVE || '';
      return {
        chave_pix: chavePix,
        mensagem: 'Ajude a manter a plataforma',
        titulo: 'Apoie o projeto via PIX',
      };
    } catch (error) {
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_TABLE_ERROR') {
        return {
          chave_pix: process.env.PIX_CHAVE || '',
          mensagem: 'Ajude a manter a plataforma',
          titulo: 'Apoie o projeto via PIX',
        };
      }
      throw error;
    }
  }

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


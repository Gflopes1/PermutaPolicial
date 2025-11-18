// /src/core/services/cleanup_service.js

const db = require('../../config/db');
const fs = require('fs');
const path = require('path');

class CleanupService {
  /**
   * Remove anúncios do marketplace com mais de 1 mês
   */
  async cleanupMarketplace() {
    try {
      const oneMonthAgo = new Date();
      oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

      // Busca anúncios antigos
      const [oldItems] = await db.execute(
        'SELECT id, fotos FROM marketplace WHERE criado_em < ?',
        [oneMonthAgo]
      );

      if (oldItems.length === 0) {
        console.log('✅ Nenhum anúncio antigo para limpar.');
        return { deleted: 0 };
      }

      // Remove arquivos de imagem
      for (const item of oldItems) {
        if (item.fotos) {
          try {
            const fotos = JSON.parse(item.fotos);
            for (const foto of fotos) {
              if (foto && foto.startsWith('/uploads/marketplace/')) {
                const filePath = path.join(__dirname, '../../..', foto);
                if (fs.existsSync(filePath)) {
                  fs.unlinkSync(filePath);
                  console.log(`🗑️  Arquivo removido: ${filePath}`);
                }
              }
            }
          } catch (e) {
            console.error(`Erro ao processar fotos do item ${item.id}:`, e);
          }
        }
      }

      // Remove do banco de dados
      const [result] = await db.execute(
        'DELETE FROM marketplace WHERE criado_em < ?',
        [oneMonthAgo]
      );

      console.log(`✅ ${result.affectedRows} anúncio(s) removido(s) do marketplace.`);
      return { deleted: result.affectedRows };
    } catch (error) {
      console.error('❌ Erro ao limpar marketplace:', error);
      throw error;
    }
  }

  /**
   * Remove intenções com mais de 6 meses
   */
  async cleanupIntencoes() {
    try {
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      // Como não temos campo de data de criação nas intenções, vamos usar uma abordagem diferente
      // Vamos assumir que a data de criação é quando foi inserida pela primeira vez
      // Se não houver campo criado_em, vamos adicionar um ou usar uma data padrão
      
      // Primeiro, vamos verificar se existe o campo criado_em
      const [columns] = await db.execute(
        "SHOW COLUMNS FROM intencoes LIKE 'criado_em'"
      );

      if (columns.length === 0) {
        // Se não existe, vamos adicionar o campo
        await db.execute(
          'ALTER TABLE intencoes ADD COLUMN criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
        );
        console.log('✅ Campo criado_em adicionado à tabela intencoes.');
        // Como acabamos de adicionar, não há registros antigos ainda
        return { deleted: 0 };
      }

      const [result] = await db.execute(
        'DELETE FROM intencoes WHERE criado_em < ?',
        [sixMonthsAgo]
      );

      console.log(`✅ ${result.affectedRows} intenção(ões) removida(s).`);
      return { deleted: result.affectedRows };
    } catch (error) {
      console.error('❌ Erro ao limpar intenções:', error);
      throw error;
    }
  }

  /**
   * Executa todas as limpezas
   */
  async runCleanup() {
    console.log('🧹 Iniciando limpeza automática...');
    const results = {
      marketplace: { deleted: 0 },
      intencoes: { deleted: 0 },
    };

    try {
      results.marketplace = await this.cleanupMarketplace();
    } catch (error) {
      console.error('Erro na limpeza do marketplace:', error);
    }

    try {
      results.intencoes = await this.cleanupIntencoes();
    } catch (error) {
      console.error('Erro na limpeza de intenções:', error);
    }

    console.log('✅ Limpeza automática concluída:', results);
    return results;
  }
}

module.exports = new CleanupService();





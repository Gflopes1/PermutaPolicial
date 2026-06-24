// /src/core/services/cleanup_service.js

const db = require('../../config/db');
const fs = require('fs');
const path = require('path');
const intencoesRepository = require('../../modules/intencoes/intencoes.repository');
const logger = require('../../core/utils/logger');

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
        logger.log('✅ Nenhum anúncio antigo para limpar.');
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
                  logger.log(`🗑️  Arquivo removido: ${filePath}`);
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

      logger.log(`✅ ${result.affectedRows} anúncio(s) removido(s) do marketplace.`);
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
      await intencoesRepository.ensureFeedbackSchema();

      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      const { deleted, permutasPorExpiracao } =
        await intencoesRepository.archiveExpiredBefore(sixMonthsAgo);

      logger.log(`✅ ${deleted} intenção(ões) arquivada(s) e removida(s).`);
      logger.log(`✅ ${permutasPorExpiracao} permuta(s) registrada(s) por expiração.`);
      return {
        deleted,
        permutasPorExpiracao,
      };
    } catch (error) {
      console.error('❌ Erro ao limpar intenções:', error);
      throw error;
    }
  }

  /**
   * Executa todas as limpezas
   */
  async runCleanup() {
    logger.log('🧹 Iniciando limpeza automática...');
    const results = {
      marketplace: { deleted: 0 },
      intencoes: { deleted: 0, permutasPorExpiracao: 0 },
      avisosExpiracao: { enviados: 0 },
    };

    try {
      const intencoesExpirationService = require('./intencoes_expiration.service');
      results.avisosExpiracao = await intencoesExpirationService.sendExpirationWarnings();
    } catch (error) {
      console.error('Erro ao enviar avisos de expiração:', error);
    }

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

    logger.log('✅ Limpeza automática concluída:', results);
    return results;
  }
}

module.exports = new CleanupService();





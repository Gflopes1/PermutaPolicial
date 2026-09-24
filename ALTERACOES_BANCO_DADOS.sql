-- ============================================
-- ALTERAÇÕES NO BANCO DE DADOS
-- Sistema de Notificações, Premium e Melhorias
-- ============================================

-- NOTA: A tabela `notificacoes` já existe no banco de dados conforme o arquivo SQL fornecido.
-- As seguintes alterações são necessárias apenas se a estrutura atual não estiver completa.

-- 1. Verificar se a tabela notificacoes existe e tem todos os campos necessários
-- Se não existir, execute:
/*
CREATE TABLE IF NOT EXISTS `notificacoes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `referencia_id` int(11) DEFAULT NULL,
  `titulo` varchar(255) NOT NULL,
  `mensagem` text DEFAULT NULL,
  `lida` tinyint(1) DEFAULT 0,
  `criado_em` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_lida` (`lida`),
  KEY `idx_criado_em` (`criado_em`),
  CONSTRAINT `notificacoes_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `policiais` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
*/

-- 2. Verificar se o campo `ocultar_no_mapa` existe na tabela `policiais`
-- Se não existir, execute:
ALTER TABLE `policiais` 
ADD COLUMN IF NOT EXISTS `ocultar_no_mapa` tinyint(1) NOT NULL DEFAULT 0 
COMMENT 'Se TRUE, o usuário não aparece no mapa de intenções';

-- 3. Índices adicionais para melhorar performance (opcional, mas recomendado)
-- Se os índices não existirem, execute:
CREATE INDEX IF NOT EXISTS `idx_notificacoes_usuario_lida` ON `notificacoes` (`usuario_id`, `lida`);
CREATE INDEX IF NOT EXISTS `idx_notificacoes_tipo` ON `notificacoes` (`tipo`);

-- 4. Verificar se o campo `antiguidade` existe na tabela `policiais`
-- Se não existir, execute:
ALTER TABLE `policiais` 
ADD COLUMN IF NOT EXISTS `antiguidade` varchar(50) DEFAULT NULL 
COMMENT 'Antiguidade do policial (ex: Turma 2018)';

-- ============================================
-- ALTERAÇÕES NA TABELA user_subscriptions
-- ============================================

-- 5. Verificar e melhorar a tabela user_subscriptions
-- Adicionar campos úteis se não existirem
ALTER TABLE `user_subscriptions` 
ADD COLUMN IF NOT EXISTS `canceled_at` TIMESTAMP NULL DEFAULT NULL 
COMMENT 'Data em que a assinatura foi cancelada';

ALTER TABLE `user_subscriptions` 
ADD COLUMN IF NOT EXISTS `cancel_reason` VARCHAR(255) NULL DEFAULT NULL 
COMMENT 'Motivo do cancelamento';

ALTER TABLE `user_subscriptions` 
ADD COLUMN IF NOT EXISTS `trial_ends_at` TIMESTAMP NULL DEFAULT NULL 
COMMENT 'Data de término do período de teste (se aplicável)';

-- 6. Índices adicionais para melhorar consultas de assinaturas
CREATE INDEX IF NOT EXISTS `idx_subscriptions_user_status` ON `user_subscriptions` (`user_id`, `status`);
CREATE INDEX IF NOT EXISTS `idx_subscriptions_status_end_at` ON `user_subscriptions` (`status`, `end_at`);
CREATE INDEX IF NOT EXISTS `idx_subscriptions_provider_subscription` ON `user_subscriptions` (`provider`, `provider_subscription_id`);

-- 7. Adicionar campo para rastrear renovações automáticas
ALTER TABLE `user_subscriptions` 
ADD COLUMN IF NOT EXISTS `auto_renew` tinyint(1) NOT NULL DEFAULT 1 
COMMENT 'Se TRUE, a assinatura renova automaticamente';

-- ============================================
-- RESUMO DAS ALTERAÇÕES
-- ============================================
-- 1. Tabela `notificacoes` - Já existe no banco, apenas verificar estrutura
-- 2. Campo `ocultar_no_mapa` na tabela `policiais` - Adicionar se não existir
-- 3. Campo `antiguidade` na tabela `policiais` - Adicionar se não existir
-- 4. Índices adicionais para melhorar performance das consultas de notificações
-- 5. Campos adicionais em `user_subscriptions`:
--    - canceled_at: Data do cancelamento
--    - cancel_reason: Motivo do cancelamento
--    - trial_ends_at: Data de término do trial
--    - auto_renew: Se renova automaticamente
-- 6. Índices adicionais para melhorar consultas de assinaturas
-- ============================================

-- NOTA IMPORTANTE:
-- Execute apenas as partes que ainda não foram aplicadas ao seu banco de dados.
-- Use IF NOT EXISTS ou verifique manualmente antes de executar.

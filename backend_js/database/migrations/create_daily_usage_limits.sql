-- ============================================
-- TABELA PARA CONTROLE DE LIMITES DIÁRIOS
-- Usuários Free têm limites diários de uso de recursos
-- ============================================

CREATE TABLE IF NOT EXISTS daily_usage_limits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    feature VARCHAR(50) NOT NULL COMMENT 'Nome da feature: ai_consult, simulado_questions',
    usage_date DATE NOT NULL COMMENT 'Data do uso (sem hora)',
    count INT NOT NULL DEFAULT 0 COMMENT 'Quantidade de usos no dia',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_feature_date (user_id, feature, usage_date),
    INDEX idx_user_id (user_id),
    INDEX idx_feature (feature),
    INDEX idx_usage_date (usage_date),
    INDEX idx_user_feature (user_id, feature)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comentários nas colunas
ALTER TABLE daily_usage_limits 
    MODIFY COLUMN feature VARCHAR(50) NOT NULL COMMENT 'Nome da feature: ai_consult, simulado_questions';


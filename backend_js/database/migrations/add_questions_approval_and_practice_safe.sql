-- ============================================
-- ADICIONAR COLUNA DE APROVAÇÃO E SISTEMA DE PRÁTICA
-- Versão segura que verifica se as colunas já existem
-- ============================================

-- Verificar e adicionar coluna 'aprovada'
SET @col_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'questions' 
  AND COLUMN_NAME = 'aprovada'
);

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE questions ADD COLUMN aprovada BOOLEAN DEFAULT TRUE',
  'SELECT "Coluna aprovada já existe" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar e adicionar coluna 'gerada_por_ia'
SET @col_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'questions' 
  AND COLUMN_NAME = 'gerada_por_ia'
);

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE questions ADD COLUMN gerada_por_ia BOOLEAN DEFAULT FALSE',
  'SELECT "Coluna gerada_por_ia já existe" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar e adicionar coluna 'aprovada_por'
SET @col_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'questions' 
  AND COLUMN_NAME = 'aprovada_por'
);

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE questions ADD COLUMN aprovada_por INT NULL',
  'SELECT "Coluna aprovada_por já existe" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar e adicionar coluna 'aprovada_em'
SET @col_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'questions' 
  AND COLUMN_NAME = 'aprovada_em'
);

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE questions ADD COLUMN aprovada_em TIMESTAMP NULL',
  'SELECT "Coluna aprovada_em já existe" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adicionar foreign key (se não existir)
SET @fk_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'questions' 
  AND CONSTRAINT_NAME = 'fk_questions_aprovada_por'
);

SET @sql = IF(@fk_exists = 0,
  'ALTER TABLE questions ADD CONSTRAINT fk_questions_aprovada_por FOREIGN KEY (aprovada_por) REFERENCES policiais(id)',
  'SELECT "Foreign key já existe" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adicionar índices (se não existirem)
CREATE INDEX IF NOT EXISTS idx_aprovada ON questions(aprovada);
CREATE INDEX IF NOT EXISTS idx_gerada_por_ia ON questions(gerada_por_ia);

-- Atualizar questões existentes para aprovadas por padrão
UPDATE questions SET aprovada = TRUE WHERE aprovada IS NULL;

-- Criar tabela para rastrear questões respondidas no modo prática
CREATE TABLE IF NOT EXISTS user_question_practice (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    question_id BIGINT NOT NULL,
    answer_given VARCHAR(10) NOT NULL,
    correct BOOLEAN NOT NULL,
    time_spent_seconds INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_question (user_id, question_id),
    INDEX idx_user (user_id),
    INDEX idx_question (question_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================
-- Migration: Adicionar suporte a sessões no Assistente IA
-- Data: 2024
-- ============================================

-- Cria a tabela assistant_messages se não existir
CREATE TABLE IF NOT EXISTS assistant_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    texto TEXT NOT NULL,
    resposta TEXT,
    role ENUM('user', 'model') NOT NULL DEFAULT 'user',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_policial_id (policial_id),
    INDEX idx_criado_em (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Adiciona a coluna session_id se não existir
-- Nota: IF NOT EXISTS pode não funcionar em versões antigas do MySQL
-- Se der erro, execute manualmente: ALTER TABLE assistant_messages ADD COLUMN session_id VARCHAR(50) DEFAULT NULL;
SET @dbname = DATABASE();
SET @tablename = 'assistant_messages';
SET @columnname = 'session_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' VARCHAR(50) DEFAULT NULL')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Cria índice composto para melhor performance nas consultas por sessão
-- Verifica se o índice já existe antes de criar
SET @indexname = 'idx_assistant_session';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (index_name = @indexname)
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE INDEX ', @indexname, ' ON ', @tablename, '(policial_id, session_id)')
));
PREPARE createIndexIfNotExists FROM @preparedStatement;
EXECUTE createIndexIfNotExists;
DEALLOCATE PREPARE createIndexIfNotExists;


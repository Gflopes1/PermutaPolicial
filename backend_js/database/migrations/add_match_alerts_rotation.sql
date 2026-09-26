-- Migration: rotação de usuários na varredura agendada de match alerts
-- Adiciona policiais.ultima_varredura_alertas + índice.
--
-- Compatível com MySQL 8 e MariaDB (NÃO usa ADD COLUMN IF NOT EXISTS /
-- CREATE INDEX IF NOT EXISTS, que não existem no MySQL 8).
-- Idempotente: checa information_schema e só executa o DDL se faltar.
-- Pode ser colado inteiro no phpMyAdmin / cliente mysql (sem DELIMITER).

SET @db := DATABASE();

-- 1) Coluna
SET @has_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'policiais' AND COLUMN_NAME = 'ultima_varredura_alertas'
);
SET @sql := IF(@has_col = 0,
  'ALTER TABLE policiais ADD COLUMN ultima_varredura_alertas DATETIME NULL COMMENT ''Timestamp da ultima varredura de match alerts para este usuario''',
  'SELECT ''coluna ultima_varredura_alertas ja existe'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) Índice (ORDER BY da query de rotação)
SET @has_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'policiais' AND INDEX_NAME = 'idx_policiais_ultima_varredura'
);
SET @sql := IF(@has_idx = 0,
  'CREATE INDEX idx_policiais_ultima_varredura ON policiais (ultima_varredura_alertas)',
  'SELECT ''indice idx_policiais_ultima_varredura ja existe'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificação
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'policiais' AND COLUMN_NAME = 'ultima_varredura_alertas';

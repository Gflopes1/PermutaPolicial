-- Adiciona campo criado_em na tabela intencoes se não existir
-- Este campo será usado para limpeza automática após 6 meses

-- Verifica se a coluna já existe antes de adicionar
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'intencoes'
    AND COLUMN_NAME = 'criado_em'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE intencoes ADD COLUMN criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    'SELECT "Coluna criado_em já existe" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Atualiza registros existentes sem data para usar a data atual
UPDATE intencoes SET criado_em = CURRENT_TIMESTAMP WHERE criado_em IS NULL;


-- Adiciona campos de local (unidade_atual_id e municipio_atual_id) na tabela intencoes
-- Esses campos armazenam o local onde o agente interessado se encontra

-- Verifica se a coluna unidade_atual_id já existe antes de adicionar
SET @col_exists_unidade = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'intencoes'
    AND COLUMN_NAME = 'unidade_atual_id'
);

SET @sql_unidade = IF(@col_exists_unidade = 0,
    'ALTER TABLE intencoes ADD COLUMN unidade_atual_id INT NULL AFTER unidade_id, ADD CONSTRAINT fk_intencoes_unidade_atual FOREIGN KEY (unidade_atual_id) REFERENCES unidades(id) ON DELETE SET NULL',
    'SELECT "Coluna unidade_atual_id já existe" AS message'
);

PREPARE stmt_unidade FROM @sql_unidade;
EXECUTE stmt_unidade;
DEALLOCATE PREPARE stmt_unidade;

-- Verifica se a coluna municipio_atual_id já existe antes de adicionar
SET @col_exists_municipio = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'intencoes'
    AND COLUMN_NAME = 'municipio_atual_id'
);

SET @sql_municipio = IF(@col_exists_municipio = 0,
    'ALTER TABLE intencoes ADD COLUMN municipio_atual_id INT NULL AFTER municipio_id, ADD CONSTRAINT fk_intencoes_municipio_atual FOREIGN KEY (municipio_atual_id) REFERENCES municipios(id) ON DELETE SET NULL',
    'SELECT "Coluna municipio_atual_id já existe" AS message'
);

PREPARE stmt_municipio FROM @sql_municipio;
EXECUTE stmt_municipio;
DEALLOCATE PREPARE stmt_municipio;

-- Popula os campos com os dados do perfil do policial para intenções existentes
UPDATE intencoes i
INNER JOIN policiais p ON i.policial_id = p.id
SET 
    i.unidade_atual_id = p.unidade_atual_id,
    i.municipio_atual_id = COALESCE(p.municipio_atual_id, 
        (SELECT municipio_id FROM unidades WHERE id = p.unidade_atual_id))
WHERE i.unidade_atual_id IS NULL OR i.municipio_atual_id IS NULL;


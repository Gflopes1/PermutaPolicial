-- ============================================
-- ADICIONA CAMPOS ADICIONAIS DE DESCONTOS E VANTAGENS
-- ============================================

-- Adiciona campos na tabela salary_settings (com verificação)
SET @col_exists_settings_descontos = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'salary_settings'
    AND COLUMN_NAME = 'outros_descontos'
);

SET @sql_settings_descontos = IF(@col_exists_settings_descontos = 0,
    'ALTER TABLE salary_settings ADD COLUMN outros_descontos DECIMAL(10, 2) DEFAULT 0.00 COMMENT ''Outros descontos em folha (ex: faltas, atrasos)''',
    'SELECT ''Coluna outros_descontos já existe em salary_settings'' AS message'
);

PREPARE stmt_settings_descontos FROM @sql_settings_descontos;
EXECUTE stmt_settings_descontos;
DEALLOCATE PREPARE stmt_settings_descontos;

SET @col_exists_settings_vantagens = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'salary_settings'
    AND COLUMN_NAME = 'outras_vantagens'
);

SET @sql_settings_vantagens = IF(@col_exists_settings_vantagens = 0,
    'ALTER TABLE salary_settings ADD COLUMN outras_vantagens DECIMAL(10, 2) DEFAULT 0.00 COMMENT ''Outras vantagens (ex: substituição, adicional)''',
    'SELECT ''Coluna outras_vantagens já existe em salary_settings'' AS message'
);

PREPARE stmt_settings_vantagens FROM @sql_settings_vantagens;
EXECUTE stmt_settings_vantagens;
DEALLOCATE PREPARE stmt_settings_vantagens;

-- Adiciona campos na tabela salary_results (com verificação)
SET @col_exists_results_descontos = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'salary_results'
    AND COLUMN_NAME = 'outros_descontos'
);

SET @sql_results_descontos = IF(@col_exists_results_descontos = 0,
    'ALTER TABLE salary_results ADD COLUMN outros_descontos DECIMAL(10, 2) DEFAULT 0.00 COMMENT ''Outros descontos em folha''',
    'SELECT ''Coluna outros_descontos já existe em salary_results'' AS message'
);

PREPARE stmt_results_descontos FROM @sql_results_descontos;
EXECUTE stmt_results_descontos;
DEALLOCATE PREPARE stmt_results_descontos;

SET @col_exists_results_vantagens = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'salary_results'
    AND COLUMN_NAME = 'outras_vantagens'
);

SET @sql_results_vantagens = IF(@col_exists_results_vantagens = 0,
    'ALTER TABLE salary_results ADD COLUMN outras_vantagens DECIMAL(10, 2) DEFAULT 0.00 COMMENT ''Outras vantagens (ex: substituição)''',
    'SELECT ''Coluna outras_vantagens já existe em salary_results'' AS message'
);

PREPARE stmt_results_vantagens FROM @sql_results_vantagens;
EXECUTE stmt_results_vantagens;
DEALLOCATE PREPARE stmt_results_vantagens;


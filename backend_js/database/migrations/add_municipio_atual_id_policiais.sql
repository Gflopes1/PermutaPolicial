-- Migration: Adiciona campo municipio_atual_id na tabela policiais
-- Data: 2025-01-17
-- Descrição: Permite armazenar município diretamente na tabela policiais,
--             independente da unidade, para melhorar o cálculo de permutas

-- Adiciona a coluna municipio_atual_id
ALTER TABLE policiais
ADD COLUMN municipio_atual_id INT NULL AFTER unidade_atual_id;

-- Adiciona foreign key constraint
ALTER TABLE policiais
ADD CONSTRAINT fk_policiais_municipio_atual
FOREIGN KEY (municipio_atual_id) REFERENCES municipios(id)
ON DELETE SET NULL;

-- Popula o campo municipio_atual_id com base na unidade atual existente
UPDATE policiais p
LEFT JOIN unidades u ON p.unidade_atual_id = u.id
SET p.municipio_atual_id = u.municipio_id
WHERE p.unidade_atual_id IS NOT NULL AND u.municipio_id IS NOT NULL;

-- Adiciona índice para melhorar performance nas queries
CREATE INDEX idx_policiais_municipio_atual_id ON policiais(municipio_atual_id);


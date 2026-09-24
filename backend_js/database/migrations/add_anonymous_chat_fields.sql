-- Migration: Adicionar suporte a conversas anônimas
-- Data: 2024

-- Adicionar campos na tabela conversas
ALTER TABLE conversas 
ADD COLUMN IF NOT EXISTS anonima BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS iniciada_por INT NULL,
ADD COLUMN IF NOT EXISTS remetente_revelado BOOLEAN DEFAULT FALSE;

-- Adicionar foreign key para iniciada_por
ALTER TABLE conversas
ADD CONSTRAINT fk_conversas_iniciada_por 
FOREIGN KEY (iniciada_por) REFERENCES policiais(id) ON DELETE SET NULL;

-- Adicionar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_conversas_anonima ON conversas(anonima);
CREATE INDEX IF NOT EXISTS idx_conversas_iniciada_por ON conversas(iniciada_por);


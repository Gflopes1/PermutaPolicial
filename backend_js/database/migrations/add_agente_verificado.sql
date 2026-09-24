-- Migration: Adiciona coluna agente_verificado para separar verificação de email de verificação do agente
-- Data: 2024

-- Adiciona a coluna agente_verificado (BOOLEAN, padrão FALSE)
ALTER TABLE policiais
ADD COLUMN agente_verificado BOOLEAN DEFAULT FALSE AFTER status_verificacao;

-- Atualiza registros existentes:
-- Se status_verificacao = 'VERIFICADO', então agente_verificado = TRUE
-- Caso contrário, agente_verificado = FALSE
UPDATE policiais
SET agente_verificado = CASE 
    WHEN status_verificacao = 'VERIFICADO' THEN TRUE
    ELSE FALSE
END;

-- Adiciona índice para melhorar performance em consultas
CREATE INDEX idx_agente_verificado ON policiais(agente_verificado);


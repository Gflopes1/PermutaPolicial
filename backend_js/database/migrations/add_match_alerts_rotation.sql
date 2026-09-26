-- Adiciona coluna para rastrear última varredura de match alerts
-- Permite rotacionar scans entre todos os usuários verificados ao longo do tempo

ALTER TABLE policiais 
ADD COLUMN ultima_varredura_alertas DATETIME NULL 
COMMENT 'Timestamp da última varredura de match alerts para este usuário';

CREATE INDEX idx_policiais_ultima_varredura ON policiais(ultima_varredura_alertas);

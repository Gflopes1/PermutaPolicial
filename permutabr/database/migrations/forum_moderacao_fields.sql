-- ============================================
-- CAMPOS DE MODERAÇÃO PARA O FÓRUM
-- ============================================

-- Adiciona campos de moderação na tabela forum_topicos
-- (Execute apenas se as colunas não existirem)
ALTER TABLE forum_topicos 
ADD COLUMN status_moderacao ENUM('PENDENTE', 'APROVADO', 'REJEITADO') DEFAULT 'APROVADO',
ADD COLUMN motivo_rejeicao TEXT NULL,
ADD COLUMN moderado_por INT NULL,
ADD COLUMN moderado_em TIMESTAMP NULL;

-- Adiciona índices e foreign keys
ALTER TABLE forum_topicos 
ADD INDEX idx_status_moderacao (status_moderacao),
ADD FOREIGN KEY (moderado_por) REFERENCES policiais(id) ON DELETE SET NULL;

-- Adiciona campos de moderação na tabela forum_respostas
ALTER TABLE forum_respostas 
ADD COLUMN status_moderacao ENUM('PENDENTE', 'APROVADO', 'REJEITADO') DEFAULT 'APROVADO',
ADD COLUMN motivo_rejeicao TEXT NULL,
ADD COLUMN moderado_por INT NULL,
ADD COLUMN moderado_em TIMESTAMP NULL;

-- Adiciona índices e foreign keys
ALTER TABLE forum_respostas 
ADD INDEX idx_status_moderacao (status_moderacao),
ADD FOREIGN KEY (moderado_por) REFERENCES policiais(id) ON DELETE SET NULL;

-- Atualiza tópicos e respostas existentes para APROVADO
UPDATE forum_topicos SET status_moderacao = 'APROVADO' WHERE status_moderacao IS NULL;
UPDATE forum_respostas SET status_moderacao = 'APROVADO' WHERE status_moderacao IS NULL;


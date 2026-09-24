-- ============================================
-- ADICIONAR COLUNA DE APROVAÇÃO E SISTEMA DE PRÁTICA
-- ============================================
-- Execute este script manualmente. Se alguma coluna já existir, ignore o erro.

-- Adicionar colunas na tabela questions
ALTER TABLE questions 
ADD COLUMN aprovada BOOLEAN DEFAULT TRUE,
ADD COLUMN gerada_por_ia BOOLEAN DEFAULT FALSE,
ADD COLUMN aprovada_por INT NULL,
ADD COLUMN aprovada_em TIMESTAMP NULL;

-- Adicionar foreign key
ALTER TABLE questions 
ADD CONSTRAINT fk_questions_aprovada_por 
FOREIGN KEY (aprovada_por) REFERENCES policiais(id);

-- Adicionar índices
CREATE INDEX idx_aprovada ON questions(aprovada);
CREATE INDEX idx_gerada_por_ia ON questions(gerada_por_ia);

-- Atualizar questões existentes para aprovadas por padrão
UPDATE questions SET aprovada = TRUE WHERE aprovada IS NULL;

-- Criar tabela para rastrear questões respondidas no modo prática
CREATE TABLE IF NOT EXISTS user_question_practice (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    question_id BIGINT NOT NULL,
    answer_given VARCHAR(10) NOT NULL,
    correct BOOLEAN NOT NULL,
    time_spent_seconds INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_question (user_id, question_id),
    INDEX idx_user (user_id),
    INDEX idx_question (question_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

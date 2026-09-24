-- ============================================
-- Migration: Criar tabela assistant_messages
-- Data: 2024
-- ============================================

-- Verifica se a tabela já existe antes de criar
CREATE TABLE IF NOT EXISTS assistant_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    texto TEXT NOT NULL,
    resposta TEXT,
    role ENUM('user', 'model') NOT NULL DEFAULT 'user',
    session_id VARCHAR(50) DEFAULT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_policial_id (policial_id),
    INDEX idx_criado_em (criado_em),
    INDEX idx_assistant_session (policial_id, session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


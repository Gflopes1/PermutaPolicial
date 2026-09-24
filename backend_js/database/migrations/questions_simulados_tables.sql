-- ============================================
-- MÓDULO: QUESTÕES & SIMULADOS
-- ============================================

-- Tabela de Questões
CREATE TABLE IF NOT EXISTS questions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pergunta TEXT NOT NULL,
    alternativas JSON NOT NULL,
    resposta_correta VARCHAR(10) NOT NULL,
    explicacao TEXT,
    assunto VARCHAR(100) NOT NULL,
    subassunto VARCHAR(100),
    tipo ENUM('mc', 'vf') NOT NULL DEFAULT 'mc',
    origem VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_assunto (assunto),
    INDEX idx_tipo (tipo),
    INDEX idx_created_at (created_at),
    FULLTEXT KEY idx_fulltext_pergunta (pergunta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Tags de Questões (opcional)
CREATE TABLE IF NOT EXISTS question_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id BIGINT NOT NULL,
    tag VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question (question_id),
    INDEX idx_tag (tag),
    UNIQUE KEY unique_question_tag (question_id, tag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Simulados
CREATE TABLE IF NOT EXISTS simulados (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    titulo VARCHAR(255),
    config JSON NOT NULL,
    started_at TIMESTAMP NULL,
    finished_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_started_at (started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Questões do Simulado
CREATE TABLE IF NOT EXISTS simulado_questions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    simulado_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    ordem INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulado_id) REFERENCES simulados(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_simulado (simulado_id),
    INDEX idx_question (question_id),
    UNIQUE KEY unique_simulado_ordem (simulado_id, ordem)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Tentativas de Questões
CREATE TABLE IF NOT EXISTS question_attempts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    simulado_id BIGINT,
    question_id BIGINT NOT NULL,
    answer_given VARCHAR(10) NOT NULL,
    correct BOOLEAN NOT NULL,
    time_spent_seconds INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (simulado_id) REFERENCES simulados(id) ON DELETE SET NULL,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_simulado (simulado_id),
    INDEX idx_question (question_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Estatísticas do Usuário
CREATE TABLE IF NOT EXISTS users_stats (
    user_id INT PRIMARY KEY,
    total_attempts INT DEFAULT 0,
    total_correct INT DEFAULT 0,
    accuracy DECIMAL(5, 2) DEFAULT 0.00,
    last_attempt_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Comentários em Questões
CREATE TABLE IF NOT EXISTS question_comments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    parent_id BIGINT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    is_hidden BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES question_comments(id) ON DELETE CASCADE,
    INDEX idx_question (question_id),
    INDEX idx_user (user_id),
    INDEX idx_parent (parent_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_hidden (is_hidden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Likes em Comentários
CREATE TABLE IF NOT EXISTS comment_likes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    comment_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES question_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_comment_user (comment_id, user_id),
    INDEX idx_comment (comment_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Reports de Comentários
CREATE TABLE IF NOT EXISTS comment_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    comment_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    reason ENUM('spam', 'inappropriate', 'off_topic', 'harassment', 'other') NOT NULL,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES question_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_comment (comment_id),
    INDEX idx_user (user_id),
    INDEX idx_reason (reason),
    UNIQUE KEY unique_comment_user_report (comment_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Logs de Moderação
CREATE TABLE IF NOT EXISTS comment_moderation_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    comment_id BIGINT NOT NULL,
    moderator_id INT NOT NULL,
    action ENUM('hide', 'unhide', 'delete', 'approve', 'warn') NOT NULL,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES question_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (moderator_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_comment (comment_id),
    INDEX idx_moderator (moderator_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Logs de Webhook de Pagamento
CREATE TABLE IF NOT EXISTS payment_webhook_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,
    raw_payload TEXT NOT NULL,
    headers JSON,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    error TEXT NULL,
    retry_count INT DEFAULT 0,
    INDEX idx_provider (provider),
    INDEX idx_processed (processed),
    INDEX idx_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Eventos de Pagamento Processados (Idempotência)
CREATE TABLE IF NOT EXISTS payment_events_processed (
    event_id VARCHAR(255) PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    status ENUM('processing', 'ok', 'failed') DEFAULT 'processing',
    note TEXT,
    INDEX idx_provider (provider),
    INDEX idx_status (status),
    INDEX idx_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Pagamentos
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,
    provider_payment_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    amount_cents INT NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    status ENUM('pending', 'succeeded', 'failed', 'refunded') DEFAULT 'pending',
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_provider (provider),
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    UNIQUE KEY unique_provider_payment (provider, provider_payment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Assinaturas de Usuário
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id VARCHAR(50) NOT NULL DEFAULT 'premium',
    status ENUM('active', 'canceled', 'expired', 'pending') DEFAULT 'pending',
    start_at TIMESTAMP NOT NULL,
    end_at TIMESTAMP NULL,
    provider VARCHAR(50) NOT NULL,
    provider_subscription_id VARCHAR(255),
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_provider (provider),
    INDEX idx_end_at (end_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trigger para atualizar estatísticas do usuário após tentativa
DELIMITER //
CREATE TRIGGER IF NOT EXISTS update_user_stats_after_attempt
AFTER INSERT ON question_attempts
FOR EACH ROW
BEGIN
    INSERT INTO users_stats (user_id, total_attempts, total_correct, accuracy, last_attempt_at)
    VALUES (NEW.user_id, 1, IF(NEW.correct, 1, 0), IF(NEW.correct, 100.00, 0.00), NEW.created_at)
    ON DUPLICATE KEY UPDATE
        total_attempts = total_attempts + 1,
        total_correct = total_correct + IF(NEW.correct, 1, 0),
        accuracy = (total_correct + IF(NEW.correct, 1, 0)) / (total_attempts + 1) * 100,
        last_attempt_at = NEW.created_at;
END //
DELIMITER ;

-- Trigger para auto-hide comentários com >3 reports
DELIMITER //
CREATE TRIGGER IF NOT EXISTS auto_hide_comment_on_reports
AFTER INSERT ON comment_reports
FOR EACH ROW
BEGIN
    DECLARE report_count INT;
    SELECT COUNT(*) INTO report_count
    FROM comment_reports
    WHERE comment_id = NEW.comment_id;
    
    IF report_count >= 3 THEN
        UPDATE question_comments
        SET is_hidden = TRUE
        WHERE id = NEW.comment_id AND is_hidden = FALSE;
    END IF;
END //
DELIMITER ;



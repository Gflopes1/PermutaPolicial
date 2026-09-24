-- Fase 3: histórico de ocorrência (linha do tempo)

CREATE TABLE IF NOT EXISTS map_point_occurrence_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    author_id INT NOT NULL,
    entry_type VARCHAR(255) NOT NULL DEFAULT 'ATUALIZACAO',
    narrative TEXT NOT NULL,
    status VARCHAR(255) NULL,
    occurred_at VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES policiais(id),
    INDEX idx_point_occurred (point_id, occurred_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

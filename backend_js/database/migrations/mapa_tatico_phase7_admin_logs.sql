-- Fase 7: trilha de auditoria do painel admin mapa tático (embaixador)

CREATE TABLE IF NOT EXISTS map_admin_action_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT NOT NULL,
    action ENUM('VIEW_GROUP_LIST','VIEW_GROUP_DETAIL','REMOVE_POINT','REMOVE_MEMBER') NOT NULL,
    group_id INT NULL,
    target_id INT NULL,
    reason TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES policiais(id),
    INDEX idx_admin_created (admin_id, created_at),
    INDEX idx_action_group (action, group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

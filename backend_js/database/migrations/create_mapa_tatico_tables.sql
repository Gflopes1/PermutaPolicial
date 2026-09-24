-- ============================================
-- TABELAS PARA MÓDULO MAPA TÁTICO E LOGÍSTICO
-- ============================================

-- Grupos de mapa (criados por policiais)
CREATE TABLE IF NOT EXISTS map_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    creator_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (creator_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_creator (creator_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Membros dos grupos
CREATE TABLE IF NOT EXISTS map_group_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('MEMBER', 'MODERATOR') NOT NULL DEFAULT 'MEMBER',
    nome_de_guerra VARCHAR(100) NULL,
    is_muted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES map_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_member (group_id, user_id),
    INDEX idx_group (group_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Convites por e-mail
CREATE TABLE IF NOT EXISTS map_group_invites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    invited_by_id INT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES map_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_group (group_id),
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pontos no mapa
CREATE TABLE IF NOT EXISTS map_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    creator_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    address VARCHAR(500) NULL,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    type VARCHAR(50) NOT NULL,
    map_type ENUM('OPERATIONAL', 'LOGISTICS') NOT NULL,
    expires_at TIMESTAMP NULL,
    photo_url VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (group_id) REFERENCES map_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_group_deleted (group_id, deleted_at),
    INDEX idx_expires (expires_at),
    INDEX idx_map_type (map_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comentários nos pontos
CREATE TABLE IF NOT EXISTS map_point_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    user_id INT NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_point (point_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Visitas "Fui Hoje" (mapa logístico)
CREATE TABLE IF NOT EXISTS map_point_visits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    user_id INT NOT NULL,
    visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_point (point_id),
    INDEX idx_user (user_id),
    INDEX idx_visited_at (visited_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Denúncias de pontos
CREATE TABLE IF NOT EXISTS map_point_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    user_id INT NOT NULL,
    reason TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_point (point_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Auditoria de pontos
CREATE TABLE IF NOT EXISTS map_point_audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    user_id INT NULL,
    action ENUM('CREATE', 'UPDATE', 'DELETE', 'REPORT', 'READ') NOT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE SET NULL,
    INDEX idx_point (point_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

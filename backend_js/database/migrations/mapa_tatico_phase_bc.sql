-- Mapa Tático — Fases B e C (descrição, blue force, geocode cache, denúncias admin)

ALTER TABLE map_points
  ADD COLUMN description TEXT NULL AFTER address;

CREATE TABLE IF NOT EXISTS map_geocode_cache (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cache_key VARCHAR(512) NOT NULL,
  cache_type ENUM('search', 'reverse') NOT NULL,
  response_json JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  UNIQUE KEY uk_cache_key (cache_key),
  INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS map_member_locations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_id INT NOT NULL,
  user_id INT NOT NULL,
  lat DECIMAL(10, 8) NOT NULL,
  lng DECIMAL(11, 8) NOT NULL,
  sharing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES map_groups(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE,
  UNIQUE KEY uk_group_user (group_id, user_id),
  INDEX idx_group_sharing (group_id, sharing_enabled, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE map_point_reports
  ADD COLUMN status ENUM('PENDING', 'REVIEWED', 'DISMISSED') NOT NULL DEFAULT 'PENDING' AFTER reason,
  ADD COLUMN reviewed_by_id INT NULL AFTER status,
  ADD COLUMN reviewed_at TIMESTAMP NULL AFTER reviewed_by_id,
  ADD COLUMN admin_notes TEXT NULL AFTER reviewed_at,
  ADD INDEX idx_status (status);

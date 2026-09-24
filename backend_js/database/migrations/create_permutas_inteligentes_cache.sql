-- Cache do motor experimental de permutas inteligentes (isolado do motor legado)

CREATE TABLE IF NOT EXISTS permutas_inteligentes_graph_snapshot (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY DEFAULT 1,
  payload LONGTEXT NOT NULL,
  node_count INT UNSIGNED NOT NULL DEFAULT 0,
  edge_count INT UNSIGNED NOT NULL DEFAULT 0,
  computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  CONSTRAINT chk_single_snapshot CHECK (id = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permutas_inteligentes_cache (
  id INT AUTO_INCREMENT PRIMARY KEY,
  policial_id INT NOT NULL,
  payload LONGTEXT NOT NULL,
  match_count INT UNSIGNED NOT NULL DEFAULT 0,
  computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  UNIQUE KEY uk_pi_cache_policial (policial_id),
  INDEX idx_pi_cache_expires (expires_at),
  CONSTRAINT fk_pi_cache_policial
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

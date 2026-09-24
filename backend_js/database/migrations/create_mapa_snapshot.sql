-- Cache de agregações do mapa de permutas (/api/mapa/dados)
-- TTL gerenciado pela aplicação (mapa.cache.repository.js)

CREATE TABLE IF NOT EXISTS mapa_snapshot (
  cache_key VARCHAR(120) NOT NULL PRIMARY KEY,
  payload LONGTEXT NOT NULL,
  computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  INDEX idx_mapa_snapshot_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mapa Tático: saúde (SHARED), mapa nacional colaborativo

ALTER TABLE map_groups
  ADD COLUMN is_global BOOLEAN NOT NULL DEFAULT FALSE AFTER name,
  ADD INDEX idx_is_global (is_global);

ALTER TABLE map_points
  MODIFY COLUMN map_type ENUM('OPERATIONAL', 'LOGISTICS', 'SHARED') NOT NULL;

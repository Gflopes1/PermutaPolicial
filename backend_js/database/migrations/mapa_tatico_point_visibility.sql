-- Fase 1: visibilidade privada de pontos no mapa tático

ALTER TABLE map_points
  ADD COLUMN visibility ENUM('GROUP', 'PRIVATE') NOT NULL DEFAULT 'GROUP' AFTER map_type;

ALTER TABLE map_points
  ADD INDEX idx_group_map_visibility_expires (group_id, map_type, visibility, expires_at);

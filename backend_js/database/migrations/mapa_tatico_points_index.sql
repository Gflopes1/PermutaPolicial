-- Índice composto para a consulta principal de pontos:
-- WHERE group_id = ? AND deleted_at IS NULL AND map_type = ? AND expires_at > NOW()
ALTER TABLE map_points
  ADD INDEX idx_group_map_active (group_id, map_type, deleted_at, expires_at);

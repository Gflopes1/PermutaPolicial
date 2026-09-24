-- Atualizações de segurança — Mapa Tático
-- Execute após create_mapa_tatico_tables.sql

-- TTL em convites pendentes (ignore erro se coluna já existir)
ALTER TABLE map_group_invites
  ADD COLUMN expires_at TIMESTAMP NULL AFTER status;

-- Expira convites antigos sem TTL definido (7 dias após criação)
UPDATE map_group_invites
SET expires_at = DATE_ADD(created_at, INTERVAL 7 DAY)
WHERE status = 'PENDING' AND expires_at IS NULL;

-- Auditoria de leitura de dados operacionais
ALTER TABLE map_point_audit_logs
  MODIFY COLUMN action ENUM('CREATE', 'UPDATE', 'DELETE', 'REPORT', 'READ') NOT NULL;

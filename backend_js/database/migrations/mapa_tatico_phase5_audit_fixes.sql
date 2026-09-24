-- Fase 5: preservar auditoria após exclusão de ponto + novas ações

ALTER TABLE map_point_audit_logs
  MODIFY COLUMN point_id INT NULL;

ALTER TABLE map_point_audit_logs
  DROP FOREIGN KEY map_point_audit_logs_ibfk_1;

ALTER TABLE map_point_audit_logs
  ADD CONSTRAINT fk_map_point_audit_logs_point
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE SET NULL;

ALTER TABLE map_point_audit_logs
  MODIFY COLUMN action ENUM(
    'CREATE','UPDATE','DELETE','REPORT','READ','OCCURRENCE_LOG','LIST_READ'
  ) NOT NULL;

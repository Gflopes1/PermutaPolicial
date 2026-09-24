-- Alertas de match, destaque de perfil e log de notificações

ALTER TABLE policiais
  ADD COLUMN destaque_ate DATETIME NULL COMMENT 'Perfil em destaque até esta data',
  ADD COLUMN alertas_match_ativo TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Receber alertas de novos matches';

CREATE TABLE IF NOT EXISTS match_alertas_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  match_chave VARCHAR(255) NOT NULL,
  tipo_match ENUM('DIRETA', 'INTERESSADO', 'TRIANGULAR') NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuario_match (usuario_id, match_chave),
  INDEX idx_usuario_criado (usuario_id, criado_em),
  FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

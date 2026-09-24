  -- Feedback de permutas concluídas + avisos de expiração de intenções

  CREATE TABLE IF NOT EXISTS permutas_concluidas_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    quantidade_intencoes INT NOT NULL DEFAULT 0,
    origem ENUM('MANUAL', 'EXPIRACAO') NOT NULL DEFAULT 'MANUAL',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_policial_id (policial_id),
    CONSTRAINT fk_permutas_concluidas_policial
      FOREIGN KEY (policial_id) REFERENCES policiais(id)
      ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS intencoes_avisos_email (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    tipo ENUM('AVISO_7_DIAS') NOT NULL DEFAULT 'AVISO_7_DIAS',
    enviado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_policial_tipo (policial_id, tipo),
    CONSTRAINT fk_intencoes_avisos_policial
      FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

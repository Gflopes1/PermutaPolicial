-- Histórico de intenções arquivadas + raio de proximidade para permuta inteligente

ALTER TABLE intencoes
  ADD COLUMN raio_km SMALLINT UNSIGNED NULL
    COMMENT 'Raio aceitável em km (NULL = match exato apenas)';

CREATE TABLE IF NOT EXISTS intencoes_historico (
  id INT AUTO_INCREMENT PRIMARY KEY,
  intencao_id INT NULL COMMENT 'ID original em intencoes (pode ser NULL após purge)',
  policial_id INT NOT NULL,
  prioridade TINYINT NOT NULL,
  tipo_intencao ENUM('ESTADO', 'MUNICIPIO', 'UNIDADE') NOT NULL,
  estado_id INT NULL,
  municipio_id INT NULL,
  unidade_id INT NULL,
  unidade_atual_id INT NULL,
  municipio_atual_id INT NULL,
  raio_km SMALLINT UNSIGNED NULL,
  criado_em TIMESTAMP NULL,
  renovado_em TIMESTAMP NULL,
  forca_id INT NULL COMMENT 'Snapshot da força no arquivamento',
  municipio_origem_id INT NULL COMMENT 'Snapshot do município de origem',
  posto_graduacao_id INT NULL,
  arquivado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  motivo ENUM(
    'ATUALIZACAO',
    'EXCLUSAO',
    'PERMUTA_CONCLUIDA',
    'EXPIRACAO',
    'CONTA_REMOVIDA'
  ) NOT NULL,
  INDEX idx_historico_policial (policial_id, arquivado_em),
  INDEX idx_historico_motivo (motivo, arquivado_em),
  INDEX idx_historico_destino (tipo_intencao, municipio_id, estado_id),
  CONSTRAINT fk_intencoes_historico_policial
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

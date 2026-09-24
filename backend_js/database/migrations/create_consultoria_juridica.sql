-- Consultoria Jurídica — parceiros (advogados/escritórios) e cliques rastreados

CREATE TABLE IF NOT EXISTS consultoria_advogados (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  descricao_curta VARCHAR(500) NOT NULL,
  descricao_detalhada TEXT NULL,
  foto_url VARCHAR(1024) NOT NULL,
  site_url VARCHAR(1024) NULL,
  contato_whatsapp VARCHAR(30) NULL,
  contato_telefone VARCHAR(30) NULL,
  contato_email VARCHAR(255) NULL,
  ordem INT NOT NULL DEFAULT 0,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_consultoria_ativo_ordem (ativo, ordem)
);

CREATE TABLE IF NOT EXISTS consultoria_cliques (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  advogado_id INT NOT NULL,
  usuario_id INT NULL,
  tipo_clique ENUM('contato', 'site') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_consultoria_cliques_advogado (advogado_id, tipo_clique),
  INDEX idx_consultoria_cliques_usuario (usuario_id),
  CONSTRAINT fk_consultoria_cliques_advogado
    FOREIGN KEY (advogado_id) REFERENCES consultoria_advogados(id) ON DELETE CASCADE,
  CONSTRAINT fk_consultoria_cliques_usuario
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE SET NULL
);

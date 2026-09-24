-- Migration: verificação de conta via OCR de documento
-- metodo_verificacao: manual_whatsapp | ocr_automatico | ocr_revisao_manual

ALTER TABLE policiais
  ADD COLUMN metodo_verificacao ENUM('manual_whatsapp', 'ocr_automatico', 'ocr_revisao_manual') NULL AFTER agente_verificado,
  ADD COLUMN verificado_em DATETIME NULL AFTER metodo_verificacao;

CREATE TABLE IF NOT EXISTS verificacoes_ocr_pendentes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  tipo_documento ENUM('funcional', 'contracheque') NOT NULL,
  imagem_redigida_url VARCHAR(500) NOT NULL,
  nome_extraido VARCHAR(255) NULL,
  matricula_extraida VARCHAR(100) NULL,
  forca_extraida VARCHAR(100) NULL,
  cargo_extraido VARCHAR(100) NULL,
  status ENUM('pendente_revisao_ocr', 'aprovado', 'rejeitado') NOT NULL DEFAULT 'pendente_revisao_ocr',
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revisado_em DATETIME NULL,
  revisado_por INT NULL,
  INDEX idx_verificacoes_ocr_status (status),
  INDEX idx_verificacoes_ocr_usuario (usuario_id),
  CONSTRAINT fk_verificacoes_ocr_usuario FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE CASCADE,
  CONSTRAINT fk_verificacoes_ocr_revisor FOREIGN KEY (revisado_por) REFERENCES policiais(id) ON DELETE SET NULL
);

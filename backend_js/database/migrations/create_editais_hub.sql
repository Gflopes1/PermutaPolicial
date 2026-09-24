-- Hub de Editais (formação + transferência interna)
-- Execute via Importar no phpMyAdmin (não cole após SELECT solto)

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS editais (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('FORMACAO', 'TRANSFERENCIA_INTERNA') NOT NULL,
  forca_id INT NOT NULL,
  titulo VARCHAR(255) NOT NULL,
  resumo TEXT NULL,
  link_pdf VARCHAR(500) NULL,
  data_abertura DATE NULL,
  data_encerramento DATE NULL,
  status ENUM('RASCUNHO', 'ABERTO', 'ENCERRADO') NOT NULL DEFAULT 'RASCUNHO',
  criterio_prioridade ENUM('CLASSIFICACAO_CURSO', 'ANTIGUIDADE', 'PONTUACAO', 'OUTRO') NOT NULL DEFAULT 'CLASSIFICACAO_CURSO',
  criterio_label VARCHAR(120) NOT NULL DEFAULT 'Classificação',
  max_opcoes TINYINT UNSIGNED NOT NULL DEFAULT 3,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_editais_status (status, data_encerramento),
  INDEX idx_editais_forca (forca_id),
  CONSTRAINT fk_editais_forca FOREIGN KEY (forca_id) REFERENCES forcas_policiais(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS edital_vagas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  edital_id INT NOT NULL,
  crpm VARCHAR(120) NULL,
  opm VARCHAR(255) NOT NULL,
  unidade_nome VARCHAR(255) NULL,
  vagas_disponiveis INT NOT NULL DEFAULT 0,
  ordem INT NOT NULL DEFAULT 0,
  INDEX idx_edital_vagas_edital (edital_id),
  CONSTRAINT fk_edital_vagas_edital FOREIGN KEY (edital_id) REFERENCES editais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS edital_participantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  edital_id INT NOT NULL,
  id_funcional VARCHAR(64) NOT NULL,
  posicao_prioridade INT NOT NULL,
  policial_id INT NULL,
  UNIQUE KEY uk_edital_id_funcional (edital_id, id_funcional),
  INDEX idx_edital_participantes_edital (edital_id),
  INDEX idx_edital_participantes_policial (policial_id),
  CONSTRAINT fk_edital_participantes_edital FOREIGN KEY (edital_id) REFERENCES editais(id) ON DELETE CASCADE,
  CONSTRAINT fk_edital_participantes_policial FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS edital_intencoes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  edital_id INT NOT NULL,
  policial_id INT NOT NULL,
  escolha_1_vaga_id INT NULL,
  escolha_2_vaga_id INT NULL,
  escolha_3_vaga_id INT NULL,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_edital_policial (edital_id, policial_id),
  CONSTRAINT fk_edital_intencoes_edital FOREIGN KEY (edital_id) REFERENCES editais(id) ON DELETE CASCADE,
  CONSTRAINT fk_edital_intencoes_policial FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
  CONSTRAINT fk_edital_intencoes_v1 FOREIGN KEY (escolha_1_vaga_id) REFERENCES edital_vagas(id) ON DELETE SET NULL,
  CONSTRAINT fk_edital_intencoes_v2 FOREIGN KEY (escolha_2_vaga_id) REFERENCES edital_vagas(id) ON DELETE SET NULL,
  CONSTRAINT fk_edital_intencoes_v3 FOREIGN KEY (escolha_3_vaga_id) REFERENCES edital_vagas(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Config WhatsApp (valores iniciais)
INSERT INTO configuracoes_gerais (chave, valor) VALUES
  ('editais_whatsapp_numero', '5551986200626'),
  ('editais_whatsapp_mensagem', 'Olá, gostaria de enviar um edital de transferência ou de novos agentes para adicionar ao site')
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- Migração legado novos soldados (se tabelas antigas existirem)
SET @legacy_edital_id = NULL;

INSERT INTO editais (tipo, forca_id, titulo, resumo, status, criterio_prioridade, criterio_label, data_abertura)
SELECT 'FORMACAO', COALESCE((SELECT id FROM forcas_policiais WHERE sigla = 'PMESP' LIMIT 1), 1),
  'Edital Novos Soldados (migrado)', 'Migrado automaticamente do módulo anterior.', 'ABERTO',
  'CLASSIFICACAO_CURSO', 'Classificação no curso', CURDATE()
FROM DUAL
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'edital_novos_soldados')
  AND NOT EXISTS (SELECT 1 FROM editais WHERE titulo = 'Edital Novos Soldados (migrado)');

SET @legacy_edital_id = (SELECT id FROM editais WHERE titulo = 'Edital Novos Soldados (migrado)' ORDER BY id DESC LIMIT 1);

INSERT INTO edital_vagas (id, edital_id, crpm, opm, vagas_disponiveis, ordem)
SELECT ens.id, @legacy_edital_id, ens.crpm, ens.opm, ens.vagas_disponiveis, ens.id
FROM edital_novos_soldados ens
WHERE @legacy_edital_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM edital_vagas ev WHERE ev.edital_id = @legacy_edital_id LIMIT 1);

-- Participantes: deduplica por id_funcional (legado pode ter linhas repetidas)
INSERT INTO edital_participantes (edital_id, id_funcional, posicao_prioridade, policial_id)
SELECT @legacy_edital_id, leg.id_funcional, leg.posicao_prioridade, leg.policial_id
FROM (
  SELECT
    CAST(ns.policial_id AS CHAR) AS id_funcional,
    MIN(ns.posicao_curso) AS posicao_prioridade,
    MAX(p.id) AS policial_id
  FROM novos_soldados ns
  LEFT JOIN policiais p ON CAST(p.id_funcional AS CHAR) = CAST(ns.policial_id AS CHAR)
  GROUP BY CAST(ns.policial_id AS CHAR)
) leg
WHERE @legacy_edital_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM edital_participantes ep WHERE ep.edital_id = @legacy_edital_id LIMIT 1);

-- Intenções: uma linha por policial (deduplicada)
INSERT INTO edital_intencoes (edital_id, policial_id, escolha_1_vaga_id, escolha_2_vaga_id, escolha_3_vaga_id)
SELECT @legacy_edital_id, leg.policial_id, leg.escolha_1_opm_id, leg.escolha_2_opm_id, leg.escolha_3_opm_id
FROM (
  SELECT
    CAST(ns.policial_id AS CHAR) AS id_funcional,
    MAX(p.id) AS policial_id,
    MAX(ns.escolha_1_opm_id) AS escolha_1_opm_id,
    MAX(ns.escolha_2_opm_id) AS escolha_2_opm_id,
    MAX(ns.escolha_3_opm_id) AS escolha_3_opm_id
  FROM novos_soldados ns
  INNER JOIN policiais p ON CAST(p.id_funcional AS CHAR) = CAST(ns.policial_id AS CHAR)
  GROUP BY CAST(ns.policial_id AS CHAR)
  HAVING MAX(ns.escolha_1_opm_id) IS NOT NULL
      OR MAX(ns.escolha_2_opm_id) IS NOT NULL
      OR MAX(ns.escolha_3_opm_id) IS NOT NULL
) leg
WHERE @legacy_edital_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM edital_intencoes ei WHERE ei.edital_id = @legacy_edital_id LIMIT 1);

SET FOREIGN_KEY_CHECKS = 1;

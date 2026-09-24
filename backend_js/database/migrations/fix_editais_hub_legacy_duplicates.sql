-- Corrige migração de participantes/intenções quando novos_soldados tem id_funcional duplicado.
-- Use se o create_editais_hub.sql falhou no INSERT de participantes (#1062 uk_edital_id_funcional).
-- Execute só este bloco no phpMyAdmin (aba SQL, sem SELECT anterior na mesma caixa).

SET @legacy_edital_id = (
  SELECT id FROM editais WHERE titulo = 'Edital Novos Soldados (migrado)' ORDER BY id DESC LIMIT 1
);

-- Participantes (deduplicados por id_funcional; posição = menor posicao_curso)
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

-- Intenções (deduplicadas por policial)
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

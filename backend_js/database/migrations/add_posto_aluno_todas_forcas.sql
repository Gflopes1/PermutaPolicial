-- Adiciona o cargo/posto "Aluno" em todos os tipos de força existentes
INSERT INTO postos_graduacoes (nome, tipo_forca)
SELECT 'Aluno', t.tipo_forca
FROM (
  SELECT DISTINCT tipo_forca AS tipo_forca FROM postos_graduacoes WHERE tipo_forca IS NOT NULL AND tipo_forca <> ''
  UNION
  SELECT DISTINCT tipo_permuta AS tipo_forca FROM forcas_policiais WHERE tipo_permuta IS NOT NULL AND tipo_permuta <> ''
) t
WHERE NOT EXISTS (
  SELECT 1
  FROM postos_graduacoes p
  WHERE p.nome = 'Aluno'
    AND p.tipo_forca = t.tipo_forca
);

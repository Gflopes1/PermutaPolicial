-- Índices para acelerar matching de permutas

CREATE INDEX idx_intencoes_policial_prioridade ON intencoes (policial_id, prioridade);
CREATE INDEX idx_intencoes_unidade_atual ON intencoes (unidade_atual_id);
CREATE INDEX idx_intencoes_municipio_atual ON intencoes (municipio_atual_id);
CREATE INDEX idx_intencoes_tipo_municipio ON intencoes (tipo_intencao, municipio_id);
CREATE INDEX idx_intencoes_tipo_unidade ON intencoes (tipo_intencao, unidade_id);
CREATE INDEX idx_intencoes_tipo_estado ON intencoes (tipo_intencao, estado_id);

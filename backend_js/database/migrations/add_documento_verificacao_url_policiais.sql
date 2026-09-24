-- URL da imagem do documento (carteira/contracheque) enviada para verificação OCR.
-- Preenchida após upload no CDN; usada enquanto aguarda revisão ou para auditoria.

ALTER TABLE policiais
  ADD COLUMN documento_verificacao_url VARCHAR(500) NULL AFTER verificado_em;

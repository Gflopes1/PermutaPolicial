-- Migration: Ampliar configuracoes_gerais.valor para TEXT
-- Data: 2026-03-10
-- Motivo: JSON da campanha referral_campaign_active excede VARCHAR(255) (#1406)
-- Execute se create_referral_tables.sql falhou no INSERT da campanha.

ALTER TABLE configuracoes_gerais
  MODIFY COLUMN valor TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO configuracoes_gerais (chave, valor)
SELECT 'referral_campaign_active', '{"id":"referral_campaign_2026_09","title":"Ajude o Permuta Policial a chegar à sua força","description":"O Permuta Policial já conecta policiais de diferentes forças e estados.\n\nAgora queremos levar a plataforma para mais policiais fora do RS.\n\nConvide seus colegas.\n\nQuanto mais policiais da sua força estiverem cadastrados, maiores as chances de encontrar uma permuta.","primary_action":"referral","primary_label":"Convidar colegas","secondary_label":"Agora não","show_share":true,"active":true}'
WHERE NOT EXISTS (
    SELECT 1 FROM configuracoes_gerais WHERE chave = 'referral_campaign_active'
);

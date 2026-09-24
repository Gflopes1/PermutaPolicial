-- Interface do dashboard: 'antiga' (padrão) ou 'nova'
INSERT INTO configuracoes_gerais (chave, valor)
VALUES ('dashboard_interface', 'antiga')
ON DUPLICATE KEY UPDATE chave = chave;

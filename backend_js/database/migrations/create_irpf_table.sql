-- ============================================
-- TABELA DE CONFIGURAÇÃO DE IRPF
-- ============================================
-- Esta tabela armazena as faixas de alíquota do IRPF para facilitar atualizações futuras
-- Os valores são mensais e seguem a tabela progressiva do IRPF

CREATE TABLE IF NOT EXISTS irpf_faixas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    limite_inferior DECIMAL(10, 2) NOT NULL COMMENT 'Limite inferior da faixa (inclusive)',
    limite_superior DECIMAL(10, 2) NULL COMMENT 'Limite superior da faixa (inclusive, NULL = sem limite)',
    aliquota DECIMAL(5, 2) NOT NULL COMMENT 'Alíquota em percentual (ex: 7.5 para 7,5%)',
    deducao DECIMAL(10, 2) NOT NULL DEFAULT 0 COMMENT 'Valor de dedução da faixa',
    ordem INT NOT NULL COMMENT 'Ordem das faixas (1 = primeira faixa)',
    ativo BOOLEAN DEFAULT TRUE COMMENT 'Se a faixa está ativa',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ordem (ordem),
    INDEX idx_ativo (ativo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insere as faixas de IRPF 2024 (valores mensais)
-- Tabela IRPF 2024:
-- - Até R$ 2.428,80: Isento
-- - De R$ 2.428,81 até R$ 2.826,65: 7,5% - Dedução R$ 182,16
-- - De R$ 2.826,66 até R$ 3.751,05: 15,0% - Dedução R$ 394,16
-- - De R$ 3.751,06 até R$ 4.664,68: 22,5% - Dedução R$ 675,49
-- - Acima de R$ 4.664,68: 27,5% - Dedução R$ 908,73

INSERT INTO irpf_faixas (limite_inferior, limite_superior, aliquota, deducao, ordem, ativo) VALUES
(0.00, 2428.80, 0.00, 0.00, 1, TRUE),           -- Isento
(2428.81, 2826.65, 7.50, 182.16, 2, TRUE),      -- 7,5%
(2826.66, 3751.05, 15.00, 394.16, 3, TRUE),     -- 15,0%
(3751.06, 4664.68, 22.50, 675.49, 4, TRUE),     -- 22,5%
(4664.69, NULL, 27.50, 908.73, 5, TRUE)         -- 27,5% (sem limite superior)
ON DUPLICATE KEY UPDATE
    limite_inferior = VALUES(limite_inferior),
    limite_superior = VALUES(limite_superior),
    aliquota = VALUES(aliquota),
    deducao = VALUES(deducao),
    ordem = VALUES(ordem),
    ativo = VALUES(ativo);


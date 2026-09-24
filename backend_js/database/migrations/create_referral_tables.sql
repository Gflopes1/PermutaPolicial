-- Migration: Sistema de indicação / referral
-- Data: 2026-03-10
-- Descrição: Tabelas para códigos de indicação, referrals, dismiss de campanhas e metas por força

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS referral_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    code VARCHAR(12) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_referral_codes_user (user_id),
    UNIQUE KEY uk_referral_codes_code (code),
    INDEX idx_referral_codes_code (code),
    CONSTRAINT fk_referral_codes_user FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS referrals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    referrer_user_id INT NOT NULL,
    referred_user_id INT NOT NULL,
    referral_code VARCHAR(12) NOT NULL,
    status ENUM('pending', 'verified', 'invalid') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,
    UNIQUE KEY uk_referrals_referred (referred_user_id),
    INDEX idx_referrals_referrer (referrer_user_id),
    INDEX idx_referrals_status (status),
    INDEX idx_referrals_code (referral_code),
    CONSTRAINT fk_referrals_referrer FOREIGN KEY (referrer_user_id) REFERENCES policiais(id) ON DELETE CASCADE,
    CONSTRAINT fk_referrals_referred FOREIGN KEY (referred_user_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS referral_campaign_dismissals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    campaign_id VARCHAR(64) NOT NULL,
    dismissed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_referral_campaign_dismiss (user_id, campaign_id),
    INDEX idx_referral_campaign_id (campaign_id),
    CONSTRAINT fk_referral_campaign_user FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS referral_force_goals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    forca_id INT NOT NULL,
    meta_usuarios INT NOT NULL DEFAULT 50,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_referral_force_goals_forca (forca_id),
    CONSTRAINT fk_referral_force_goals_forca FOREIGN KEY (forca_id) REFERENCES forcas_policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Coluna valor legada costuma ser VARCHAR(255); campanhas JSON precisam de mais espaço
ALTER TABLE configuracoes_gerais
  MODIFY COLUMN valor TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Campanha inicial de indicação (popup versionado)
INSERT INTO configuracoes_gerais (chave, valor)
SELECT 'referral_campaign_active', '{"id":"referral_campaign_2026_09","title":"Ajude o Permuta Policial a chegar à sua força","description":"O Permuta Policial já conecta policiais de diferentes forças e estados.\n\nAgora queremos levar a plataforma para mais policiais fora do RS.\n\nConvide seus colegas.\n\nQuanto mais policiais da sua força estiverem cadastrados, maiores as chances de encontrar uma permuta.","primary_action":"referral","primary_label":"Convidar colegas","secondary_label":"Agora não","show_share":true,"active":true}'
WHERE NOT EXISTS (
    SELECT 1 FROM configuracoes_gerais WHERE chave = 'referral_campaign_active'
);

SET FOREIGN_KEY_CHECKS = 1;

-- ROLLBACK (manual):
-- DROP TABLE IF EXISTS referral_force_goals;
-- DROP TABLE IF EXISTS referral_campaign_dismissals;
-- DROP TABLE IF EXISTS referrals;
-- DROP TABLE IF EXISTS referral_codes;
-- DELETE FROM configuracoes_gerais WHERE chave = 'referral_campaign_active';

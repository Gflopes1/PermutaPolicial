-- Fase 4: perfil estruturado de suspeito + aceite de responsabilização

CREATE TABLE IF NOT EXISTS map_point_suspect_profile (
    point_id INT PRIMARY KEY,
    apelido VARCHAR(100) NULL,
    caracteristicas_fisicas TEXT NULL,
    altura_cm VARCHAR(255) NULL,
    compleicao VARCHAR(255) NULL,
    tatuagens_marcas TEXT NULL,
    veiculos_associados TEXT NULL,
    modus_operandi TEXT NULL,
    nivel_periculosidade VARCHAR(255) NOT NULL DEFAULT 'BAIXO',
    orientacoes_abordagem TEXT NULL,
    bo_rai_numero VARCHAR(50) NULL,
    fundamentacao TEXT NOT NULL,
    criado_por INT NOT NULL,
    archived_at TIMESTAMP NULL,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (criado_por) REFERENCES policiais(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS map_suspect_profile_disclaimer_ack (
    user_id INT PRIMARY KEY,
    acknowledged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES policiais(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migration: Criação de tabela para relatos de problemas
-- Data: 2025-01-XX
-- Descrição: Tabela para armazenar relatos de problemas dos usuários

CREATE TABLE IF NOT EXISTS problema_relatos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NULL, -- NULL para relatos de usuários não autenticados
    pagina VARCHAR(255) NOT NULL, -- Nome da página onde o problema ocorreu
    detalhes TEXT NOT NULL, -- Descrição detalhada do problema
    status ENUM('PENDENTE', 'EM_ANALISE', 'RESOLVIDO', 'DESCARTADO') DEFAULT 'PENDENTE',
    resolucao TEXT NULL, -- Resposta/resolução do problema (preenchido por admin)
    resolvido_por INT NULL, -- ID do admin que resolveu
    resolvido_em TIMESTAMP NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_pagina (pagina),
    INDEX idx_status (status),
    INDEX idx_criado_em (criado_em),
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE SET NULL,
    FOREIGN KEY (resolvido_por) REFERENCES policiais(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

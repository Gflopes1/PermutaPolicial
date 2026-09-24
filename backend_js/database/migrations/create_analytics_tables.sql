-- Migration: Criação de tabelas para sistema de analytics
-- Data: 2025-01-17
-- Descrição: Tabelas para rastrear ações dos usuários, acessos e visitas

-- Tabela de eventos de usuário (criação de conta, login, etc)
CREATE TABLE IF NOT EXISTS user_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NULL, -- NULL para eventos de usuários não autenticados
    evento_tipo VARCHAR(50) NOT NULL, -- 'ACCOUNT_CREATED', 'LOGIN', 'LOGOUT', 'PROFILE_UPDATED', etc
    metadata JSON NULL, -- Dados adicionais do evento
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_evento_tipo (evento_tipo),
    INDEX idx_criado_em (criado_em),
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de visualizações de página/área
CREATE TABLE IF NOT EXISTS page_views (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NULL, -- NULL para visitantes não autenticados
    pagina VARCHAR(100) NOT NULL, -- '/dashboard', '/permutas', '/marketplace', etc
    sessao_id VARCHAR(100) NULL, -- ID da sessão do usuário
    tempo_permanencia INT NULL, -- Tempo em segundos (calculado quando sair da página)
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_pagina (pagina),
    INDEX idx_sessao_id (sessao_id),
    INDEX idx_criado_em (criado_em),
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de sessões de usuário
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NULL, -- NULL para sessões de visitantes não autenticados
    sessao_id VARCHAR(100) NOT NULL UNIQUE,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    dispositivo_tipo VARCHAR(20) NULL, -- 'desktop', 'mobile', 'tablet'
    navegador VARCHAR(50) NULL,
    sistema_operacional VARCHAR(50) NULL,
    inicio_sessao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fim_sessao TIMESTAMP NULL,
    duracao_segundos INT NULL, -- Calculado quando a sessão termina
    total_page_views INT DEFAULT 0,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_sessao_id (sessao_id),
    INDEX idx_inicio_sessao (inicio_sessao),
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


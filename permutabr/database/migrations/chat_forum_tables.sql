-- ============================================
-- TABELAS PARA SISTEMA DE CHAT E FÓRUM
-- ============================================

-- Tabela de Conversas (Chat entre dois usuários)
CREATE TABLE IF NOT EXISTS conversas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario1_id INT NOT NULL,
    usuario2_id INT NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario1_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario2_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_conversa (usuario1_id, usuario2_id),
    INDEX idx_usuario1 (usuario1_id),
    INDEX idx_usuario2 (usuario2_id),
    INDEX idx_atualizado_em (atualizado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Mensagens do Chat
CREATE TABLE IF NOT EXISTS mensagens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conversa_id INT NOT NULL,
    remetente_id INT NOT NULL,
    mensagem TEXT NOT NULL,
    lida BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversa_id) REFERENCES conversas(id) ON DELETE CASCADE,
    FOREIGN KEY (remetente_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_conversa (conversa_id),
    INDEX idx_remetente (remetente_id),
    INDEX idx_criado_em (criado_em),
    INDEX idx_lida (lida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Status de Leitura (para rastrear quais mensagens cada usuário leu)
CREATE TABLE IF NOT EXISTS mensagens_lidas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensagem_id INT NOT NULL,
    usuario_id INT NOT NULL,
    lida_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mensagem_id) REFERENCES mensagens(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_leitura (mensagem_id, usuario_id),
    INDEX idx_usuario (usuario_id),
    INDEX idx_mensagem (mensagem_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Categorias do Fórum
CREATE TABLE IF NOT EXISTS forum_categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    cor VARCHAR(7) DEFAULT '#2196F3', -- Cor em hexadecimal
    icone VARCHAR(50) DEFAULT 'forum', -- Nome do ícone
    ordem INT DEFAULT 0,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ordem (ordem),
    INDEX idx_ativo (ativo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Tópicos do Fórum
CREATE TABLE IF NOT EXISTS forum_topicos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    autor_id INT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    conteudo TEXT NOT NULL,
    fixado BOOLEAN DEFAULT FALSE,
    bloqueado BOOLEAN DEFAULT FALSE,
    visualizacoes INT DEFAULT 0,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES forum_categorias(id) ON DELETE RESTRICT,
    FOREIGN KEY (autor_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_categoria (categoria_id),
    INDEX idx_autor (autor_id),
    INDEX idx_fixado (fixado),
    INDEX idx_criado_em (criado_em),
    FULLTEXT KEY idx_fulltext (titulo, conteudo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Respostas do Fórum
CREATE TABLE IF NOT EXISTS forum_respostas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topico_id INT NOT NULL,
    autor_id INT NOT NULL,
    conteudo TEXT NOT NULL,
    resposta_id INT NULL, -- Para respostas a outras respostas (comentários)
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (topico_id) REFERENCES forum_topicos(id) ON DELETE CASCADE,
    FOREIGN KEY (autor_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (resposta_id) REFERENCES forum_respostas(id) ON DELETE CASCADE,
    INDEX idx_topico (topico_id),
    INDEX idx_autor (autor_id),
    INDEX idx_resposta (resposta_id),
    INDEX idx_criado_em (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Reações (Curtidas, etc)
CREATE TABLE IF NOT EXISTS forum_reacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topico_id INT NULL,
    resposta_id INT NULL,
    usuario_id INT NOT NULL,
    tipo VARCHAR(20) DEFAULT 'curtida', -- curtida, descurtida, etc
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topico_id) REFERENCES forum_topicos(id) ON DELETE CASCADE,
    FOREIGN KEY (resposta_id) REFERENCES forum_respostas(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_reacao_topico (topico_id, usuario_id, tipo),
    UNIQUE KEY unique_reacao_resposta (resposta_id, usuario_id, tipo),
    INDEX idx_usuario (usuario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Notificações (para notificar usuários sobre novas mensagens/respostas)
CREATE TABLE IF NOT EXISTS notificacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    tipo VARCHAR(50) NOT NULL, -- 'mensagem', 'resposta_forum', 'mencao', etc
    referencia_id INT NULL, -- ID da mensagem, resposta, etc
    titulo VARCHAR(255) NOT NULL,
    mensagem TEXT,
    lida BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_lida (lida),
    INDEX idx_criado_em (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- INSERIR CATEGORIAS PADRÃO DO FÓRUM
-- ============================================

INSERT INTO forum_categorias (nome, descricao, cor, icone, ordem) VALUES
('Geral', 'Discussões gerais sobre permutas', '#2196F3', 'forum', 1),
('Dúvidas', 'Tire suas dúvidas sobre o sistema', '#4CAF50', 'help', 2),
('Sugestões', 'Sugira melhorias para a plataforma', '#FF9800', 'lightbulb', 3),
('Anúncios', 'Avisos e comunicados oficiais', '#F44336', 'announcement', 0)
ON DUPLICATE KEY UPDATE nome=nome;


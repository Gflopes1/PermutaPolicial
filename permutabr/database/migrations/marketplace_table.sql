-- Tabela para o sistema de marketplace
CREATE TABLE IF NOT EXISTS marketplace (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    valor DECIMAL(10, 2) NOT NULL,
    tipo ENUM('armas', 'veiculos', 'equipamentos') NOT NULL,
    fotos JSON NOT NULL,
    policial_id INT NOT NULL,
    status ENUM('PENDENTE', 'APROVADO', 'REJEITADO') DEFAULT 'PENDENTE',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_tipo (tipo),
    INDEX idx_status (status),
    INDEX idx_policial (policial_id),
    INDEX idx_criado_em (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


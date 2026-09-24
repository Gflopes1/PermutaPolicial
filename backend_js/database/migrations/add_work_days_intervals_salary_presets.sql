-- ============================================
-- MÓDULO DE CALENDÁRIO + PRESETS + CÁLCULO DE SALÁRIO
-- ============================================

-- Tabela de Presets (templates de dias de trabalho)
CREATE TABLE IF NOT EXISTS presets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cor VARCHAR(7) NOT NULL DEFAULT '#2196F3', -- Cor em hexadecimal
    duracao DECIMAL(5, 2) NOT NULL DEFAULT 5.70, -- Duração em horas (padrão 5.7h)
    tipo ENUM('normal', 'plantao', 'folga', 'atestado', 'abatimento', 'ferias') NOT NULL DEFAULT 'normal',
    flag_abatimento BOOLEAN DEFAULT FALSE,
    etapa_rule_override VARCHAR(50) NULL, -- Regra customizada de etapas (ex: 'per_6h', 'per_8h', 'fixed_2')
    visibilidade ENUM('private', 'public') DEFAULT 'private',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_policial (policial_id),
    INDEX idx_tipo (tipo),
    INDEX idx_visibilidade (visibilidade)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Intervalos de Presets (horários específicos do preset)
CREATE TABLE IF NOT EXISTS preset_intervals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    preset_id INT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    ordem INT DEFAULT 0,
    FOREIGN KEY (preset_id) REFERENCES presets(id) ON DELETE CASCADE,
    INDEX idx_preset (preset_id),
    INDEX idx_ordem (ordem)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Dias de Trabalho
CREATE TABLE IF NOT EXISTS work_days (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    data DATE NOT NULL,
    preset_id INT NULL, -- Preset aplicado (opcional, pode ter intervals customizados)
    total_hours DECIMAL(5, 2) DEFAULT 0.00, -- Total de horas do dia (calculado)
    etapas INT DEFAULT 0, -- Número de etapas calculadas
    tipo ENUM('normal', 'plantao', 'folga', 'atestado', 'abatimento', 'ferias') DEFAULT 'normal',
    flag_abatimento BOOLEAN DEFAULT FALSE,
    observacoes TEXT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    FOREIGN KEY (preset_id) REFERENCES presets(id) ON DELETE SET NULL,
    UNIQUE KEY unique_policial_data (policial_id, data),
    INDEX idx_policial (policial_id),
    INDEX idx_data (data),
    INDEX idx_preset (preset_id),
    INDEX idx_tipo (tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Intervalos de Trabalho (horários específicos do dia)
CREATE TABLE IF NOT EXISTS work_intervals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    work_day_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL, -- Timestamp completo (data + hora) para suportar turnos que cruzam meia-noite
    end_time TIMESTAMP NOT NULL,
    duracao_minutos INT DEFAULT 0, -- Duração em minutos (calculado)
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (work_day_id) REFERENCES work_days(id) ON DELETE CASCADE,
    INDEX idx_work_day (work_day_id),
    INDEX idx_start_time (start_time),
    INDEX idx_end_time (end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Configurações de Salário (por usuário)
CREATE TABLE IF NOT EXISTS salary_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL UNIQUE,
    carga_horaria_dia DECIMAL(5, 2) DEFAULT 5.70, -- Carga horária diária padrão (5.7h)
    valor_hora_extra DECIMAL(10, 2) DEFAULT 44.00, -- Valor da hora extra (R$)
    vale_alimentacao DECIMAL(10, 2) DEFAULT 426.00, -- Valor do VA mensal (R$)
    dia_pagamento_va INT DEFAULT 20, -- Dia do mês que o VA é pago
    etapa_value DECIMAL(10, 2) DEFAULT 11.00, -- Valor de cada etapa (R$)
    previdencia_aliquota DECIMAL(5, 4) DEFAULT 0.1400, -- Alíquota de previdência (14% = 0.14)
    etapa_rule VARCHAR(50) DEFAULT 'per_6h', -- Regra padrão de etapas (1 etapa a cada 6h)
    abatimento_horas DECIMAL(5, 2) DEFAULT 5.70, -- Horas contabilizadas para abatimento/atestado
    salario_base DECIMAL(10, 2) DEFAULT 0.00, -- Salário base mensal (opcional, para cálculo de IR)
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    INDEX idx_policial (policial_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Resultados de Salário (cálculos mensais gerados)
CREATE TABLE IF NOT EXISTS salary_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    policial_id INT NOT NULL,
    mes INT NOT NULL, -- 1-12
    ano INT NOT NULL,
    total_horas DECIMAL(8, 2) DEFAULT 0.00, -- Total de horas trabalhadas no mês
    carga_horaria_mes DECIMAL(8, 2) DEFAULT 0.00, -- Carga horária esperada do mês
    horas_extras DECIMAL(8, 2) DEFAULT 0.00, -- Horas extras (total_horas - carga_horaria_mes)
    total_etapas INT DEFAULT 0, -- Total de etapas do mês
    valor_etapas DECIMAL(10, 2) DEFAULT 0.00, -- Valor total das etapas (etapas * etapa_value)
    vale_alimentacao DECIMAL(10, 2) DEFAULT 0.00, -- VA creditado (0 se em férias)
    valor_horas_extras DECIMAL(10, 2) DEFAULT 0.00, -- Valor das horas extras
    salario_bruto DECIMAL(10, 2) DEFAULT 0.00, -- Salário bruto (base + extras + etapas + VA)
    desconto_previdencia DECIMAL(10, 2) DEFAULT 0.00, -- Desconto de previdência
    desconto_irpf DECIMAL(10, 2) DEFAULT 0.00, -- Desconto de IRPF
    desconto_consignados DECIMAL(10, 2) DEFAULT 0.00, -- Descontos consignados (opcional)
    salario_liquido DECIMAL(10, 2) DEFAULT 0.00, -- Salário líquido final
    dias_trabalhados INT DEFAULT 0, -- Número de dias trabalhados no mês
    dias_ferias INT DEFAULT 0, -- Dias em férias no mês
    status ENUM('PENDENTE', 'PROCESSADO', 'CONFIRMADO') DEFAULT 'PENDENTE',
    processado_em TIMESTAMP NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE,
    UNIQUE KEY unique_policial_mes_ano (policial_id, mes, ano),
    INDEX idx_policial (policial_id),
    INDEX idx_mes_ano (mes, ano),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SEED: Presets Iniciais (serão criados para cada usuário ao criar settings)
-- ============================================
-- Nota: Os presets iniciais serão criados via código backend quando o usuário
-- criar suas configurações de salário pela primeira vez.



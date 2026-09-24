# 📅 Módulo de Calendário + Presets + Cálculo de Salário

## 📋 Visão Geral

Este módulo permite aos usuários gerenciar seus dias de trabalho, aplicar presets (templates) de horários, e calcular automaticamente salários mensais com base nas horas trabalhadas, etapas de alimentação, vale alimentação, e descontos (previdência, IRPF).

## 🗄️ Banco de Dados

### Migrations

Execute a migration para criar as tabelas necessárias:

```bash
mysql -u usuario -p nome_do_banco < database/migrations/add_work_days_intervals_salary_presets.sql
```

### Tabelas Criadas

- **work_days**: Dias de trabalho do usuário
- **work_intervals**: Intervalos de horário de cada dia
- **presets**: Templates de dias (6h, 8h, 12x36, etc.)
- **preset_intervals**: Intervalos de horário dos presets
- **salary_settings**: Configurações de salário por usuário
- **salary_results**: Resultados de cálculos mensais

## 🚀 Instalação

### Backend

1. Instale as dependências:
```bash
cd backend_js
npm install
```

2. Execute a migration SQL

3. Inicie o servidor:
```bash
npm start
# ou para desenvolvimento
npm run dev
```

### Frontend

1. Instale as dependências:
```bash
cd permuta_policial
flutter pub get
```

## 📡 Endpoints da API

### Work Days

- `GET /api/work/month?month=MM&year=YYYY` - Busca dias do mês
- `POST /api/work/day` - Cria/atualiza dia de trabalho
- `DELETE /api/work/day/:id` - Deleta dia de trabalho
- `POST /api/work/apply-preset` - Aplica preset em múltiplos dias
- `GET /api/work/stats?month=MM&year=YYYY` - Estatísticas do mês

### Presets

- `GET /api/presets` - Lista presets do usuário
- `GET /api/presets/:id` - Busca preset específico
- `POST /api/presets` - Cria novo preset
- `PUT /api/presets/:id` - Atualiza preset
- `DELETE /api/presets/:id` - Deleta preset

### Salary

- `GET /api/salary/settings` - Busca configurações de salário
- `PUT /api/salary/settings` - Atualiza configurações
- `GET /api/salary/preview?month=MM&year=YYYY` - Preview do cálculo
- `POST /api/salary/generate?month=MM&year=YYYY` - Gera resultado do mês
- `GET /api/salary/result?month=MM&year=YYYY` - Busca resultado
- `GET /api/salary/results?limit=12` - Lista resultados
- `GET /api/salary/export?month=MM&year=YYYY&format=pdf` - Exporta PDF

## 🔧 Configurações

### Variáveis de Ambiente

```env
ENABLE_SALARY_JOB=true  # Habilita job de processamento automático
```

### Job Cron

O job de processamento automático de salários executa diariamente às 02:00 (horário de Brasília) e processa o salário do mês anterior para todos os usuários no dia configurado de pagamento do VA.

## 📊 Cálculos

### Etapas de Alimentação

- Regra padrão: 1 etapa a cada 6 horas (floor)
- Configurável por preset ou globalmente
- Valor padrão: R$ 11,00 por etapa

### Vale Alimentação

- Valor fixo mensal (padrão: R$ 426,00)
- Não creditado em meses com férias
- Isento de IR

### Horas Extras

- Qualquer hora além da carga mensal
- Valor configurável por usuário (padrão: R$ 44,00/h)

### Descontos

- **Previdência**: Alíquota configurável (padrão: 14%)
- **IRPF**: Tabela progressiva simplificada
- **Consignados**: Valor configurável

## 🧪 Testes

### Unit Tests

```bash
npm test
```

### Integration Tests

```bash
npm test -- work.integration.test.js
```

## 📱 Uso no Frontend

### Navegação

```dart
Navigator.of(context).pushNamed(AppRoutes.calendar);
```

### Auto-Save

O sistema salva automaticamente após 1 segundo de inatividade ao editar um dia.

### Aplicar Preset em Massa

1. Selecione múltiplas datas
2. Clique em "Aplicar Preset"
3. Escolha o preset desejado
4. Confirme a ação

## 🔍 Troubleshooting

### Erro: "Token não encontrado"
- Verifique se o usuário está autenticado
- Confirme que o token está sendo enviado no header Authorization

### Erro: "Perfil não encontrado"
- Verifique se o usuário tem configurações de salário criadas
- O sistema cria automaticamente na primeira vez

### Preview não atualiza
- Verifique se há dias de trabalho cadastrados no mês
- Confirme que as configurações de salário estão corretas

## 📝 Notas

- Timezone padrão: America/Sao_Paulo
- Horas são arredondadas para 2 casas decimais
- Etapas sempre usam floor (arredondamento para baixo)
- VA e Etapas são isentas de IR



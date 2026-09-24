# Módulo Questões & Simulados

## 📋 Visão Geral

Módulo completo para sistema de questões e simulados, incluindo comentários, pagamentos e assinaturas premium.

## 🗄️ Banco de Dados

### Migrations

Execute a migration principal:

```bash
mysql -u seu_usuario -p nome_do_banco < backend_js/database/migrations/questions_simulados_tables.sql
```

Ou execute diretamente no MySQL Workbench/phpMyAdmin.

### Tabelas Criadas

- `questions` - Questões do sistema
- `question_tags` - Tags opcionais para questões
- `simulados` - Simulados criados pelos usuários
- `simulado_questions` - Relação entre simulados e questões
- `question_attempts` - Tentativas de resposta
- `users_stats` - Estatísticas dos usuários
- `question_comments` - Comentários em questões
- `comment_likes` - Likes em comentários
- `comment_reports` - Reports de comentários
- `comment_moderation_logs` - Logs de moderação
- `payment_webhook_logs` - Logs de webhooks de pagamento
- `payment_events_processed` - Eventos processados (idempotência)
- `payments` - Pagamentos registrados
- `user_subscriptions` - Assinaturas dos usuários

## 🌱 Seeds

Execute o seed para criar dados de teste:

```bash
cd backend_js
node database/seeds/questions_seed.js
```

Isso criará:
- 500 questões placeholder
- 20 comentários placeholder
- 2 usuários de teste (free e premium)

## 🔧 Configuração

### Variáveis de Ambiente

Adicione ao seu `.env`:

```env
# Webhooks de Pagamento
STRIPE_WEBHOOK_SECRET=whsec_...
MERCADOPAGO_WEBHOOK_SECRET=...
```

## 📡 Endpoints da API

### Questões

- `GET /api/questions` - Lista questões (filtros: assunto, tipo, page, per_page, search)
- `GET /api/questions/:id` - Busca questão por ID
- `POST /api/questions` - Cria questão (admin)
- `PUT /api/questions/:id` - Atualiza questão (admin)
- `DELETE /api/questions/:id` - Deleta questão (admin)

### Simulados

- `GET /api/simulado/create-options` - Opções de criação de simulado
- `POST /api/simulado` - Cria simulado
- `POST /api/simulado/:id/start` - Inicia simulado
- `GET /api/simulado/:id/question?ordem=1` - Busca questão atual
- `POST /api/simulado/:id/answer` - Submete resposta
- `GET /api/simulado/:id/result` - Resultado do simulado

### Comentários

- `GET /api/comments/questions/:id/comments` - Lista comentários de uma questão
- `GET /api/comments/:id/replies` - Lista respostas de um comentário
- `POST /api/comments/questions/:id/comments` - Cria comentário
- `PUT /api/comments/:id` - Atualiza comentário
- `DELETE /api/comments/:id` - Deleta comentário
- `POST /api/comments/:id/like` - Toggle like
- `POST /api/comments/:id/report` - Reporta comentário
- `POST /api/comments/:id/moderate` - Modera comentário (admin)

### Pagamentos

- `POST /api/payments/webhook/:provider?` - Webhook de pagamento
- `GET /api/payments/subscription` - Assinatura do usuário
- `GET /api/payments/webhook-logs` - Logs de webhook (admin)
- `POST /api/payments/webhook-logs/:id/retry` - Reprocessa webhook (admin)

## 🔐 Autenticação e Autorização

### Middlewares

- `authMiddleware` - Verifica JWT e anexa `req.user`
- `premiumMiddleware` - Verifica assinatura e anexa `req.user.is_premium`
- `premiumMiddleware.requirePremium` - Exige assinatura premium
- `adminMiddleware` - Exige permissões de admin

### Limites por Plano

- **Free**: 10 questões/dia, simulados até 10 questões
- **Premium**: Ilimitado, simulados até 120 questões

## ⏱️ Timer de Simulado

O timer é validado no servidor. O cliente deve enviar `server_start_time` ao submeter respostas. Se o tempo esgotar, o simulado é finalizado automaticamente.

## 💬 Sistema de Comentários

- Comentários com até 2 níveis (comentário → resposta)
- Rate limit: 5 comentários/minuto por usuário
- Auto-hide: comentários com >3 reports são ocultados automaticamente
- Moderação: admins podem hide/unhide/delete comentários

## 💳 Webhooks de Pagamento

### Suporte a Providers

- Stripe
- MercadoPago

### Fluxo

1. Webhook recebe payload raw
2. Valida assinatura (HMAC)
3. Verifica timestamp (janela de 300s)
4. Persiste log antes de processar
5. Verifica idempotência via `event_id`
6. Processa evento e atualiza assinaturas

### Eventos Suportados

- `payment.succeeded` / `payment.created` → Cria pagamento e assinatura
- `payment.failed` → Registra falha
- `charge.refunded` / `payment.refunded` → Reverte assinatura

## 🧪 Testes

### Executar Testes

```bash
cd backend_js
npm test
```

### Testes Unitários

- Seleção aleatória de questões
- Limites por plano
- Validação de timer server-side
- Lógica de moderação

### Testes de Integração

- Fluxo completo: criar → iniciar → responder → resultado
- Webhooks com assinaturas válidas/inválidas
- Idempotência de eventos

## 📱 Frontend (Flutter)

### Estrutura

```
permuta_policial/lib/features/questions/
├── screens/
│   ├── questions_list_screen.dart
│   ├── question_detail_screen.dart
│   ├── simulado_screen.dart
│   ├── simulado_result_screen.dart
│   └── admin_questions_screen.dart
├── widgets/
│   ├── question_card.dart
│   ├── comment_widget.dart
│   └── timer_widget.dart
├── providers/
│   └── questions_provider.dart
└── models/
    ├── question.dart
    ├── simulado.dart
    └── comment.dart
```

## 🚀 Próximos Passos

- Integrar geração de questões por IA
- Expandir banco para >10k questões
- Integrar provedores de pagamento reais
- Habilitar export PDF
- Sistema de ranking global
- Notificações push

## 📝 Notas

- Questões são placeholders (não conteúdo real)
- Sistema pronto para integração com webhooks reais
- Código modular e limpo, seguindo padrões do projeto



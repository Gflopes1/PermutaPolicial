# Auditoria Completa — Permuta Policial

> **Escopo:** `backend_js/src` + `permuta_policial/lib`  
> **Dimensões:** Desempenho · Segurança · UX · Arquitetura · Roadmap  
> **Data:** setembro/2026  
> **Metodologia:** Análise estática de código, mapeamento de rotas/módulos, revisão de padrões e integrações

---

## Sumário executivo

O **Permuta Policial** é uma plataforma madura e feature-rich (~235 arquivos backend, ~361 Dart) com arquitetura clara (Express modular + Flutter Provider/GoRouter). O produto cobre permutas, mapa, chat, editais, marketplace, estudos, calendário e admin — bem além de um MVP.

### Pontuação qualitativa

| Dimensão | Nota | Resumo |
|----------|------|--------|
| **Arquitetura** | 7/10 | Camadas consistentes; god classes e DI monolítica |
| **Segurança** | 6/10 | Bases sólidas (Helmet, bcrypt, Joi); gaps em CORS, Socket, token URL |
| **Desempenho** | 6/10 | Otimizações web recentes (-32% bundle); N+1, auth DB hit, providers no boot |
| **UX** | 7/10 | Mobile-first, skeletons, onboarding; a11y fraca, telas gigantes |
| **Testes** | 3/10 | Poucos testes backend; praticamente nenhum no Flutter |
| **Manutenibilidade** | 5/10 | Arquivos 1000+ linhas, features esqueleto, divergência dev/prod |

### Top 5 ações prioritárias

1. **Segurança:** Eliminar JWT na URL do OAuth; revalidar usuário no Socket.IO
2. **Desempenho:** Cache curto no auth middleware; corrigir N+1 em permutas legado
3. **UX:** Dividir dashboard/permutas/admin em widgets menores; adicionar Semantics
4. **Infra:** Adicionar `@aws-sdk/client-s3` ao `package.json`; unificar server/devserver
5. **Produto:** Implementar ou remover `assistant`, `novos_soldados`, `SyncService`

---

## 1. Mapa do sistema

### 1.1 Visão geral

```
                    ┌──────────────────────────────────────┐
                    │         PERMUTA POLICIAL             │
                    │  Plataforma de conexão de permutas   │
                    └──────────────────────────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          ▼                           ▼                           ▼
    ┌───────────┐              ┌───────────────┐           ┌─────────────┐
    │  CORE     │              │  COMUNICAÇÃO  │           │  FERRAMENTAS│
    │ Permutas  │              │ Chat, Fórum   │           │ Calendário  │
    │ Mapa      │              │ Notificações  │           │ Questões    │
    │ Editais   │              │ Push FCM      │           │ Marketplace │
    │ Verificação│             │               │           │ Consultoria │
    └───────────┘              └───────────────┘           └─────────────┘
          │                           │                           │
          └───────────────────────────┼───────────────────────────┘
                                      ▼
                              ┌───────────────┐
                              │    ADMIN      │
                              │ Analytics, OCR│
                              │ Moderação     │
                              └───────────────┘
```

### 1.2 Backend — 28 módulos ativos

| Módulo | Endpoints ~ | Complexidade | Criticidade |
|--------|-------------|--------------|-------------|
| auth | 12 | Média | Crítica |
| policiais | 4 | Baixa | Crítica |
| intencoes | 5 | Baixa | Crítica |
| permutas | 3 | Média | Alta |
| permutas-inteligentes | 5 | Alta | Crítica |
| mapa | 2 | Média | Alta |
| mapa-tatico | ~40 | Muito alta | Média |
| editais | ~15 | Alta | Alta |
| chat | ~10 | Média | Alta |
| forum | ~12 | Média | Média |
| marketplace | ~8 | Média | Média |
| questions/payments | ~20 | Alta | Média |
| work/salary | ~10 | Média | Baixa |
| analytics | ~20 | Média | Baixa |
| admin | ~30 | Alta | Crítica |
| verificacao-ocr | ~6 | Alta | Crítica |
| referral | ~8 | Média | Baixa |
| push/notificacoes | ~8 | Baixa | Média |
| demais | variado | Baixa | Baixa |

**Total estimado:** ~180+ endpoints HTTP + eventos Socket.IO

### 1.3 Frontend — 24 features

| Feature | Telas principais | Linhas críticas |
|---------|------------------|-----------------|
| dashboard | dashboard_screen_v3.dart | ~1145 |
| permutas | permutas_unificadas_screen.dart | ~1156 |
| admin | admin_provider.dart + admin_screen.dart | ~1079 + ~800 |
| mapa_tatico | mapa_tatico_screen.dart + widgets | ~600+ |
| auth | login, register_wizard, callback | ~500 |
| profile | profile, completar_perfil | ~400 |

---

## 2. Como as features funcionam

### 2.1 Fluxo de autenticação

```
[Landing/Login]
     │
     ├─ Email/senha → POST /api/auth/login → JWT → SecureStorage
     ├─ Google (web redirect / mobile native POST)
     ├─ Microsoft OAuth redirect
     └─ Registro wizard → email confirm → completar perfil
              │
              ▼
     [Auth middleware backend]
     JWT verify → SELECT policiais → status VERIFICADO?
              │
              ▼
     [GoRouter guards frontend]
     perfil incompleto? → /completar-perfil
     admin? → verifica embaixador/moderador
```

**Problema identificado:** OAuth retorna token em query string (`/auth/callback?token=...`) — exposto em history, logs, Referer.

### 2.2 Motor de permutas

**Legado** (`permutas.service.js`):
- Loop por intenção com query geográfica individual → **N+1 queries**
- Rate limit 20/min

**Inteligente** (`permutas-inteligentes.service.js`):
- Grafo em memória + cache MySQL
- Job cron com `p-limit` (concorrência 5)
- Matches: diretos, triangulares, ciclos N-way
- Admin pode rebuild manual

**Frontend:**
- Tela unificada com seções colapsáveis
- Grafo visual em canvas
- `PermutasLazyList` com paginação real

### 2.3 Mapa tático — fluxo colaborativo

```
Criar grupo → Convidar membros → Adicionar pontos (geo + fotos R2 criptografadas)
     │                                    │
     └─ Socket.IO tempo real ◄───────────┘
              │
              ├─ Comentários, denúncias, visitas
              ├─ Geocoding Nominatim (cache 24h)
              └─ Admin modera via /api/admin/mapa-tatico
```

### 2.4 Modelo premium

```
Request → premium.middleware (anexa flag)
       → usageLimit.middleware (daily_usage_limits table)
       → service valida limites
       → 403 PREMIUM_REQUIRED → ApiClient abre PremiumModal
```

Enforcement real no backend; modal é UX. Limite free configurável por feature.

---

## 3. Auditoria de desempenho

### 3.1 Backend

#### ✅ Pontos positivos

| Item | Detalhe |
|------|---------|
| Pool MySQL dimensionado | `MAX_DB_CONNECTIONS / workers - 2` |
| Rate limiting granular | Global 100/min + por rota (login 5/15min, matches 15-20/min) |
| Cache geocoding | MySQL 24h para Nominatim |
| Cache grafo PI | Repository dedicado |
| JSON limit seletivo | 100kb padrão; 15MB só import CSV editais |
| Streaming R2 | CDN proxy com pipe |
| Jobs desacoplados | Cron: match-alerts, salary, PI rebuild |
| `p-limit` | Concorrência controlada no job PI |

#### ⚠️ Problemas e impacto

| Problema | Arquivo | Impacto | Prioridade |
|----------|---------|---------|------------|
| **N+1 em matches legado** | `permutas.service.js` L48-57 | Latência O(n) por request | Alta |
| **Auth middleware = 1 SELECT/request** | `auth.middleware.js` | ~100% requests autenticadas | Alta |
| **Rate limit in-memory** | express-rate-limit, socket.js | Não compartilha entre workers Passenger | Média |
| **Performance logs só RAM** | `performance-logger.js` | Perdidos no restart | Baixa |
| **Rebuild grafo CPU-intensivo** | permutas-inteligentes | Picos em rebuild manual | Média |
| **Cleanup marketplace sync** | `cleanup_service.js` | `fs.unlinkSync` bloqueante | Baixa |
| **devserver JSON 15MB global** | `devserver.js` vs `server.js` | Divergência prod/dev | Média |

#### Recomendações backend

1. **Auth cache TTL curto (30-60s)** — Redis ou Map in-memory por worker com invalidação em update de perfil
2. **Batch queries no permutas legado** — substituir loop por JOIN ou query única com geo
3. **Rate limit compartilhado** — Redis store para express-rate-limit e socket rate
4. **Índices MySQL** — auditar queries de matches, mapa, analytics (EXPLAIN)
5. **Persistir performance logs** — flush periódico para MySQL ou serviço externo

### 3.2 Frontend

#### ✅ Pontos positivos

| Item | Detalhe |
|------|---------|
| Deferred routes | ~198 chunks `.part.js`; main.dart.js -32% (5.9MB → 3.8MB) |
| Dashboard entry lazy | `DashboardEntryScreen` → carrega v3 sob demanda |
| PermutasLazyList | ListView.builder + repaint boundaries |
| Auth resume throttle | 2 min debounce em `handleAppResume` |
| Boot otimizado | `runApp` imediato; deep links pós-frame |
| CachedNetworkImage | Mobile com cache nativo |

#### ⚠️ Problemas e impacto

| Problema | Arquivo | Impacto | Prioridade |
|----------|---------|---------|------------|
| **~40 providers no boot** | `main.dart` | TTFB mental + memória inicial | Alta |
| **God widgets** | dashboard, permutas, admin | Rebuilds amplos, manutenção difícil | Alta |
| **Selector quase ausente** | codebase-wide | Consumer amplo → rebuilds desnecessários | Média |
| **Imagens web sem disk cache** | `cached_network_image_wrapper.dart` | Re-download frequente | Média |
| **FutureBuilder por imagem** | cache busting async | Micro-jank | Baixa |
| **SyncService orphan** | registrado, não usado | Timer 30s desperdiçado | Baixa |
| **Dashboard init paralelo** | matches+chat+notif+referral | Waterfall no first paint | Média |
| **Grafo canvas + múltiplos fetch** | permutas_unificadas | Jank em devices fracos | Média |

#### Baseline web (set/2026)

```
Produção ANTES:  main.dart.js ~5,65 MB (raw)
Build DEPOIS:    main.dart.js ~3,81 MB (raw) — -32%
Chunks deferred: 198 arquivos .part.js
Monitorar:       [Permuta Boot] first frame em Xms
```

#### Recomendações frontend

1. **Lazy providers** — `ChangeNotifierProvider` só nas rotas que usam (Provider tree por feature)
2. **Split god classes** — dashboard em 5-8 widgets com `Selector`/`Consumer` granular
3. **Priorizar above-the-fold** — dashboard carrega matches primeiro; chat/referral deferred
4. **Cache imagens web** — service worker ou `cached_network_image` com strategy web
5. **Remover SyncService** do boot ou implementar de fato
6. **Isolates para grafo** — compute() para layout do grafo de permutas

---

## 4. Auditoria de segurança

### 4.1 Backend

#### ✅ Controles existentes

| Controle | Implementação |
|----------|---------------|
| Helmet + CSP | `server.js` L51-65 |
| Rate limiting | Global + por rota |
| Validação input | Celebrate/Joi na maioria dos endpoints |
| Senhas | bcrypt cost 10 |
| JWT | Verificação + reload do banco |
| Imagens | Magic bytes validation |
| Webhook MP | Assinatura obrigatória em produção |
| Secrets | Validados no boot (`config.validator.js`) |
| Erros | Stack oculto em produção |
| CDN | Allowlist de prefixos + anti path traversal |
| Criptografia | AES-256-GCM para campos sensíveis (mapa tático) |
| SQL | Parametrizado via mysql2 (sem concat user input) |

#### 🔴 Riscos altos

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| **CORS sem Origin aceito** | `server.js` L101-104 — qualquer request sem Origin passa | Restringir a webhooks conhecidos por path |
| **Socket.IO sem revalidação** | `socket.js` — só decodifica JWT, não checa status_verificacao | Reusar lógica do auth.middleware no handshake |
| **JWT 30 dias** | Janela grande se token vazado | Reduzir + refresh token ou revogação |
| **@aws-sdk/client-s3 ausente** | Usado em storage.service.js, não no package.json | Adicionar dependência explícita |

#### 🟡 Riscos médios

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| Analytics POST público | Spam/DoS em `/api/analytics/*` | Rate limit agressivo ou auth |
| Relatos públicos | POST `/api/problemas/relato` sem auth | CAPTCHA ou rate limit por IP |
| Uploads `/uploads` públicos | Arquivos servidos sem auth | Migrar tudo para R2 + signed URLs |
| CDN público | Key conhecida = acesso | Signed URLs com TTL |
| Webhook MP retorna 200 em erro | Perda de eventos de pagamento | Dead letter queue + alertas |
| Dynamic UPDATE keys | policiais.repository.js | Whitelist explícita no service |
| Push test endpoint | POST `/api/push/test` autenticado | Restringir a admin |

### 4.2 Frontend

#### ✅ Controles existentes

| Controle | Implementação |
|----------|---------------|
| Token storage | FlutterSecureStorage (mobile) |
| Logs gated | AppLogger só em ENV=dev |
| 401 handling | Logout automático TOKEN_EXPIRED |
| Admin guards | GoRouter + backend embaixador |
| POST body log | Truncado >10k, só dev |

#### 🔴 Riscos altos

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| **JWT na URL OAuth** | `/auth/callback?token=...` | POST com code one-time ou fragment (#) |
| **Chave PIX hardcoded** | `dashboard_screen_v3.dart` L51 | Mover para config backend |

#### 🟡 Riscos médios

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| Sem certificate pinning | http_client_factory_io.dart | Pin para prod (mobile) |
| SecureStorage web | Semântica localStorage-like | HttpOnly cookie ou shorter TTL |
| Token expirado inconsistente | ApiClient limpa storage, AuthProvider não | Sincronizar estado |
| Premium gate client-side | Modal por 403 | OK se backend enforce (verificar todos endpoints) |
| debugPrint em AuthProvider | Logs de isPremium etc. | Usar AppLogger gated |

### 4.3 Matriz de superfície de ataque

```
                    PÚBLICO          AUTENTICADO       ADMIN
                    ───────          ───────────       ─────
Permutas preview    ● rate limit
Analytics POST      ● sem auth ⚠
Relatos             ● sem auth ⚠
Mapa visitante      ●
CDN/R2              ● key guess ⚠
Auth login          ● brute force ✓ (5/15min)
Matches                              ●
Chat/Socket                          ● ⚠ (socket)
Mapa tático                          ●
Admin panel                                         ● ✓
Import CSV editais                                  ● 15MB
```

---

## 5. Auditoria de UX

### 5.1 Pontos fortes

| Área | Detalhe |
|------|---------|
| Design system | Tema escuro consistente (`app_theme.dart`, `app_styles.dart`) |
| Mobile-first | Auth card 500px max, dashboard responsivo |
| Loading states | Shimmer/skeleton em dashboard e permutas |
| Onboarding | `dashboard_onboarding.dart` guia novos usuários |
| Modo visitante | Mapa acessível sem cadastro — boa aquisição |
| Premium UX | Modal global interceptado, não quebra fluxo |
| Registro wizard | 3 steps claros com validação |
| Password strength | Meter visual no registro |
| Double-back exit | PopScope no dashboard |
| Web PWA | Update checker, push permission overlay |

### 5.2 Problemas de UX

| Problema | Impacto | Sugestão |
|----------|---------|----------|
| **Telas 1000+ linhas** | Cognitive overload, bugs difíceis | Split em tabs/seções lazy |
| **Fórum sem rota listagem** | Só embed no dashboard — difícil deep link | Rota `/forum` dedicada |
| **Acessibilidade zero** | Sem Semantics, fontSize fixo | WCAG 2.1 AA mínimo |
| **Sem breakpoints desktop** | Web em tela grande subutilizada | Layout 2-colunas em >900px |
| **Grafo permutas complexo** | Curva de aprendizado alta | Tooltip tour + legenda persistente |
| **Verificação OCR barreira** | Pode frustrar — falta feedback claro | Stepper com status em tempo real |
| **Erro de rede genérico** | Usuário não sabe se retry | Mensagens específicas + botão retry |
| **Mapa tático denso** | Muitos controles em mobile | Bottom sheet progressivo |

### 5.3 Jornadas críticas — avaliação

#### Jornada 1: Novo usuário → primeiro match

```
Landing ✓ → Registro ✓ → Confirmar email ✓ → Completar perfil ⚠ (pode confundir)
→ Verificação OCR ⚠ (barreira alta) → Dashboard ✓ → Ver matches ✓
```

**Fricção principal:** OCR antes de ver valor completo. Considerar preview limitado pós-perfil.

#### Jornada 2: Visitante → cadastro

```
Mapa visitante ✓ (bom!) → CTA cadastro ✓ → ...
```

**Boa aquisição.** Manter mapa visitante rápido.

#### Jornada 3: Match → contato

```
Ver match ✓ → Iniciar chat ✓ → Notificação push ⚠ (web depende permissão)
```

**Melhorar:** Indicador online, confirmação de entrega.

### 5.4 Acessibilidade — checklist

| Critério WCAG | Status | Ação |
|---------------|--------|------|
| Contraste texto | ⚠ Não auditado | Testar com Lighthouse |
| Semantics labels | ✗ Ausente | Adicionar em botões/ícones |
| Navegação teclado | ⚠ Parcial | Testar tab order |
| Tamanho fonte sistema | ✗ Fixo | Respeitar textScaleFactor |
| Animações | ✓ Landing respeita disableAnimations | Estender |
| Screen reader | ✗ Não testado | Audit com TalkBack/VoiceOver |

---

## 6. Dívida técnica consolidada

### 6.1 Backend

| Item | Severidade |
|------|------------|
| Pastas vazias (assistant, novos-soldados) | Média |
| Duplicação referral routes | Baixa |
| Dois entry points (server vs devserver) | Alta |
| console.log espalhado (~30 arquivos) | Média |
| premium.middleware não bloqueia | Baixa (by design) |
| Nome confuso "embaixador" | Baixa |
| Marketplace cleanup referencia /uploads local | Média |
| Poucos testes (4 arquivos) | Alta |
| package.json main incorreto | Baixa |
| passport.js legado coexistindo | Baixa |

### 6.2 Frontend

| Item | Severidade |
|------|------------|
| AdminProvider ~1079 linhas | Alta |
| DashboardScreenV3 ~1145 linhas | Alta |
| PermutasUnificadasScreen ~1156 linhas | Alta |
| SyncService orphan | Média |
| Features esqueleto (assistant, novos_soldados) | Média |
| DI monolítica main.dart 300+ linhas | Média |
| Inconsistência logging | Média |
| Token expirado não sync AuthProvider | Média |
| OAuth callback triplicado (splash+main+router) | Baixa |
| Drift schema v1 sem migrações | Baixa |

---

## 7. O que fazer — roadmap priorizado

### 🔴 Sprint 1 — Segurança crítica (1-2 semanas)

- [ ] OAuth: trocar token na URL por authorization code + POST exchange
- [ ] Socket.IO: revalidar `status_verificacao` no handshake
- [ ] Adicionar `@aws-sdk/client-s3` ao package.json
- [ ] Mover chave PIX para endpoint `/api/configuracoes/apoio`
- [ ] Restringir CORS sem Origin (whitelist por path: webhooks only)
- [ ] Sincronizar logout 401 entre ApiClient e AuthProvider

### 🟠 Sprint 2 — Desempenho (2-3 semanas)

- [ ] Cache TTL 60s no auth middleware (Redis ou in-memory)
- [ ] Corrigir N+1 em `permutas.service.js`
- [ ] Lazy providers por rota (reduzir boot)
- [ ] Split dashboard_screen_v3 em widgets com Selector
- [ ] Dashboard: fetch prioritário (matches first, rest deferred)
- [ ] Rate limit compartilhado (Redis) se multi-worker

### 🟡 Sprint 3 — UX e a11y (2-3 semanas)

- [ ] Adicionar Semantics em botões e ícones principais
- [ ] Rota `/forum` com listagem dedicada
- [ ] Tour do grafo de permutas (primeira visita)
- [ ] Layout desktop 2-colunas (>900px) no dashboard
- [ ] Mensagens de erro de rede específicas + retry
- [ ] Respeitar `textScaleFactor` do sistema

### 🟢 Sprint 4 — Qualidade e manutenção (contínuo)

- [ ] Unificar server.js e devserver.js (config única)
- [ ] Testes: auth, permutas-inteligentes, payments webhook
- [ ] Split AdminProvider em 4-5 providers menores
- [ ] Remover ou implementar SyncService, assistant, novos_soldados
- [ ] Migrar console.log → logger estruturado
- [ ] CI: lint + test + build Flutter web

---

## 8. O que mais podemos criar — ideias de produto

### 8.1 Alto valor para permutas (core)

| Feature | Descrição | Esforço |
|---------|-----------|---------|
| **Assistente IA de permuta** | Chatbot que explica regras, sugere intenções, resume matches | Médio — pastas já existem |
| **Alertas geográficos** | "Novo interessado em [cidade]" push/email | Baixo — infra existe |
| **Histórico de permutas concluídas** | Social proof + estatísticas por corporação | Baixo |
| **Compatibilidade por força/posto** | Regras de quem pode permutar com quem | Médio |
| **Calculadora de distância real** | Tempo de deslocamento entre lotações | Baixo — geo utils existem |
| **Modo "busca ativa"** | Usuário marca urgência, aparece destacado | Baixo |

### 8.2 Novos soldados (feature reservada)

| Feature | Descrição |
|---------|-----------|
| Hub novos soldados | Conteúdo, editais recentes, mentorias |
| Matching por turma/curso | Conectar colegas de formação |
| FAQ por corporação | Regras de permuta para recém-ingressos |

### 8.3 Comunicação e comunidade

| Feature | Descrição |
|---------|-----------|
| Grupos por município/força | WhatsApp-like dentro do app |
| Depoimentos verificados | Histórias de permutas bem-sucedidas |
| Webinars/live | Integração com calendário existente |

### 8.4 Ferramentas profissionais

| Feature | Descrição |
|---------|-----------|
| Checklist documental | O que preparar para permuta por corporação |
| Integração e-Social | Import automático de dados funcionais |
| Comparador de municípios | Custo de vida, salário, segurança |
| Modo offline completo | Ativar SyncService + Drift de fato |

### 8.5 Monetização e growth

| Feature | Descrição |
|---------|-----------|
| Premium tiers | Básico/Pro com features diferenciadas |
| Parceiros premium | Descontos em equipamentos (marketplace integrado) |
| API B2B para sindicatos | Acesso agregado anonimizado |
| Programa embaixadores regional | Referral com metas por estado |

### 8.6 Admin e operação

| Feature | Descrição |
|---------|-----------|
| Dashboard tempo real | WebSocket para métricas live |
| A/B testing | Feature flags via configuracoes |
| Moderação IA | Auto-flag conteúdo fórum/marketplace |
| Audit log completo | Quem fez o quê (LGPD compliance) |

---

## 9. Métricas recomendadas

### 9.1 Performance — monitorar

```
Backend:
  - p95 latency por endpoint (/matches, /permutas-inteligentes/matches)
  - Pool MySQL connections active/waiting
  - Job PI rebuild duration
  - Socket connections count

Frontend:
  - [Permuta Boot] first frame ms
  - main.dart.js transfer size (gzip)
  - Time to Interactive (web)
  - Crash-free sessions (mobile)
```

### 9.2 Segurança — monitorar

```
  - Failed login attempts / IP
  - 401/403 rate
  - Webhook MP failures
  - Rate limit hits
  - OCR rejection rate
```

### 9.3 UX — monitorar

```
  - Funnel: landing → registro → verificação → primeiro match
  - Time to first match view
  - Chat initiation rate
  - Premium conversion (403 → subscribe)
  - Bounce rate mapa visitante
```

---

## 10. Conclusão

O Permuta Policial é um produto **ambicioso e funcional**, com arquitetura backend sólida (camadas, validação, rate limit) e frontend otimizado para web (deferred loading com ganho mensurável de 32% no bundle).

Os maiores riscos estão em **segurança de tokens** (URL OAuth, Socket.IO) e **escalabilidade de performance** (auth DB hit, N+1, god classes). A UX é boa para mobile-first mas precisa de **acessibilidade** e **decomposição de telas** para escalar a equipe e reduzir bugs.

O roadmap sugerido prioriza segurança → performance → UX → qualidade, com ideias de produto alinhadas ao core (permutas) e às pastas já reservadas (assistant, novos_soldados).

---

## Anexos

### A. Arquivos centrais para revisão

**Backend:**
- `backend_js/src/server.js`
- `backend_js/src/api/index.js`
- `backend_js/src/core/middlewares/auth.middleware.js`
- `backend_js/src/modules/permutas-inteligentes/permutas-inteligentes.service.js`
- `backend_js/src/config/socket.js`

**Frontend:**
- `permuta_policial/lib/main.dart`
- `permuta_policial/lib/core/config/app_router.dart`
- `permuta_policial/lib/core/api/api_client.dart`
- `permuta_policial/lib/features/dashboard/screens/dashboard_screen_v3.dart`
- `permuta_policial/lib/features/permutas/screens/permutas_unificadas_screen.dart`

### B. Documento complementar

Ver [`O_QUE_E_E_O_QUE_FAZ.md`](./O_QUE_E_E_O_QUE_FAZ.md) para descrição funcional completa do sistema.

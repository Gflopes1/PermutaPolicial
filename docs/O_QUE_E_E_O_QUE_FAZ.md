# Permuta Policial — O que é e o que faz

> Documento de referência sobre a plataforma, seus módulos, fluxos e limites.  
> Última atualização: setembro/2026

---

## O que é

**Permuta Policial** é uma plataforma brasileira **privada e independente** que conecta agentes de segurança pública em serviço ativo interessados em trocar de lotação (permuta).

| Atributo | Valor |
|----------|-------|
| **Domínio** | https://br.permutapolicial.com.br |
| **Dev** | https://dev.br.permutapolicial.com.br |
| **Público-alvo** | PM, BM, PC, PRF, PF, Guarda Municipal |
| **Idioma** | Português (pt-BR) |
| **Vínculo governamental** | Nenhum |
| **Stack** | Flutter Web/Mobile + API Node.js/Express + MySQL |

A plataforma **não autoriza, não efetiva e não garante** permutas. Ela é uma camada tecnológica de **descoberta, conexão e comunicação** entre profissionais. A formalização depende das regras de cada corporação.

---

## Problema que resolve

Encontrar alguém com interesse compatível de permuta costuma depender de grupos informais, contatos pessoais e sorte. O Permuta Policial centraliza:

- Registro de intenções de lotação
- Motor de correspondências (diretas, triangulares, ciclos)
- Mapa de demanda por município
- Comunicação entre interessados
- Recursos auxiliares (editais, estudos, calendário, marketplace)

---

## Arquitetura do sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                        USUÁRIO FINAL                             │
│              (Web PWA / Android / iOS / Deep links)              │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                   permuta_policial/lib (Flutter)                 │
│  GoRouter · Provider · 26 repositórios · Socket.IO · Drift      │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS / WSS
┌────────────────────────────▼────────────────────────────────────┐
│                   backend_js/src (Node.js/Express)               │
│  ~28 módulos · JWT + OAuth · Celebrate/Joi · Socket.IO          │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   MySQL/MariaDB      Cloudflare R2         Serviços externos
   (dados principais) (fotos, mídia)        (FCM, Vision, MP, SMTP)
```

---

## Mapa do site e rotas principais

### Área pública (sem login)

| Rota | O que faz |
|------|-----------|
| `/` | Splash — decide destino (landing, dashboard, OAuth, referral) |
| `/landing` | Página de apresentação com CTA de cadastro ou modo visitante |
| `/auth`, `/auth/login`, `/auth/registrar` | Login, registro wizard, recuperação de senha |
| `/auth/callback` | Retorno OAuth com token JWT |
| `/mapa/visitante` | Mapa nacional de demanda (explorável sem conta) |
| `/r/:code` | Landing de indicação (referral) |
| `/edital/:id`, `/editais/:id/consulta` | Consulta pública de editais |

### Área autenticada (agente verificado)

| Rota | O que faz |
|------|-----------|
| `/dashboard` | Hub principal — matches, chat, marketplace, fórum, onboarding |
| `/permutas` | Matches clássicos + permutas inteligentes (grafo) |
| `/mapa` | Mapa nacional com detalhes por município |
| `/meus-dados` | Perfil, lotação, intenções, foto |
| `/completar-perfil` | Barreira até lotação/posto preenchidos |
| `/verificacao/documento` | OCR de documento policial |
| `/editais` | Hub de editais e simulador de vagas |
| `/marketplace` | Classificados entre agentes |
| `/chat/conversa/:id` | Mensagens 1:1 em tempo real |
| `/forum/topico/:id` | Tópicos do fórum |
| `/calendar` | Gestor de horas, presets, preview salarial |
| `/questions`, `/simulado`, `/practice` | Banco de questões e simulados |
| `/referral` | Programa de indicações |
| `/mapa-tatico/*` | Mapa operacional colaborativo |
| `/consultoria-juridica` | Diretório de advogados parceiros |
| `/premium/success` | Confirmação de assinatura |

### Área administrativa

| Rota | Quem acessa | O que faz |
|------|-------------|-----------|
| `/admin` | Embaixador ou moderador | Gestão de usuários, OCR, analytics, editais, parceiros |

---

## Módulos de negócio — o que cada um faz

### 1. Autenticação e identidade

**Backend:** `modules/auth`, `modules/policiais`, `modules/verificacao-ocr`  
**Frontend:** `features/auth`, `features/profile`, `features/verificacao`

- Cadastro com confirmação por e-mail (código 6 dígitos)
- Login e-mail/senha, Google OAuth, Microsoft OAuth
- JWT com expiração configurável (padrão 30 dias)
- Verificação de identidade via OCR (Google Vision) + revisão manual admin
- Perfil: lotação, posto, força, intenções, foto (R2)

**Fluxo típico:**
```
Cadastro → Confirmar e-mail → Completar perfil → Verificar documento → Dashboard
```

---

### 2. Permutas (core do produto)

**Backend:** `modules/intencoes`, `modules/permutas`, `modules/permutas-inteligentes`, `modules/match-alerts`  
**Frontend:** `features/permutas`, `features/profile`

| Motor | Descrição |
|-------|-----------|
| **Matches legado** | Correspondências por proximidade geográfica e critérios de intenção |
| **Permutas inteligentes** | Grafo de intenções — matches diretos, triangulares e ciclos N-way |
| **Alertas** | Job cron (08h/20h) notifica novos matches |
| **Preview público** | Simulação sem login (rate limit 12/min) |

O usuário define **para onde quer ir** (municípios/unidades). O sistema cruza intenções e sugere combinações possíveis.

---

### 3. Mapa nacional de demanda

**Backend:** `modules/mapa`  
**Frontend:** `features/mapa`

- Agregação anônima de intenções por município
- Modo visitante (sem login) para aquisição
- Detalhes por município exigem autenticação
- Opção de ocultar perfil no mapa

---

### 4. Mapa tático (feature avançada)

**Backend:** `modules/mapa-tatico`  
**Frontend:** `features/mapa_tatico`

- Grupos colaborativos com membros e convites
- Pontos georreferenciados com fotos (criptografadas em repouso)
- Comentários, denúncias, visitas, auditoria
- Geocoding via Nominatim (cache MySQL 24h)
- Tempo real via Socket.IO
- Perfil de suspeito (com disclaimer e rate limit)
- Admin embaixador pode moderar grupos

---

### 5. Comunicação

**Backend:** `modules/chat`, `modules/forum`, `modules/notificacoes`, `modules/push`  
**Frontend:** `features/chat`, `features/forum`, `features/notificacoes`

| Canal | Funcionalidade |
|-------|----------------|
| **Chat 1:1** | REST + Socket.IO, marcar lidas, compartilhar dados |
| **Fórum** | Categorias, tópicos, respostas, reações, moderação |
| **Notificações in-app** | Solicitações de contato, alertas |
| **Push FCM** | Web (Firebase) e mobile |

---

### 6. Editais de permuta

**Backend:** `modules/editais`  
**Frontend:** `features/editais`

- Hub de editais formais com importação CSV (admin)
- Consulta pública de vagas e participantes
- Simulador de posição na lista
- Acesso restrito: agente verificado + ID funcional na lista do edital
- Página de compartilhamento (`/share/edital/:id`)

---

### 7. Marketplace

**Backend:** `modules/marketplace`  
**Frontend:** `features/marketplace`

- Classificados de equipamentos entre agentes verificados
- Moderação admin (aprovar/rejeitar)
- Fotos no Cloudflare R2

---

### 8. Educação e concursos

**Backend:** `modules/questions`, payments  
**Frontend:** `features/questions`, `features/premium`

- Banco de questões com comentários
- Simulados e prática (limite diário free)
- Assinatura premium via MercadoPago
- Modal de upgrade interceptado globalmente no app

---

### 9. Ferramentas de trabalho

**Backend:** `modules/work`, presets, salary  
**Frontend:** `features/calendar`

- Calendário de escalas e horas
- Presets de turnos
- Cálculo e preview salarial
- Export PDF

---

### 10. Growth e parceiros

**Backend:** `modules/referral`, `modules/analytics`, `modules/parceiros`, `modules/consultoria-juridica`  
**Frontend:** `features/referral`, `features/consultoria_juridica`

- Programa de indicação com links `/r/:code` e ranking
- Analytics de page views e eventos (admin)
- Parceiros comerciais
- Consultoria jurídica — diretório de advogados

---

### 11. Administração

**Backend:** `modules/admin`  
**Frontend:** `features/admin`

- Estatísticas e analytics
- CRUD de policiais, verificações OCR
- Moderação marketplace, fórum, mapa tático
- Configurações globais, broadcast e-mail
- Importação de editais, rebuild do grafo PI
- Logs de performance e atividade

---

### 12. Módulos planejados (ainda sem código)

| Módulo | Status |
|--------|--------|
| `assistant` | Pastas vazias (backend + frontend) |
| `novos_soldados` | Pastas vazias (backend + frontend) |
| `SyncService` (offline) | Implementado mas não conectado ao app |

---

## Integrações externas

| Serviço | Uso |
|---------|-----|
| **MySQL/MariaDB** | Banco principal |
| **Cloudflare R2** | Armazenamento de fotos e mídia (API S3) |
| **Firebase FCM** | Push notifications |
| **Google OAuth + Vision** | Login e OCR de documentos |
| **Microsoft OAuth** | Login institucional |
| **MercadoPago** | Assinaturas premium |
| **Nominatim (OSM)** | Geocoding do mapa tático |
| **SMTP (Nodemailer)** | E-mails transacionais |
| **Cloudflare CDN** | Entrega de assets web |

---

## Modelo de acesso e permissões

```
Visitante
  └─ Mapa visitante, landing, preview permuta, editais públicos

Usuário cadastrado (e-mail confirmado)
  └─ Perfil incompleto → completar-perfil

Agente verificado (OCR aprovado)
  └─ Permutas, chat, marketplace, editais (se na lista), mapa tático

Premium
  └─ Simulados ilimitados, prática estendida, recursos gated

Moderador
  └─ Fórum, marketplace, verificações

Embaixador (admin master)
  └─ Tudo + broadcast, delete usuários, mapa tático admin, config global
```

---

## Fluxo de dados — permuta inteligente

```
1. Policial cadastra intenções (municípios/unidades desejados)
2. Job cron ou rebuild manual constrói grafo de intenções
3. Algoritmo encontra:
   - Matches diretos (A↔B)
   - Triangulares (A→B→C→A)
   - Ciclos N-way
4. Resultados cacheados em MySQL
5. App consulta GET /api/permutas-inteligentes/matches
6. Usuário inicia chat ou solicita contato
7. Negociação ocorre fora/fora da plataforma formalmente
```

---

## Limites e disclaimers importantes

1. **Não é órgão público** — não representa PM, PC, BM ou qualquer corporação
2. **Não garante permuta** — apenas sugere correspondências compatíveis
3. **Verificação ≠ autorização** — OCR confirma identidade, não direito de permutar
4. **Dados agregados no mapa** — podem estar desatualizados ou incompletos
5. **Mapa tático** — ferramenta colaborativa; conteúdo é responsabilidade dos usuários
6. **Premium** — enforcement real está no backend; modal no app é UX

---

## Estrutura de código

### Backend (`backend_js/src/`)

```
api/index.js          → Agregador de rotas /api/*
config/               → DB, Socket.IO, Passport OAuth
core/middlewares/     → auth, admin, premium, rate limit, errors
core/services/        → email, storage R2, cleanup
modules/              → 28 domínios (routes→controller→service→repository)
```

### Frontend (`permuta_policial/lib/`)

```
main.dart             → Bootstrap, DI Provider, MaterialApp.router
core/config/          → Router, guards, tema, app_config
core/api/             → ApiClient + 26 repositórios
core/services/        → Auth, socket, push, OCR, analytics
features/             → 24 módulos de negócio
shared/widgets/       → PremiumModal, banners web
```

---

## Glossário

| Termo | Significado na plataforma |
|-------|---------------------------|
| **Permuta** | Troca de lotação entre agentes (sujeita a regras institucionais) |
| **Intenção** | Município/unidade para onde o agente deseja ir |
| **Match** | Correspondência entre intenções compatíveis |
| **Agente verificado** | Passou pelo OCR e foi aprovado (ou admin) |
| **Embaixador** | Admin master da plataforma (não confundir com referral) |
| **Premium** | Assinante com limites estendidos |
| **Edital** | Processo formal de permuta com lista de participantes |
| **Mapa tático** | Mapa colaborativo operacional (grupos/pontos) |

---

## Contato e suporte

- Relatos de problemas: POST `/api/problemas/relato` (público)
- Notificações in-app para solicitações de contato
- Admin responde via painel `/admin`

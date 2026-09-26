# Melhorias de Segurança - Permuta Policial

Documento consolidado das melhorias de segurança implementadas na fase final do programa de API/produto.

## 🔐 Autenticação e Autorização

### Google ID Token (Native)

**Antes:**
- Verificação via endpoint HTTP `oauth2.googleapis.com/tokeninfo`
- Suscetível a ataques MITM
- Sem validação criptográfica adequada

**Depois:**
- Verificação JWKS com `google-auth-library`
- Validação criptográfica de assinatura
- Verificação de audience configurável (env)
- Arquivo: `backend_js/src/modules/auth/google-id-token.utils.js`

### JWT Access Tokens

**Antes:**
- Expiração padrão: 30 dias
- Sem mecanismo de refresh

**Depois:**
- Expiração padrão: **7 dias** (configurável via `JWT_EXPIRES_IN`)
- Requer re-login mais frequente
- Mitigação: mensagem clara de sessão expirada no app

**Limitação conhecida:** Sem refresh token rotation (requer tabela dedicada + endpoints).

## 🚦 Rate Limiting

### Endpoints de Autenticação

| Endpoint | Limite | Janela | Arquivo |
|----------|--------|--------|---------|
| `POST /auth/registrar` | 3 | 1 hora | `auth.routes.js` |
| `POST /auth/confirmar-email` | 5 | 15 min | `auth.routes.js` |
| `POST /auth/login` | 5 | 15 min | `auth.routes.js` (existente) |
| `POST /auth/solicitar-recuperacao` | 3 | 1 hora | `auth.routes.js` |
| `POST /auth/validar-codigo` | 3 | 1 hora | `auth.routes.js` |
| `POST /auth/redefinir-senha` | 3 | 1 hora | `auth.routes.js` |

### Uploads

| Endpoint | Limite | Janela | Arquivo |
|----------|--------|--------|---------|
| `POST /policiais/me/photo` | 10 | 1 hora | `policiais.routes.js` |

### Socket.IO

- Rate limit existente mantido: **30 mensagens/minuto por usuário**
- Implementado via `messageRateMap` em `config/socket.js`

## 🔌 WebSocket (Socket.IO)

### Validação de Payloads

**Antes:**
- Eventos aceitavam qualquer estrutura de dados
- Validação mínima de tipos

**Depois:**
- Validação estrita de:
  - Tipo do payload (`object`, `number`, `string`)
  - Campos obrigatórios (`conversaId`, `mensagem`)
  - Ranges válidos (`conversaId > 0`)
- Arquivo: `backend_js/src/config/socket.js`

### Authorization Checks

**Implementados em:**
- `nova_mensagem`: Verifica participação antes de enviar
- `typing`: Verifica participação antes de emitir
- `marcar_lidas`: Verifica participação antes de marcar
- `join_mapa_tatico_group`: Verifica membership no grupo

## 📊 Qualidade do Código

### Empty Catches

**Antes:**
```javascript
try {
  const [[notifs]] = await db.execute('...');
} catch (_) {} // silencioso
```

**Depois:**
```javascript
try {
  const [[notifs]] = await db.execute('...');
} catch (err) {
  console.error('Erro ao buscar notificações para analytics:', err.message);
}
```

Arquivo: `backend_js/src/modules/analytics/analytics.repository.js`

### Paginação

**Antes:**
```sql
SELECT * FROM marketplace WHERE policial_id = ? ORDER BY criado_em DESC
```

**Depois:**
```sql
SELECT * FROM marketplace WHERE policial_id = ? ORDER BY criado_em DESC LIMIT 100
```

Arquivo: `backend_js/src/modules/marketplace/marketplace.repository.js`

## 🔒 Resource-Level Authorization

### Padrão `/me`

Rotas críticas usam sufixo `/me` garantindo que o usuário só acessa seus próprios dados:

- `GET /policiais/me` - Perfil
- `PUT /policiais/me` - Atualização
- `POST /policiais/me/photo` - Upload foto
- `GET /intencoes/me` - Intenções
- `PUT /intencoes/me` - Atualização intenções
- `DELETE /intencoes/me` - Remoção intenções

Authorization via `req.user.id` (preenchido por `authMiddleware`).

## 🛡️ Uploads

### Validações Existentes (Mantidas)

- **Magic bytes**: Validação via `validateImageMagicBytes` (Sharp)
- **Tamanho**: Limite 8 MB por arquivo
- **Tipos**: JPEG, PNG, WEBP, HEIC/HEIF
- **Processamento**: Sharp para redimensionamento e otimização

### Limitações

- ✅ Validação de magic bytes (não apenas MIME)
- ✅ Limite de tamanho por arquivo
- ✅ Rate limiting por usuário (novo)
- ❌ Quota total de storage por usuário (não implementada)

## 🌐 Rotas Públicas

### Auditadas

| Rota | Status | PII? | Descrição |
|------|--------|------|-----------|
| `GET /permutas/stats-public` | ✅ Segura | Não | Apenas agregados (contagem de usuários, unidades) |
| `POST /permutas/preview-simulacao` | ✅ Rate-limited | Não | Simulação pré-login (12 req/min) |

Arquivo: `backend_js/src/modules/permutas/permutas.routes.js`

## 🚨 Riscos Residuais

| Risco | Mitigação Atual | Prioridade |
|-------|----------------|------------|
| JWT sem refresh | Re-login a cada 7 dias | Média |
| Quota de storage ausente | Rate limit 10 uploads/hora | Baixa |
| Rate limiters por IP | IPs compartilhados afetados | Baixa |
| Empty catches remanescentes | Identificados os críticos | Baixa |

## 📚 Referências

- [Google Auth Library](https://github.com/googleapis/google-auth-library-nodejs)
- [Express Rate Limit](https://github.com/express-rate-limit/express-rate-limit)
- [Socket.IO Security](https://socket.io/docs/v4/server-api/#event-connection)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)

## 🔄 Próximos Passos (Fora deste PR)

1. **Refresh Token Rotation**
   - Criar tabela `refresh_tokens`
   - Endpoints `POST /auth/refresh` e `POST /auth/logout`
   - Invalidar refresh tokens em redefinição de senha

2. **Quotas de Upload**
   - Contabilizar storage por usuário
   - Limite por tier (ex: 100 MB padrão, 500 MB embaixador)

3. **Observabilidade**
   - Logs estruturados de rate limit hits
   - Alertas de tentativas de ataque (brute force)
   - Dashboard de autenticação

4. **Auditoria Completa**
   - Revisão manual de todas as rotas
   - Penetration testing externo
   - Revisão de dependencies (npm audit)

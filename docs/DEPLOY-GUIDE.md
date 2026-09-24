# Guia de Deploy - Staging

Este guia detalha os passos para deploy da branch `cursor/security-ux-improvements-1b81` no ambiente de staging (dev.br.permutapolicial.com.br).

## 📋 Pré-requisitos

- VPS com acesso SSH
- Node.js 18+ instalado
- MySQL/MariaDB rodando
- PM2 instalado globalmente
- Flutter SDK (para build do app)

## 🔐 Variáveis de Ambiente

### Novas Variáveis (Obrigatórias)

Nenhuma variável nova foi adicionada. Todas as melhorias usam variáveis já existentes.

### Variáveis Críticas (Validar)

O sistema valida as seguintes variáveis no boot (`src/core/config/config.validator.js`):

```bash
# Banco de Dados
DB_HOST=localhost
DB_USER=permuta_user
DB_PASSWORD=<senha-segura>
DB_NAME=permuta_policial
DB_PORT=3306

# Segurança
JWT_SECRET=<256-bit-random-string>
SESSION_SECRET=<256-bit-random-string>
ENCRYPTION_MASTER_KEY=<256-bit-random-string>

# Google OAuth (já existentes - validação melhorada)
GOOGLE_CLIENT_ID=<client-id>.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=<android-client-id>.apps.googleusercontent.com
GOOGLE_SERVER_CLIENT_ID=<server-client-id>.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=<secret>

# Microsoft OAuth
MICROSOFT_CLIENT_ID=<client-id>
MICROSOFT_CLIENT_SECRET=<secret>
MICROSOFT_TENANT_ID=common

# Email
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=<email>
MAIL_PASS=<app-password>
MAIL_FROM=<email>

# URLs
BASE_URL=https://api.permutapolicial.com.br
FRONTEND_URL=https://dev.br.permutapolicial.com.br
NODE_ENV=development

# Storage (S3/R2)
AWS_BUCKET_NAME=<bucket>
AWS_ENDPOINT=<endpoint>
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=auto

# JWT (configuração atualizada)
JWT_EXPIRES_IN=7d  # Reduzido de 30d (padrão se omitido)
```

## 🚀 Passos de Deploy - Backend

### 1. Pull do Código

```bash
cd /path/to/backend_js
git fetch origin
git checkout cursor/security-ux-improvements-1b81
git pull origin cursor/security-ux-improvements-1b81
```

### 2. Instalar Dependências

```bash
npm install
```

**Nota:** A versão do `google-auth-library` já está no `package.json` (^9.15.1). Nenhuma dependência nova foi adicionada.

### 3. Validar Configuração

```bash
# Validar que .env está correto
node -e "require('dotenv').config(); require('./src/core/config/config.validator').validateConfig(); console.log('✅ Config OK')"
```

Se houver erros, o comando acima irá listar as variáveis faltantes.

### 4. Executar Testes (Opcional mas Recomendado)

```bash
npm test -- --testPathPattern="permutas.*test"
```

Saída esperada:
```
PASS src/modules/permutas/__tests__/permutas-metricas.test.js
PASS src/modules/permutas/__tests__/permutas-metrics.test.js
Test Suites: 2 passed, 2 total
Tests:       7 passed, 7 total
```

### 5. Restart da Aplicação

```bash
# Se usando PM2
pm2 restart permuta-api

# Ou se usando ecosystem file
pm2 restart ecosystem-completo.config.js --only permuta-api

# Verificar logs
pm2 logs permuta-api --lines 50
```

**Logs esperados:**
```
✅ Validação de configuração concluída
🔌 Banco de dados conectado
🔥 Socket.IO inicializado
🚀 Servidor rodando na porta 5000
```

### 6. Smoke Test

```bash
# Health check
curl https://api-dev.permutapolicial.com.br/health

# Teste de autenticação (rate limit)
for i in {1..6}; do
  curl -X POST https://api-dev.permutapolicial.com.br/api/auth/registrar \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com"}' \
    -w "\n%{http_code}\n"
done
# Esperado: primeiras 3 retornam 400 (validação), 4ª+ retorna 429 (rate limit)
```

## 📱 Deploy - Flutter Web

### 1. Pull do Código

```bash
cd /path/to/permuta_policial
git fetch origin
git checkout cursor/security-ux-improvements-1b81
git pull origin cursor/security-ux-improvements-1b81
```

### 2. Build

```bash
# Limpar build anterior
flutter clean

# Get dependencies
flutter pub get

# Build para web (produção)
flutter build web --release --web-renderer canvaskit
```

### 3. Deploy para Nginx

```bash
# Backup do build atual
sudo cp -r /var/www/permuta-web /var/www/permuta-web.backup.$(date +%Y%m%d%H%M)

# Copiar novo build
sudo rm -rf /var/www/permuta-web/*
sudo cp -r build/web/* /var/www/permuta-web/

# Restart do Nginx
sudo systemctl restart nginx
```

### 4. Smoke Test - Flutter

1. Abrir https://dev.br.permutapolicial.com.br
2. Verificar que dashboard carrega
3. Scroll até o final - verificar seção "Apoiar o Projeto"
4. Campo Minado e PIX devem estar agrupados (não mais na zona primária)

## 🔍 Validações Pós-Deploy

### Backend

| Teste | Comando | Esperado |
|-------|---------|----------|
| Health | `curl /health` | `200 OK` |
| Rate Limit Login | `curl -X POST /api/auth/login` (6x) | 429 na 6ª |
| Google Auth | Testar login Google no app | Sucesso |
| Socket.IO | Abrir chat no app | Mensagens funcionando |
| Métricas | Ver dashboard de matches | 3 ou 14 interessados corretos |

### Frontend

| Teste | Local | Esperado |
|-------|-------|----------|
| Dashboard Hero | Topo | Matches compatíveis em destaque |
| Campo Minado | Seção "Apoiar" (final) | Presente mas não primário |
| PIX | Seção "Apoiar" (final) | Presente mas não primário |
| Ferramentas | Meio | Grid de ferramentas visível |
| Responsivo | Redimensionar janela | Layout adapta (desktop/mobile) |

## 🐛 Troubleshooting

### Erro: "Variáveis de ambiente obrigatórias não configuradas"

**Solução:** Verificar `.env` e comparar com lista acima. Executar:
```bash
node -e "require('dotenv').config(); console.log(process.env.JWT_SECRET ? '✅ JWT_SECRET OK' : '❌ JWT_SECRET missing')"
```

### Erro: "Token do Google inválido"

**Solução:** Verificar que `GOOGLE_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID` e `GOOGLE_SERVER_CLIENT_ID` estão corretos no `.env`.

### Rate Limit Bloqueando Usuários Legítimos

**Solução temporária:** Aumentar limites em `auth.routes.js`:
```javascript
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5, // aumentar para 5 ou 10
  // ...
});
```

### Socket.IO Não Conecta

**Verificar logs do PM2:**
```bash
pm2 logs permuta-api | grep "Socket.IO"
```

**Se CORS error:** Adicionar origem em `config/socket.js`:
```javascript
const allowedOrigins = [
  'https://dev.br.permutapolicial.com.br', // já presente
  // adicionar outras se necessário
];
```

### Dashboard Flutter - Layout Quebrado

**Limpar cache do navegador:**
```bash
# No servidor
sudo rm -rf /var/www/permuta-web/*
sudo cp -r build/web/* /var/www/permuta-web/
sudo systemctl restart nginx
```

**No navegador:** Ctrl+Shift+R (hard refresh)

## 📊 Monitoramento Pós-Deploy

### Logs a Observar (Primeiras 24h)

```bash
# Rate limit hits
pm2 logs permuta-api | grep "429"

# Erros de autenticação
pm2 logs permuta-api | grep "Token do Google inválido"

# Erros de Socket.IO
pm2 logs permuta-api | grep "Socket.IO.*erro"

# Analytics (opcional)
mysql -u permuta_user -p permuta_policial -e "SELECT COUNT(*) FROM analytics_eventos WHERE evento_tipo='LOGIN' AND created_at > NOW() - INTERVAL 24 HOUR;"
```

### Métricas de Sucesso

- ✅ Taxa de login mantida ou aumentada
- ✅ Zero erros de validação JWT
- ✅ Rate limits ativados mas sem bloquear usuários legítimos
- ✅ Feedback positivo sobre novo layout do dashboard

## 🔄 Rollback (Se Necessário)

### Backend
```bash
cd /path/to/backend_js
git checkout main  # ou branch anterior
npm install
pm2 restart permuta-api
```

### Frontend
```bash
cd /path/to/permuta_policial
git checkout main
flutter clean
flutter pub get
flutter build web --release
sudo rm -rf /var/www/permuta-web/*
sudo cp -r build/web/* /var/www/permuta-web/
```

## 📞 Contato em Caso de Problemas

- **Logs completos:** `pm2 logs permuta-api --lines 200 > deploy-error.log`
- **Status do sistema:** `pm2 status`
- **Erros do Nginx:** `sudo tail -f /var/log/nginx/error.log`

---

## ✅ Checklist de Deploy

### Backend
- [ ] Pull do código
- [ ] `npm install` executado
- [ ] Variáveis de ambiente validadas
- [ ] PM2 restart executado
- [ ] Logs verificados (sem erros críticos)
- [ ] Health check OK
- [ ] Rate limit testado

### Frontend
- [ ] Pull do código
- [ ] `flutter pub get` executado
- [ ] `flutter build web` concluído
- [ ] Arquivos copiados para `/var/www/permuta-web/`
- [ ] Nginx restart executado
- [ ] Dashboard carrega corretamente
- [ ] Seção "Apoiar o Projeto" visível no final

### Validação Final
- [ ] Login Google funciona
- [ ] Chat (Socket.IO) funciona
- [ ] Métricas de matches corretas (3 vs 14)
- [ ] Campo Minado e PIX movidos para "Apoiar"
- [ ] Sem erros no console do navegador
- [ ] Sem erros nos logs do PM2

---

**Última atualização:** 24/09/2026  
**Branch:** `cursor/security-ux-improvements-1b81`  
**PR:** #1

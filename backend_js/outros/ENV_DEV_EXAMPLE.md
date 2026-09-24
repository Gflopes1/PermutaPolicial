# Arquivo de Configuração - Ambiente DEV/HOMOLOGAÇÃO

Copie este conteúdo para criar um arquivo `.env.dev` na raiz do projeto `backend_js/`.

```env
# ============================================
# ARQUIVO DE CONFIGURAÇÃO - AMBIENTE DEV/HOMOLOGAÇÃO
# ============================================

# Ambiente
NODE_ENV=development
BASE_URL=https://dev.br.permutapolicial.com.br

# Servidor
PORT=3001
HOST=127.0.0.1

# Banco de Dados MySQL
DB_HOST=localhost
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
DB_NAME=permutapolicial_permutaDB
DB_PORT=3306

# JWT
JWT_SECRET=sua-chave-secreta-jwt-para-dev-altere-em-producao
JWT_EXPIRES_IN=7d

# Sessão
SESSION_SECRET=dev-secret-key-change-in-production

# OAuth Google
GOOGLE_CLIENT_ID=seu-google-client-id-dev
GOOGLE_CLIENT_SECRET=seu-google-client-secret-dev

# OAuth Microsoft
MICROSOFT_CLIENT_ID=seu-microsoft-client-id-dev
MICROSOFT_CLIENT_SECRET=seu-microsoft-client-secret-dev
# Opcional: Chave específica para criptografia de cookies (usa SESSION_SECRET se não fornecido)
# MICROSOFT_COOKIE_ENCRYPTION_KEY=sua-chave-para-criptografia-de-cookies

# Frontend URL (para CORS)
FRONTEND_URL=https://dev.br.permutapolicial.com.br

# Jobs e Processamento
ENABLE_SALARY_JOB=false

# MercadoPago (Pagamentos)
MERCADOPAGO_ACCESS_TOKEN=seu-mercadopago-access-token-dev
MERCADOPAGO_WEBHOOK_SECRET=seu-webhook-secret-dev
```

## Como usar:

1. Copie o conteúdo acima
2. Crie um arquivo `.env.dev` em `backend_js/.env.dev`
3. Configure as variáveis com os valores corretos do seu ambiente de desenvolvimento
4. Execute o servidor dev com: `node devserver.js`

## Nota:

- O arquivo `.env.dev` não deve ser commitado no git (já está no .gitignore)
- Use valores diferentes de produção para evitar conflitos
- O servidor dev roda na porta 3001 por padrão


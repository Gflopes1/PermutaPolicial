# Configuração Nginx para Landing Pages

## Passo 1: Configurar o Next.js para rodar na porta 3001

O backend já está usando a porta 3000, então o Next.js deve rodar na porta 3001.

### Opção A: Modificar o package.json (Recomendado - JÁ FEITO)

O `package.json` já foi configurado para usar a porta 3001:

```json
"scripts": {
  "dev": "next dev -p 3001",
  "build": "next build",
  "start": "next start -p 3001",
  "start:prod": "next start -p 3001",
  "lint": "next lint"
}
```

### Opção B: Usar variável de ambiente no sistema

Crie um arquivo `.env` na pasta `landings/`:

```
PORT=3001
```

Ou exporte a variável antes de iniciar:

```bash
export PORT=3001
npm start
```

## Passo 2: Adicionar configuração no Nginx

Adicione o seguinte bloco **ANTES** da location `/api/` no seu arquivo de configuração do nginx:

```nginx
# Proxy para as landing pages Next.js (porta 3001)
location /app/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # Headers importantes para Next.js
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
}

# Proxy para arquivos estáticos do Next.js (_next/static)
location /_next/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Cache para arquivos estáticos
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Passo 3: Ordem das locations no Nginx

A ordem das `location` blocks é importante! A configuração deve ficar assim:

```nginx
server {
    # ... outras configurações ...
    
    # 1. Primeiro: Landing Pages Next.js
    location /app/ {
        # ... configuração acima ...
    }
    
    location /_next/ {
        # ... configuração acima ...
    }
    
    # 2. Depois: API Backend
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        # ... sua configuração atual ...
    }
    
    # 3. Por último: Arquivos estáticos do Flutter
    # ... resto da configuração ...
}
```

## Passo 4: Build e Deploy do Next.js

⚠️ **IMPORTANTE**: O Next.js precisa de um build de produção antes de iniciar!

1. **Instalar dependências e fazer build:**
```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm install
npm run build  # ⚠️ OBRIGATÓRIO antes de iniciar!
```

2. **Iniciar o servidor Next.js (usando PM2 recomendado):**

```bash
# Instalar PM2 globalmente (se ainda não tiver)
npm install -g pm2

# Iniciar o Next.js com PM2
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
pm2 start npm --name "landings-nextjs" -- start

# Salvar configuração do PM2
pm2 save

# Configurar PM2 para iniciar automaticamente no boot
pm2 startup
```

Ou manualmente:

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm start
```

Ou usando o script específico:

```bash
npm run start:prod
```

## Passo 5: Recarregar Nginx

Após adicionar a configuração:

```bash
# Testar configuração
nginx -t

# Se estiver OK, recarregar
nginx -s reload

# Ou reiniciar
systemctl reload nginx
```

## Verificação

Após configurar, teste as URLs:

- `https://br.permutapolicial.com.br/app/pm`
- `https://br.permutapolicial.com.br/app/bm`
- `https://br.permutapolicial.com.br/app/pc`
- etc.

## Troubleshooting

### Erro 502 Bad Gateway
- Verifique se o Next.js está rodando na porta 3001
- Verifique os logs: `pm2 logs landings-nextjs` ou `tail -f /www/wwwlogs/br.permutapolicial.com.br.error.log`

### Página não carrega
- Verifique se o build foi feito corretamente: `npm run build`
- Verifique se os arquivos estáticos `/_next/` estão sendo servidos

### Conflito de rotas
- Certifique-se de que a location `/app/` está ANTES da location `/api/` no nginx


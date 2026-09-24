# 🚀 Implementação Rápida - Landing Pages no Nginx

## Resumo
As landing pages do Next.js devem ser servidas através do nginx fazendo proxy reverso para a porta 3001.

## ⚡ Passos Rápidos

### 1. Adicionar configuração no Nginx

Edite o arquivo de configuração do nginx (geralmente em):
```
/www/server/panel/vhost/nginx/br.permutapolicial.com.br.conf
```

**Adicione ANTES da linha `location /api/`:**

```nginx
# Landing Pages Next.js
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
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
}

location /_next/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 2. Build do Next.js

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm install
npm run build
```

### 3. Iniciar o servidor Next.js com PM2

```bash
# Usando o arquivo de configuração PM2
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
pm2 start ecosystem.config.js

# Salvar e configurar auto-start
pm2 save
pm2 startup
```

### 4. Testar e recarregar Nginx

```bash
# Testar configuração
nginx -t

# Se OK, recarregar
nginx -s reload
# ou
systemctl reload nginx
```

### 5. Verificar

Acesse no navegador:
- https://br.permutapolicial.com.br/app/pm
- https://br.permutapolicial.com.br/app/bm

## 📋 Checklist

- [ ] Configuração `/app/` adicionada no nginx (ANTES de `/api/`)
- [ ] Configuração `/_next/` adicionada no nginx
- [ ] Next.js buildado (`npm run build`)
- [ ] Next.js rodando na porta 3001 (verificar com `pm2 list`)
- [ ] Nginx recarregado
- [ ] URLs testadas no navegador

## 🔍 Troubleshooting

**Erro 502:**
```bash
# Verificar se Next.js está rodando
pm2 list
pm2 logs landings-nextjs

# Verificar porta
netstat -tulpn | grep 3001
```

**Página não carrega:**
```bash
# Verificar logs do nginx
tail -f /www/wwwlogs/br.permutapolicial.com.br.error.log

# Verificar se o build foi feito
ls -la /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings/.next
```

## 📝 Ordem das Locations no Nginx

A ordem é importante! Deve ser:

1. `/app/` (Landing Pages)
2. `/_next/` (Arquivos estáticos Next.js)
3. `/api/` (Backend)
4. Outras locations...


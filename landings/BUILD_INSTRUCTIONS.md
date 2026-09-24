# 🏗️ Instruções de Build - Landing Pages

## ⚠️ Erro Comum

Se você ver este erro:
```
Error: Could not find a production build in the '.next' directory. 
Try building your app with 'next build' before starting the production server.
```

**Solução**: Você precisa fazer o build antes de iniciar o servidor!

## 📋 Passos para Build e Deploy

### 1. Instalar Dependências (se ainda não fez)

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm install
```

### 2. Fazer o Build

```bash
npm run build
```

Isso vai criar a pasta `.next` com os arquivos de produção.

### 3. Iniciar o Servidor

```bash
npm start
# ou
npm run start:prod
```

### 4. Ou Fazer Build + Start em um comando

```bash
npm run build:start
```

## 🔄 Atualização de Código

Sempre que você atualizar o código, precisa fazer o build novamente:

```bash
# 1. Parar o PM2
pm2 stop landings-nextjs

# 2. Fazer build
npm run build

# 3. Reiniciar PM2
pm2 restart landings-nextjs
```

## 🚀 Com PM2

### Primeira Vez

```bash
# 1. Build
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm install
npm run build

# 2. Iniciar com PM2
pm2 start ecosystem.config.js

# 3. Salvar e configurar auto-start
pm2 save
pm2 startup
```

### Atualização

```bash
# 1. Parar
pm2 stop landings-nextjs

# 2. Build
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm run build

# 3. Reiniciar
pm2 restart landings-nextjs
```

## 📝 Scripts Disponíveis

- `npm run dev` - Modo desenvolvimento (com hot-reload)
- `npm run build` - Build de produção
- `npm start` - Iniciar servidor de produção (requer build)
- `npm run start:prod` - Mesmo que `npm start`
- `npm run build:start` - Build + Start em um comando
- `npm run lint` - Verificar código com ESLint

## ⚡ Solução Rápida

Se você só quer iniciar rapidamente:

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm run build:start
```

## 🔍 Verificar se Build Foi Feito

```bash
# Verificar se a pasta .next existe
ls -la .next

# Se não existir, fazer build
npm run build
```

## 🚨 Troubleshooting

### Build Falha

```bash
# Limpar cache e node_modules
rm -rf .next node_modules
npm install
npm run build
```

### Porta 3001 já em uso

```bash
# Verificar o que está usando a porta
netstat -tulpn | grep 3001

# Parar o processo ou mudar a porta no package.json
```

### Erros de TypeScript/ESLint

Veja `FIX_BUILD.md` para instruções de como desabilitar temporariamente.


# ⚡ Solução Rápida - Erro de Build

## 🚨 Erro Atual

```
Error: Could not find a production build in the '.next' directory.
```

## ✅ Solução Imediata

Execute estes comandos no servidor:

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings

# 1. Parar o PM2 (se estiver rodando)
pm2 stop landings-nextjs

# 2. Fazer o build
npm run build

# 3. Reiniciar o PM2
pm2 restart landings-nextjs
```

## 📋 Passo a Passo Completo

### 1. Parar o processo atual

```bash
pm2 stop landings-nextjs
```

### 2. Navegar para a pasta

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
```

### 3. Instalar dependências (se necessário)

```bash
npm install
```

### 4. Fazer o build

```bash
npm run build
```

Aguarde até ver:
```
✓ Compiled successfully
```

### 5. Iniciar com PM2

```bash
pm2 restart landings-nextjs
```

Ou se não estiver no PM2 ainda:

```bash
pm2 start ecosystem.config.js
pm2 save
```

### 6. Verificar se está funcionando

```bash
pm2 list
pm2 logs landings-nextjs
```

## 🔄 Script Automatizado

Você também pode usar o script que criei:

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
chmod +x PM2_BUILD_SCRIPT.sh
./PM2_BUILD_SCRIPT.sh
```

## ⚠️ Importante

**Sempre que você atualizar o código, precisa fazer o build novamente:**

```bash
pm2 stop landings-nextjs
npm run build
pm2 restart landings-nextjs
```

## 📚 Mais Informações

Veja `BUILD_INSTRUCTIONS.md` para documentação completa.


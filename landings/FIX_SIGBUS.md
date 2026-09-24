# 🔧 Solução para Erro SIGBUS no Build

## 🚨 Erro

```
Next.js build worker exited with code: null and signal: SIGBUS
```

**SIGBUS** geralmente indica **falta de memória** durante o build do Next.js.

## ✅ Soluções

### 1. Aumentar Memória Disponível (Recomendado)

#### Opção A: Aumentar Swap

```bash
# Verificar swap atual
free -h

# Criar arquivo de swap (2GB)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Tornar permanente
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verificar
free -h
```

#### Opção B: Limpar Memória Antes do Build

```bash
# Limpar cache do sistema
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Limpar node_modules e .next
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
rm -rf .next node_modules/.cache
```

### 2. Build com Limite de Memória do Node.js

```bash
# Limitar memória do Node.js (ajuste conforme necessário)
NODE_OPTIONS="--max-old-space-size=2048" npm run build
```

Ou adicione ao `package.json`:

```json
"scripts": {
  "build": "NODE_OPTIONS='--max-old-space-size=2048' next build"
}
```

### 3. Build em Etapas

```bash
# 1. Limpar tudo
rm -rf .next node_modules/.cache

# 2. Build com menos workers
NODE_OPTIONS="--max-old-space-size=2048" npm run build
```

### 4. Desabilitar Otimizações Temporariamente

Edite `next.config.js` e adicione:

```javascript
module.exports = {
  // ... outras configurações
  swcMinify: false, // Desabilitar minificação SWC
  experimental: {
    webpackBuildWorker: false,
  },
}
```

### 5. Build sem Standalone (se não precisar)

Se não precisar do modo standalone, remova do `next.config.js`:

```javascript
// Remover esta linha:
output: 'standalone',
```

## 🔄 Script de Build Otimizado

Crie um script `build-safe.sh`:

```bash
#!/bin/bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings

# Limpar cache
rm -rf .next node_modules/.cache

# Limpar memória do sistema
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1

# Build com limite de memória
NODE_OPTIONS="--max-old-space-size=2048" npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
else
    echo "❌ Erro no build. Tente aumentar a memória ou swap."
    exit 1
fi
```

Torne executável:

```bash
chmod +x build-safe.sh
./build-safe.sh
```

## 📊 Verificar Recursos do Sistema

```bash
# Ver memória disponível
free -h

# Ver uso de memória em tempo real
top

# Ver processos Node.js
ps aux | grep node
```

## 🎯 Solução Rápida

Execute estes comandos:

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings

# 1. Limpar cache
rm -rf .next node_modules/.cache

# 2. Build com limite de memória
NODE_OPTIONS="--max-old-space-size=2048" npm run build
```

## ⚠️ Se Ainda Falhar

1. **Aumente o swap** (veja Opção A acima)
2. **Pare outros processos** que estejam usando memória
3. **Build em servidor com mais memória** (se possível)
4. **Use build incremental** (não limpe .next entre builds)

## 📝 Notas

- O Next.js precisa de pelo menos **2GB de RAM** para builds grandes
- Com swap, você pode usar mais memória (mais lento, mas funciona)
- O modo `standalone` usa mais memória durante o build


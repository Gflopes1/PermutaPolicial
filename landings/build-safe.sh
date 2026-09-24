#!/bin/bash
# Script de build seguro com limpeza de memória e cache
# Uso: ./build-safe.sh

cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings

echo "🧹 Limpando cache..."
rm -rf .next node_modules/.cache

echo "💾 Limpando memória do sistema..."
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1

echo "🏗️ Fazendo build com limite de memória (2GB)..."
NODE_OPTIONS="--max-old-space-size=2048" npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    exit 0
else
    echo "❌ Erro no build. Tente aumentar a memória ou swap."
    echo "📖 Veja FIX_SIGBUS.md para mais soluções"
    exit 1
fi


#!/bin/bash
# Script para fazer build e iniciar o Next.js com PM2
# Uso: ./PM2_BUILD_SCRIPT.sh

cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings

echo "📦 Instalando dependências..."
npm install

echo "🏗️ Fazendo build de produção..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    
    echo "🚀 Iniciando com PM2..."
    pm2 restart landings-nextjs || pm2 start ecosystem.config.js
    
    echo "💾 Salvando configuração PM2..."
    pm2 save
    
    echo "✅ Pronto! Verifique com: pm2 list"
else
    echo "❌ Erro no build! Verifique os logs acima."
    exit 1
fi


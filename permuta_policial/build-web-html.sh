#!/bin/bash

echo "🔨 Building Flutter Web com renderização HTML..."
echo ""

# Gera web/version.json + meta tags em index.html (detecção de nova build no cliente)
echo "🔄 Atualizando versão (index.html + version.json)..."
if command -v node &> /dev/null; then
  node update-version.js
else
  echo "⚠️  Node.js não encontrado. Pulando atualização de versão."
  echo "   Execute manualmente: node update-version.js"
fi

# Limpar build anterior
echo "🧹 Limpando build anterior..."
flutter clean

# Obter dependências
echo "📦 Obtendo dependências..."
flutter pub get

# Build com renderização HTML e ambiente de produção
echo "🚀 Fazendo build com renderização HTML (PRODUÇÃO)..."
flutter build web --release --dart-define=ENV=prod --pwa-strategy=none

echo ""
echo "🔄 Pós-build: fingerprint main.dart.js + cache bust flutter_bootstrap..."
if command -v node &> /dev/null; then
  node update-version.js --post-build
else
  echo "⚠️  Node.js não encontrado. Rode: node update-version.js --post-build"
fi

echo ""
if [ ! -f "build/web/version.json" ]; then
  echo "⚠️  build/web/version.json ausente — confira se node update-version.js rodou."
else
  echo "📌 version.json em build/web/version.json"
fi

echo ""
echo "✅ Build concluído com sucesso!"
echo "📁 Arquivos gerados em: build/web/"
echo ""
echo "📋 Próximos passos:"
echo "   1. Copiar arquivos para o servidor:"
echo "      cp -r build/web/* /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/"
echo ""
echo "   2. Verificar se o Nginx está configurado corretamente"
echo "   3. Testar o site em: https://br.permutapolicial.com.br"
echo ""


# 🔍 Diagnóstico: Frontend Production Chamando Backend Development

## ❌ Problema Identificado

O frontend em produção (`https://br.permutapolicial.com.br`) está chamando a API de desenvolvimento (`https://dev.br.permutapolicial.com.br`).

## 🔎 Causa Raiz

### 1. Script de Build Não Define ENV=prod

Os scripts `build-web-html.sh` e `build-web-html.bat` **não estão passando** `--dart-define=ENV=prod` no comando de build.

**Antes:**
```bash
flutter build web --web-renderer html --release --base-href /
```

**Depois (corrigido):**
```bash
flutter build web --web-renderer html --release --base-href / --dart-define=ENV=prod
```

### 2. Lógica de Detecção de Ambiente com Fallback Problemático

No arquivo `app_config.dart`, a lógica de detecção tem esta ordem:

1. ✅ Tenta `String.fromEnvironment('ENV')` - **MAS NÃO ESTÁ SENDO DEFINIDO NO BUILD**
2. ⚠️ Tenta detectar pelo hostname - **PODE FALHAR SE HOUVER ERRO**
3. ❌ Fallback usa `kDebugMode` - **PODE SER TRUE MESMO EM RELEASE**

Se a detecção pelo hostname falhar (ex: erro ao acessar `web.window.location.hostname`), cai no fallback que pode retornar `development` mesmo em produção.

## ✅ Correções Aplicadas

### 1. Scripts de Build Atualizados

- ✅ `build-web-html.sh` - Adicionado `--dart-define=ENV=prod`
- ✅ `build-web-html.bat` - Adicionado `--dart-define=ENV=prod`

### 2. Lógica de Detecção Melhorada

- ✅ Melhor tratamento de erros na detecção por hostname
- ✅ Fallback usa `kReleaseMode` ao invés de `kDebugMode` (mais confiável)
- ✅ Detecção explícita do domínio de produção
- ✅ Produção como padrão quando não conseguir detectar

## 🚀 Solução Imediata

### Opção 1: Rebuild com Script Corrigido (Recomendado)

```bash
cd permuta_policial
./build-web-html.sh  # Linux/Mac
# ou
build-web-html.bat   # Windows
```

### Opção 2: Build Manual com ENV=prod

```bash
cd permuta_policial
flutter clean
flutter pub get
flutter build web --web-renderer html --release --base-href / --dart-define=ENV=prod
```

### Opção 3: Build Manual Simples (usa detecção por hostname)

Se não quiser usar `--dart-define`, a nova lógica de detecção por hostname deve funcionar, mas **não é recomendado** para produção.

## 📋 Verificação

Após o rebuild, verifique no console do navegador:

```
═══════════════════════════════════════
🔧 CONFIGURAÇÃO DO AMBIENTE
📍 Ambiente: production
📍 API Base URL: https://br.permutapolicial.com.br
📍 Socket Base URL: https://br.permutapolicial.com.br
═══════════════════════════════════════
```

Se ainda mostrar `development`, o build não foi feito corretamente.

## ⚠️ Importante

1. **Sempre use `--dart-define=ENV=prod` em builds de produção**
2. **Não confie apenas na detecção por hostname** - ela é um fallback
3. **Teste após o rebuild** - limpe o cache do navegador se necessário

## 🔄 Próximos Passos

1. ✅ Fazer rebuild com o script corrigido
2. ✅ Deploy dos arquivos gerados
3. ✅ Testar em produção
4. ✅ Verificar logs do console para confirmar ambiente correto


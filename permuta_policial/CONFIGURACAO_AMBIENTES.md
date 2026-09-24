# Configuração de Ambientes - Frontend Flutter

## 📋 Visão Geral

O frontend agora suporta configuração de ambientes (desenvolvimento e produção) através do arquivo `app_config.dart`.

## 🔧 Como Funciona

### Arquivo de Configuração

Criado: `lib/core/config/app_config.dart`

Este arquivo define:
- **Ambiente de desenvolvimento**: `http://dev.br.permutapolicial.com.br`
- **Ambiente de produção**: `https://br.permutapolicial.com.br`

### Detecção Automática do Ambiente

O ambiente é detectado automaticamente:

1. **Em modo debug (`kDebugMode`)**: Usa **desenvolvimento** por padrão
2. **Em modo release**: Usa **produção** por padrão
3. **Forçar produção em debug**: Use `--dart-define=ENV=prod`

## 🚀 Como Usar

### Opção 1: Modo Debug (Desenvolvimento)

Quando você roda em modo debug, automaticamente usará o ambiente de desenvolvimento:

```bash
# Web
flutter run -d chrome

# Mobile
flutter run
```

**URLs usadas:**
- API: `http://dev.br.permutapolicial.com.br`
- Socket: `http://dev.br.permutapolicial.com.br`

### Opção 2: Forçar Produção em Debug

Para testar com produção mesmo em debug:

```bash
flutter run --dart-define=ENV=prod -d chrome
```

### Opção 3: Build de Produção (Release)

Ao fazer build de produção, automaticamente usa produção:

```bash
# Web
flutter build web --release

# Mobile
flutter build apk --release
flutter build ios --release
```

## 📝 Arquivos Atualizados

1. **`lib/core/config/app_config.dart`** - Novo arquivo de configuração
2. **`lib/core/api/api_client.dart`** - Atualizado para usar `AppConfig.apiBaseUrl`
3. **`lib/core/services/socket_service.dart`** - Atualizado para usar `AppConfig.socketBaseUrl`

## 🔍 Verificar Ambiente Atual

O `AppConfig` possui um método para logar as configurações:

```dart
AppConfig.logEnvironment();
```

Isso imprime no console:
```
═══════════════════════════════════════
🔧 CONFIGURAÇÃO DO AMBIENTE
📍 Ambiente: development
📍 API Base URL: http://dev.br.permutapolicial.com.br
📍 Socket Base URL: http://dev.br.permutapolicial.com.br
═══════════════════════════════════════
```

## 🛠️ Personalização

Para alterar as URLs ou adicionar novos ambientes, edite `lib/core/config/app_config.dart`:

```dart
static String get apiBaseUrl {
  switch (environment) {
    case Environment.development:
      return 'http://dev.br.permutapolicial.com.br'; // Altere aqui
    case Environment.production:
      return 'https://br.permutapolicial.com.br'; // Altere aqui
  }
}
```

## ⚠️ Importante

1. **Certifique-se de que o servidor dev está rodando** em `dev.br.permutapolicial.com.br` (porta 3001 via proxy)

2. **CORS**: O servidor dev já está configurado para aceitar requisições de `dev.br.permutapolicial.com.br`

3. **Socket.IO**: Certifique-se de que o Socket.IO está configurado corretamente no servidor dev

4. **HTTPS/HTTP**: 
   - Produção usa HTTPS
   - Desenvolvimento usa HTTP

## 🧪 Testar

1. **Ambiente Dev:**
   ```bash
   flutter run -d chrome
   # Verifique nos logs: "Ambiente: development"
   # API deve chamar: http://dev.br.permutapolicial.com.br
   ```

2. **Ambiente Prod (em debug):**
   ```bash
   flutter run --dart-define=ENV=prod -d chrome
   # Verifique nos logs: "Ambiente: production"
   # API deve chamar: https://br.permutapolicial.com.br
   ```

## 📚 Referências

- Backend DEV: `backend_js/devserver.js` (porta 3001)
- Documentação Backend DEV: `backend_js/DEV_SERVER_README.md`


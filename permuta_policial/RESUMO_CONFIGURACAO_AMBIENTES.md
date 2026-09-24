# Resumo: Configuração de Ambientes no Frontend

## ✅ Alterações Realizadas

### 1. Novo Arquivo de Configuração

**Arquivo:** `lib/core/config/app_config.dart`

Criado sistema de configuração de ambientes que detecta automaticamente:
- **Desenvolvimento**: `http://dev.br.permutapolicial.com.br`
- **Produção**: `https://br.permutapolicial.com.br`

### 2. Arquivos Atualizados

1. **`lib/core/api/api_client.dart`**
   - Atualizado para usar `AppConfig.apiBaseUrl` ao invés de URL hardcoded

2. **`lib/core/services/socket_service.dart`**
   - Atualizado para usar `AppConfig.socketBaseUrl` ao invés de URL hardcoded

3. **`lib/main.dart`**
   - Adicionado log do ambiente ao iniciar a aplicação

### 3. Documentação

**Arquivo:** `CONFIGURACAO_AMBIENTES.md`

Documentação completa sobre como usar os ambientes.

## 🚀 Como Funciona

### Detecção Automática

- **Modo Debug**: Usa ambiente de **desenvolvimento** automaticamente
- **Modo Release**: Usa ambiente de **produção** automaticamente
- **Forçar produção em debug**: `flutter run --dart-define=ENV=prod`

### URLs Configuradas

| Ambiente | API URL | Socket URL |
|----------|---------|------------|
| Desenvolvimento | `http://dev.br.permutapolicial.com.br` | `http://dev.br.permutapolicial.com.br` |
| Produção | `https://br.permutapolicial.com.br` | `https://br.permutapolicial.com.br` |

## 📝 Exemplos de Uso

### Rodar em Desenvolvimento (Padrão em Debug)
```bash
flutter run -d chrome
```

### Rodar em Produção (Mesmo em Debug)
```bash
flutter run --dart-define=ENV=prod -d chrome
```

### Build de Produção
```bash
flutter build web --release
```

## ✅ Resultado

Agora o frontend está configurado para:
- ✅ Usar automaticamente o ambiente correto
- ✅ Conectar ao servidor dev quando em modo debug
- ✅ Conectar ao servidor de produção quando em release
- ✅ Permitir forçar produção mesmo em debug

**Nenhuma mudança adicional é necessária no frontend!**

## 📚 Referências

- `CONFIGURACAO_AMBIENTES.md` - Documentação detalhada
- `backend_js/DEV_SERVER_README.md` - Documentação do servidor dev


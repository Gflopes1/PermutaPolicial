# Diagnóstico: Erro "Failed to fetch" / CORS

## ❌ Problema

Erro `ClientException: Failed to fetch` ao fazer requisições POST para a API:
- `POST: http://dev.br.permutapolicial.com.br/api/analytics/evento`
- `POST: http://dev.br.permutapolicial.com.br/api/auth/login`

## 🔍 Possíveis Causas

### 1. Problema de CORS (Cross-Origin Resource Sharing)

O backend pode não estar permitindo a origem do Flutter Web.

**Verificar:**
- Qual é a origem exata do Flutter Web? (verifique nos logs do console)
- A origem está na lista de origens permitidas do backend?

**Solução:**
- Adicionar a origem do Flutter Web na lista de origens permitidas do backend
- Verificar se o backend está retornando os headers CORS corretos

### 2. Servidor não está acessível

O servidor pode não estar rodando ou não estar acessível na URL configurada.

**Verificar:**
- O servidor dev está rodando em `http://dev.br.permutapolicial.com.br`?
- A porta está correta? (geralmente 3001 via proxy)
- Há algum firewall bloqueando a conexão?

**Solução:**
- Verificar se o servidor está rodando: `curl http://dev.br.permutapolicial.com.br/api/health`
- Verificar logs do servidor para ver se as requisições estão chegando

### 3. Problema com BrowserClient

O `BrowserClient` pode ter problemas com requisições cross-origin.

**Verificar:**
- Se o erro acontece apenas no navegador (não em mobile)
- Se há erros no console do navegador relacionados a CORS

**Solução:**
- Verificar se o backend está retornando os headers CORS corretos
- Verificar se a requisição OPTIONS (preflight) está sendo respondida corretamente

## ✅ Melhorias Implementadas

### 1. Logs Melhorados

Adicionados logs mais detalhados no `ApiClient`:
- Origem da requisição
- Headers enviados
- Tipo de erro específico
- Mensagens de diagnóstico

### 2. Tratamento de Erros Específico

Melhor tratamento para `ClientException` com mensagens mais informativas sobre CORS.

## 🔧 Como Diagnosticar

### Passo 1: Verificar Logs do Console

Ao fazer uma requisição, você verá nos logs:
```
📍 Origem da requisição: http://localhost:xxxx (ou outra origem)
📍 Headers: Content-Type, Authorization
```

### Passo 2: Verificar Console do Navegador

Abra o DevTools (F12) e verifique:
- **Console**: Mensagens de erro relacionadas a CORS
- **Network**: 
  - Se a requisição OPTIONS (preflight) está sendo feita
  - Se a requisição POST está sendo bloqueada
  - Headers de resposta do servidor

### Passo 3: Verificar Backend

Verifique se o backend está:
- Rodando e acessível
- Retornando headers CORS corretos
- Permitindo a origem do Flutter Web

## 🛠️ Soluções

### Solução 1: Adicionar Origem no Backend

Se o Flutter Web está rodando em `http://localhost:xxxx`, adicione no `backend_js/devserver.js`:

```javascript
const allowedOrigins = [
    // ... origens existentes ...
    'http://localhost:xxxx', // Adicione a porta específica
    // Ou permita todas as portas do localhost:
    // (já está permitido na linha 288-289)
];
```

### Solução 2: Verificar Configuração do Proxy

Se o Flutter Web está sendo servido via proxy, verifique:
- Se o proxy está configurado corretamente
- Se o proxy está passando os headers CORS corretamente

### Solução 3: Testar Requisição Direta

Teste se o servidor está acessível:

```bash
# Teste de saúde do servidor
curl http://dev.br.permutapolicial.com.br/api/health

# Teste de CORS
curl -X OPTIONS http://dev.br.permutapolicial.com.br/api/auth/login \
  -H "Origin: http://localhost:xxxx" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

## 📝 Próximos Passos

1. **Verificar logs do console** para identificar a origem exata
2. **Verificar console do navegador** para ver erros de CORS específicos
3. **Verificar se o servidor está acessível** fazendo uma requisição direta
4. **Ajustar configuração de CORS** no backend se necessário

## 🔗 Referências

- [Flutter Web CORS](https://docs.flutter.dev/platform-integration/web/initialization)
- [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- Backend CORS config: `backend_js/devserver.js` (linhas 270-300)


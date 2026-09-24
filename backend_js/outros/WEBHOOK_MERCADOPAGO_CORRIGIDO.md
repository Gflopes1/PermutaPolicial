# Webhook do Mercado Pago - Correções Aplicadas

## ✅ Correções Realizadas

### 1. Validação de Assinatura Corrigida

**Antes:** A validação estava usando o payload bruto para calcular o HMAC.

**Agora:** Segue exatamente a documentação do Mercado Pago:

1. ✅ Extrai `ts` e `v1` do header `x-signature`
2. ✅ Extrai `data.id` do payload ou query parameters
3. ✅ Extrai `x-request-id` do header
4. ✅ Constrói o manifest: `id:[data.id];request-id:[x-request-id];ts:[ts];`
5. ✅ Calcula HMAC SHA256 usando o manifest (não o payload)
6. ✅ Compara com `v1` usando timing-safe comparison
7. ✅ Valida timestamp (avisa se muito antigo, mas não falha)

**Arquivo:** `backend_js/src/modules/questions/payments.service.js` - método `validateMercadoPagoSignature`

### 2. Processamento de Eventos Melhorado

Adicionados métodos específicos para eventos do Mercado Pago:

- ✅ `handleMercadoPagoPayment` - Processa pagamentos (payment.created, payment.updated)
- ✅ `handleMercadoPagoSubscriptionPreapproval` - Processa vinculação de assinatura
- ✅ `handleMercadoPagoAuthorizedPayment` - Processa pagamentos autorizados de assinaturas

**Arquivo:** `backend_js/src/modules/questions/payments.service.js`

### 3. Busca de Detalhes Completos via API

O webhook agora:
- ✅ Busca detalhes completos do pagamento via API do Mercado Pago quando necessário
- ✅ Usa `MERCADOPAGO_ACCESS_TOKEN` para fazer requisições à API
- ✅ Processa dados completos do pagamento (status, valores, metadata)

**Método:** `fetchMercadoPagoPaymentDetails`

### 4. Resposta HTTP Correta

- ✅ Sempre responde com status `200` ou `201` dentro de 22 segundos
- ✅ Responde mesmo em caso de erro (para evitar retentativas)

**Arquivo:** `backend_js/src/modules/questions/payments.controller.js`

### 5. Suporte a Query Parameters

- ✅ Extrai `data.id` de query parameters quando presente
- ✅ Valida assinatura considerando query parameters

### 6. Identificação Automática do Provider

- ✅ Identifica automaticamente se é Mercado Pago pelo header `x-signature`
- ✅ Fallback para Mercado Pago se não especificado

## 📋 Como o Webhook Funciona Agora

### Fluxo de Validação (Mercado Pago)

```
1. Recebe webhook com header x-signature
2. Extrai ts e v1 do header
3. Extrai data.id do payload ou query params
4. Extrai x-request-id do header
5. Constrói manifest: "id:123;request-id:abc;ts:1704908010;"
6. Calcula HMAC SHA256(manifest, secret)
7. Compara com v1
8. Se válido, processa o evento
9. Responde 200 OK
```

### Eventos Suportados

| Evento | Tipo | Handler |
|--------|------|---------|
| `payment.created` | payment | `handleMercadoPagoPayment` |
| `payment.updated` | payment | `handleMercadoPagoPayment` |
| `subscription_preapproval` | subscription | `handleMercadoPagoSubscriptionPreapproval` |
| `subscription_authorized_payment` | subscription | `handleMercadoPagoAuthorizedPayment` |

## ⚙️ Configuração Necessária

### Variáveis de Ambiente

```env
# Obrigatório para validação de assinatura
MERCADOPAGO_WEBHOOK_SECRET=sua-assinatura-secreta-do-mercadopago

# Obrigatório para buscar detalhes via API
MERCADOPAGO_ACCESS_TOKEN=seu-access-token-do-mercadopago
```

### URL do Webhook

Configure no painel do Mercado Pago:

**Produção:**
```
https://br.permutapolicial.com.br/api/payments/webhook/mercadopago
```

**Desenvolvimento:**
```
http://dev.br.permutapolicial.com.br/api/payments/webhook/mercadopago
```

## 🧪 Como Testar

### 1. Usar Simulador do Mercado Pago

1. Acesse "Suas integrações" > Sua aplicação > Webhooks
2. Clique em "Simular"
3. Selecione o tipo de evento
4. Envie o teste

### 2. Verificar Logs

```bash
# Ver logs do webhook em tempo real
tail -f logs/app.log | grep webhook

# Ou verificar no banco
SELECT * FROM payment_webhook_logs ORDER BY received_at DESC LIMIT 10;
```

### 3. Verificar Processamento

```bash
# Ver eventos processados
SELECT * FROM payment_events_processed ORDER BY received_at DESC LIMIT 10;

# Ver assinaturas criadas
SELECT * FROM user_subscriptions ORDER BY created_at DESC LIMIT 10;
```

## 📝 Formato da Resposta

O webhook sempre responde `200 OK`:

```json
{
  "processed": true,
  "eventId": "12345",
  "reason": "payment_succeeded",
  "paymentId": "999999999",
  "status": "succeeded"
}
```

## ⚠️ Importante

1. **Assinatura Secreta:** Configure no painel do Mercado Pago e no `.env`
2. **Access Token:** Necessário para buscar detalhes completos via API
3. **Timeout:** O Mercado Pago espera resposta em até 22 segundos
4. **Retentativas:** Se não responder, o Mercado Pago tentará novamente a cada 15 minutos

## 🔍 Troubleshooting

### Erro: "Assinatura inválida"

- Verifique se `MERCADOPAGO_WEBHOOK_SECRET` está configurado corretamente
- Verifique se a assinatura secreta no painel do Mercado Pago está atualizada
- Verifique os logs para ver o manifest gerado e comparar

### Erro: "Timeout"

- Certifique-se de que o processamento é rápido (< 20 segundos)
- Use jobs assíncronos para processamento pesado

### Eventos não sendo processados

- Verifique os logs do webhook em `payment_webhook_logs`
- Verifique os eventos processados em `payment_events_processed`
- Verifique se o tipo de evento está sendo suportado


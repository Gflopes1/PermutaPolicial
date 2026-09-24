# Como Testar o Webhook do Mercado Pago

## ✅ Implementação Atual

O webhook foi corrigido para seguir a documentação oficial do Mercado Pago:

### Validação de Assinatura
- ✅ Extrai `ts` e `v1` do header `x-signature`
- ✅ Constrói manifest: `id:[data.id];request-id:[x-request-id];ts:[ts];`
- ✅ Calcula HMAC SHA256 com o manifest
- ✅ Valida timestamp (avisa se muito antigo)

### Processamento de Eventos
- ✅ `payment` (payment.created, payment.updated) → Busca detalhes via API
- ✅ `subscription_preapproval` → Processa vinculação de assinatura
- ✅ `subscription_authorized_payment` → Processa pagamento recorrente

### Resposta
- ✅ Sempre responde `200 OK` dentro de 22 segundos
- ✅ Responde mesmo em caso de erro (evita retentativas)

## 🧪 Como Testar

### 1. Usar Simulador do Mercado Pago

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Vá em "Suas integrações" > Sua aplicação
3. Clique em "Webhooks" > "Configurar notificações"
4. Configure a URL:
   - **Teste**: `http://dev.br.permutapolicial.com.br/api/payments/webhook/mercadopago`
   - **Produção**: `https://br.permutapolicial.com.br/api/payments/webhook/mercadopago`
5. Selecione os eventos:
   - ✅ Pagamentos (payment)
   - ✅ Planos e assinaturas (subscription_preapproval)
   - ✅ Planos e assinaturas (subscription_authorized_payment)
6. Clique em "Salvar"
7. Clique em "Simular" para testar

### 2. Verificar Logs no Backend

```bash
# No terminal onde o servidor está rodando, você verá:
✅ Webhook MercadoPago recebido
✅ Assinatura válida
✅ Processando evento: payment
✅ Pagamento processado com sucesso
```

### 3. Verificar no Banco de Dados

```sql
-- Ver últimos webhooks recebidos
SELECT * FROM payment_webhook_logs 
WHERE provider = 'mercadopago' 
ORDER BY received_at DESC 
LIMIT 10;

-- Ver eventos processados
SELECT * FROM payment_events_processed 
WHERE provider = 'mercadopago' 
ORDER BY received_at DESC 
LIMIT 10;

-- Ver assinaturas criadas/atualizadas
SELECT * FROM user_subscriptions 
ORDER BY created_at DESC 
LIMIT 10;
```

### 4. Testar Manualmente (cURL)

```bash
# Exemplo de webhook do Mercado Pago
curl -X POST https://br.permutapolicial.com.br/api/payments/webhook/mercadopago \
  -H "Content-Type: application/json" \
  -H "x-signature: ts=1704908010,v1=abc123..." \
  -H "x-request-id: test-123" \
  -d '{
    "id": 12345,
    "live_mode": true,
    "type": "payment",
    "date_created": "2015-03-25T10:04:58.396-04:00",
    "user_id": 44444,
    "api_version": "v1",
    "action": "payment.created",
    "data": {
      "id": "999999999"
    }
  }'
```

## ⚠️ Checklist de Configuração

- [ ] `MERCADOPAGO_WEBHOOK_SECRET` configurado no `.env`
- [ ] `MERCADOPAGO_ACCESS_TOKEN` configurado no `.env` (para buscar detalhes via API)
- [ ] URL do webhook configurada no painel do Mercado Pago
- [ ] Eventos selecionados no painel do Mercado Pago
- [ ] Assinatura secreta gerada no painel do Mercado Pago
- [ ] Servidor respondendo na URL configurada

## 🔍 Troubleshooting

### Erro: "Assinatura inválida"

**Possíveis causas:**
1. Assinatura secreta incorreta ou desatualizada
2. Manifest construído incorretamente
3. Query params não sendo capturados

**Como verificar:**
- Veja os logs no console (mostra o manifest gerado)
- Compare a assinatura secreta no `.env` com a do painel
- Verifique se `x-request-id` está presente no header

### Eventos não sendo processados

**Possíveis causas:**
1. Tipo de evento não suportado
2. `data.id` não encontrado
3. Erro ao buscar detalhes via API

**Como verificar:**
- Veja os logs no console
- Verifique `payment_webhook_logs` para ver o payload recebido
- Verifique `payment_events_processed` para ver o status

### Pagamento não atualizando assinatura

**Possíveis causas:**
1. `user_id` não está no metadata do pagamento
2. Pagamento não é de assinatura
3. Status do pagamento não é "approved"

**Como verificar:**
- Veja os detalhes do pagamento em `payments` table
- Verifique se `user_id` está correto no metadata
- Verifique o status do pagamento


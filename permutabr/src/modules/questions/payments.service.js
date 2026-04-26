const paymentsRepository = require('./payments.repository');
const crypto = require('crypto');
const ApiError = require('../../core/utils/ApiError');
const axios = require('axios');

class PaymentsService {
  async validateWebhookSignature(provider, payload, signature, secret, headers = {}, queryParams = {}) {
    if (!secret) {
      throw new ApiError(500, 'Webhook secret não configurado');
    }

    switch (provider.toLowerCase()) {
      case 'stripe':
        return this.validateStripeSignature(payload, signature, secret);
      case 'mercadopago':
        return this.validateMercadoPagoSignature(payload, signature, secret, headers, queryParams);
      default:
        throw new ApiError(400, `Provider ${provider} não suportado`);
    }
  }

  validateStripeSignature(payload, signature, secret) {
    try {
      const elements = signature.split(',');
      const timestamp = elements.find(e => e.startsWith('t='))?.split('=')[1];
      const signatures = elements.filter(e => e.startsWith('v1=')).map(e => e.split('=')[1]);

      if (!timestamp || signatures.length === 0) {
        return false;
      }

      const currentTime = Math.floor(Date.now() / 1000);
      if (Math.abs(currentTime - parseInt(timestamp)) > 300) {
        return false;
      }

      const signedPayload = `${timestamp}.${payload}`;
      const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(signedPayload)
        .digest('hex');

      return signatures.some(sig => crypto.timingSafeEqual(
        Buffer.from(sig),
        Buffer.from(expectedSignature)
      ));
    } catch (error) {
      return false;
    }
  }

  validateMercadoPagoSignature(payload, signature, secret, headers = {}, queryParams = {}) {
    try {
      // Normaliza a assinatura (remove espaços extras)
      const parts = signature.split(',').map(p => p.trim());
      let ts = null;
      let v1 = null;

      // Extrai ts e v1 de forma segura
      parts.forEach(part => {
        const [key, value] = part.split('=');
        if (key && value) {
            if (key.trim() === 'ts') ts = value.trim();
            if (key.trim() === 'v1') v1 = value.trim();
        }
      });

      console.log(`🔍 Webhook MP Debug: TS recebido: ${ts}, V1 recebido: ${v1}`);

      if (!ts || !v1) {
        console.error('❌ Webhook MercadoPago: ts ou v1 não encontrados no header x-signature');
        return false;
      }

      // Extrai data.id
      let dataId = null;
      try {
        const payloadObj = typeof payload === 'string' ? JSON.parse(payload) : payload;
        dataId = payloadObj?.data?.id || queryParams['data.id'] || queryParams['data_id'];
      } catch (e) {
        dataId = queryParams['data.id'] || queryParams['data_id'];
      }

      // Normaliza data.id (lowercase se alfanumérico)
      if (dataId && typeof dataId === 'string' && /^[a-zA-Z0-9]+$/.test(dataId)) {
        dataId = dataId.toLowerCase();
      }

      // Extrai x-request-id
      const xRequestId = headers['x-request-id'] || headers['X-Request-Id'] || null;

      // Constrói o manifest
      let manifest = '';
      if (dataId) manifest += `id:${dataId};`;
      if (xRequestId) manifest += `request-id:${xRequestId};`;
      if (ts) manifest += `ts:${ts};`;

      // Valida Hash
      const hmac = crypto.createHmac('sha256', secret).update(manifest).digest('hex');
      const isValid = crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(v1));

      if (!isValid) {
        console.error('❌ Webhook MercadoPago: Hash inválido (Assinatura incorreta)');
        console.error(`   Manifest gerado: ${manifest}`);
        console.error(`   Hash calculado: ${hmac}`);
        return false;
      }

      // --- CORREÇÃO DO TIMESTAMP ---
      const currentTimeMs = Date.now();
      let notificationTime = parseInt(ts);
      
      // Se o timestamp for pequeno (ex: 10 dígitos), é segundos. Converte para ms.
      // Se for grande (13 dígitos), já é ms.
      if (notificationTime < 100000000000) { 
          notificationTime = notificationTime * 1000; 
      }

      // Diferença em segundos para o log
      const timeDiffSeconds = Math.abs((currentTimeMs - notificationTime) / 1000);
      
      // ✅ CORREÇÃO SEGURANÇA: Replay Attack - tolerância reduzida para 5 minutos (300 segundos)
      if (timeDiffSeconds > 300) {
        console.warn(`⚠️ Webhook MercadoPago: Timestamp antigo (diferença de ${timeDiffSeconds.toFixed(1)}s). Server: ${currentTimeMs}, MP: ${notificationTime}`);
        // Rejeita webhooks com timestamp muito antigo para prevenir replay attacks
        return false; 
      }

      return true;
    } catch (error) {
      console.error('❌ Erro ao validar assinatura MercadoPago:', error);
      return false;
    }
  }

  async processWebhook(provider, rawPayload, headers, queryParams = {}) {
    const logId = await paymentsRepository.logWebhook(provider, rawPayload, headers);

    try {
      const payload = typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
      
      // Para Mercado Pago, o ID do evento pode estar em diferentes lugares
      let eventId;
      if (provider.toLowerCase() === 'mercadopago') {
        eventId = payload.id || queryParams['data.id'] || `${provider}_${Date.now()}`;
      } else {
        eventId = payload.id || payload.event_id || `${provider}_${Date.now()}`;
      }

      // Verifica se o evento já foi processado
      const existing = await paymentsRepository.checkEventProcessed(eventId);
      if (existing && existing.status === 'ok') {
        await paymentsRepository.markWebhookProcessed(logId);
        return { processed: true, eventId, reason: 'already_processed' };
      }

      await paymentsRepository.markEventProcessing(eventId, provider);

      let result;
      const eventType = payload.type || payload.action;
      
      // Processa eventos do Mercado Pago conforme documentação
      if (provider.toLowerCase() === 'mercadopago') {
        // O tipo pode ser "payment", mas o action indica o que aconteceu
        const action = payload.action || eventType;
        
        // Para eventos de payment, sempre processa via handleMercadoPagoPayment
        // que busca os detalhes completos via API
        if (eventType === 'payment' || action.startsWith('payment.')) {
          result = await this.handleMercadoPagoPayment(provider, payload, queryParams);
        } else if (eventType === 'subscription_preapproval' || action === 'subscription.preapproval') {
          result = await this.handleMercadoPagoSubscriptionPreapproval(provider, payload);
        } else if (eventType === 'subscription_authorized_payment' || action === 'subscription.authorized_payment') {
          result = await this.handleMercadoPagoAuthorizedPayment(provider, payload);
        } else {
          console.warn(`⚠️ Webhook MercadoPago: Tipo de evento não suportado: ${eventType}, action: ${action}`);
          result = { processed: false, reason: `unknown_event_type: ${eventType}` };
        }
      } else {
        // Outros providers (Stripe, etc)
        switch (eventType) {
          case 'payment.succeeded':
          case 'payment.created':
            result = await this.handlePaymentSucceeded(provider, payload);
            break;
          case 'payment.failed':
            result = await this.handlePaymentFailed(provider, payload);
            break;
          case 'charge.refunded':
          case 'payment.refunded':
            result = await this.handlePaymentRefunded(provider, payload);
            break;
          default:
            result = { processed: false, reason: `unknown_event_type: ${eventType}` };
        }
      }

      await paymentsRepository.markEventProcessed(
        eventId,
        result.processed ? 'ok' : 'failed',
        result.reason
      );
      await paymentsRepository.markWebhookProcessed(logId);

      return { processed: result.processed, eventId, ...result };
    } catch (error) {
      console.error('💥 Erro ao processar webhook:', error);
      await paymentsRepository.markWebhookProcessed(logId, error.message);
      throw new ApiError(500, `Erro ao processar webhook: ${error.message}`);
    }
  }

  async handlePaymentSucceeded(provider, payload) {
    const paymentData = this.extractPaymentData(provider, payload);
    
    await paymentsRepository.createPayment({
      provider,
      provider_payment_id: paymentData.paymentId,
      user_id: paymentData.userId,
      amount_cents: paymentData.amountCents,
      currency: paymentData.currency || 'BRL',
      status: 'succeeded',
      metadata: payload
    });

    const subscriptionData = this.extractSubscriptionData(provider, payload);
    if (subscriptionData) {
      await paymentsRepository.createOrUpdateSubscription({
        user_id: subscriptionData.userId,
        plan_id: 'premium',
        status: 'active',
        start_at: new Date(),
        end_at: subscriptionData.endDate || null,
        provider,
        provider_subscription_id: subscriptionData.subscriptionId,
        metadata: payload
      });
    }

    return { processed: true, reason: 'payment_succeeded' };
  }

  async handlePaymentFailed(provider, payload) {
    const paymentData = this.extractPaymentData(provider, payload);
    
    await paymentsRepository.createPayment({
      provider,
      provider_payment_id: paymentData.paymentId,
      user_id: paymentData.userId,
      amount_cents: paymentData.amountCents,
      currency: paymentData.currency || 'BRL',
      status: 'failed',
      metadata: payload
    });

    return { processed: true, reason: 'payment_failed' };
  }

  async handlePaymentRefunded(provider, payload) {
    const paymentData = this.extractPaymentData(provider, payload);
    
    await paymentsRepository.updatePaymentStatus(
      provider,
      paymentData.paymentId,
      'refunded'
    );

    const subscriptionData = this.extractSubscriptionData(provider, payload);
    if (subscriptionData) {
      await paymentsRepository.createOrUpdateSubscription({
        user_id: subscriptionData.userId,
        plan_id: 'premium',
        status: 'canceled',
        start_at: new Date(),
        end_at: new Date(),
        provider,
        provider_subscription_id: subscriptionData.subscriptionId,
        metadata: payload
      });
    }

    return { processed: true, reason: 'payment_refunded' };
  }

  // Busca detalhes completos do pagamento via API do Mercado Pago
  async fetchMercadoPagoPaymentDetails(paymentId) {
    const axios = require('axios');
    const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
    
    if (!accessToken) {
      console.warn('⚠️ MERCADOPAGO_ACCESS_TOKEN não configurado. Não será possível buscar detalhes do pagamento.');
      return null;
    }

    try {
      const response = await axios.get(
        `https://api.mercadopago.com/v1/payments/${paymentId}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );
      return response.data;
    } catch (error) {
      console.error(`❌ Erro ao buscar detalhes do pagamento ${paymentId} do Mercado Pago:`, error.message);
      return null;
    }
  }

  // Processa pagamento do Mercado Pago
  async handleMercadoPagoPayment(provider, payload, queryParams = {}) {
    // Extrai o ID do pagamento - pode estar em diferentes lugares
    // 1. Query param (data.id)
    // 2. payload.data.id
    // 3. payload.id (se o payload já é o objeto de pagamento)
    let paymentId = queryParams['data.id'] || queryParams['data_id'];
    
    if (!paymentId && payload.data) {
      paymentId = payload.data.id || payload.data.payment_id;
    }
    
    if (!paymentId && payload.id) {
      paymentId = payload.id;
    }
    
    // Se ainda não encontrou, tenta no payload direto (caso o webhook envie o objeto completo)
    if (!paymentId && payload.payment_id) {
      paymentId = payload.payment_id;
    }
    
    if (!paymentId) {
      console.error('❌ Webhook MercadoPago: ID do pagamento não encontrado');
      console.error('   Payload:', JSON.stringify(payload, null, 2));
      console.error('   Query params:', queryParams);
      return { processed: false, reason: 'payment_id_missing' };
    }
    
    // Converte para string para garantir consistência
    paymentId = paymentId.toString();

    // Busca os detalhes completos do pagamento via API
    const paymentDetails = await this.fetchMercadoPagoPaymentDetails(paymentId);
    
    // Se não conseguir buscar, usa os dados do payload
    const paymentData = paymentDetails || payload.data || payload;
    
    // Extrai dados do pagamento
    const userId = paymentData.metadata?.user_id || paymentData.external_reference;
    const amountCents = paymentData.transaction_amount 
      ? Math.round(paymentData.transaction_amount * 100) 
      : (paymentData.amount || 0);
    const currency = paymentData.currency_id || paymentData.currency || 'BRL';
    const status = paymentData.status; // approved, pending, rejected, etc

    // Mapeia status do Mercado Pago para status interno
    let internalStatus = 'pending';
    if (status === 'approved') {
      internalStatus = 'succeeded';
    } else if (status === 'rejected' || status === 'cancelled') {
      internalStatus = 'failed';
    } else if (status === 'refunded') {
      internalStatus = 'refunded';
    }

    // Salva ou atualiza o pagamento
    await paymentsRepository.createPayment({
      provider,
      provider_payment_id: paymentId.toString(),
      user_id: userId ? parseInt(userId) : null,
      amount_cents: amountCents,
      currency,
      status: internalStatus,
      metadata: paymentData
    });

    // Se o pagamento foi aprovado e é de uma assinatura, atualiza a assinatura
    if (internalStatus === 'succeeded' && userId) {
      // Verifica se há dados de assinatura no pagamento
      const subscriptionId = paymentData.subscription_id || paymentData.preapproval_id;
      
      if (subscriptionId) {
        await paymentsRepository.createOrUpdateSubscription({
          user_id: parseInt(userId),
          plan_id: 'premium',
          status: 'active',
          start_at: new Date(),
          end_at: null, // Assinaturas são mensais, será atualizado quando cancelar
          provider,
          provider_subscription_id: subscriptionId.toString(),
          metadata: paymentData
        });
      }
    }

    return { 
      processed: true, 
      reason: `payment_${internalStatus}`,
      paymentId,
      status: internalStatus
    };
  }

  // Processa vinculação de assinatura do Mercado Pago
  async handleMercadoPagoSubscriptionPreapproval(provider, payload) {
    const axios = require('axios');
    const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
    
    // Extrai ID da assinatura
    const preapprovalId = payload.data?.id || payload.id;
    
    if (!preapprovalId) {
      return { processed: false, reason: 'preapproval_id_missing' };
    }

    // Busca detalhes da assinatura via API
    let preapprovalDetails = null;
    if (accessToken) {
      try {
        const response = await axios.get(
          `https://api.mercadopago.com/preapproval/search`,
          {
            params: { id: preapprovalId },
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json'
            }
          }
        );
        preapprovalDetails = response.data.results?.[0];
      } catch (error) {
        console.error(`❌ Erro ao buscar detalhes da assinatura ${preapprovalId}:`, error.message);
      }
    }

    const preapprovalData = preapprovalDetails || payload.data || payload;
    const userId = preapprovalData.metadata?.user_id || preapprovalData.external_reference;
    const status = preapprovalData.status; // authorized, paused, cancelled, etc

    if (!userId) {
      return { processed: false, reason: 'user_id_missing' };
    }

    // Mapeia status do Mercado Pago para status interno
    let internalStatus = 'active';
    if (status === 'authorized') {
      internalStatus = 'active';
    } else if (status === 'paused' || status === 'cancelled') {
      internalStatus = 'canceled';
    }

    // Calcula data de término (normalmente 1 mês)
    const startAt = preapprovalData.date_created 
      ? new Date(preapprovalData.date_created) 
      : new Date();
    const endAt = preapprovalData.auto_recurring?.end_date
      ? new Date(preapprovalData.auto_recurring.end_date)
      : null;

    await paymentsRepository.createOrUpdateSubscription({
      user_id: parseInt(userId),
      plan_id: 'premium',
      status: internalStatus,
      start_at: startAt,
      end_at: endAt,
      provider,
      provider_subscription_id: preapprovalId.toString(),
      metadata: preapprovalData
    });

    return { 
      processed: true, 
      reason: 'subscription_preapproval_processed',
      preapprovalId,
      status: internalStatus
    };
  }

  // Processa pagamento autorizado de assinatura do Mercado Pago
  async handleMercadoPagoAuthorizedPayment(provider, payload) {
    const axios = require('axios');
    const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
    
    const authorizedPaymentId = payload.data?.id || payload.id;
    
    if (!authorizedPaymentId) {
      return { processed: false, reason: 'authorized_payment_id_missing' };
    }

    // Busca detalhes do pagamento autorizado via API
    let authorizedPaymentDetails = null;
    if (accessToken) {
      try {
        const response = await axios.get(
          `https://api.mercadopago.com/authorized_payments/${authorizedPaymentId}`,
          {
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json'
            }
          }
        );
        authorizedPaymentDetails = response.data;
      } catch (error) {
        console.error(`❌ Erro ao buscar detalhes do pagamento autorizado ${authorizedPaymentId}:`, error.message);
      }
    }

    const paymentData = authorizedPaymentDetails || payload.data || payload;
    const userId = paymentData.metadata?.user_id || paymentData.external_reference;
    const subscriptionId = paymentData.subscription_id || paymentData.preapproval_id;
    const status = paymentData.status;

    if (!userId || !subscriptionId) {
      return { processed: false, reason: 'user_id_or_subscription_id_missing' };
    }

    // Se o pagamento foi aprovado, atualiza a assinatura
    if (status === 'approved') {
      await paymentsRepository.createOrUpdateSubscription({
        user_id: parseInt(userId),
        plan_id: 'premium',
        status: 'active',
        start_at: new Date(),
        end_at: null,
        provider,
        provider_subscription_id: subscriptionId.toString(),
        metadata: paymentData
      });
    }

    return { 
      processed: true, 
      reason: 'authorized_payment_processed',
      authorizedPaymentId,
      status
    };
  }

  extractPaymentData(provider, payload) {
    if (provider.toLowerCase() === 'stripe') {
      return {
        paymentId: payload.data?.object?.id || payload.id,
        userId: payload.data?.object?.metadata?.user_id || payload.metadata?.user_id,
        amountCents: payload.data?.object?.amount || payload.amount,
        currency: payload.data?.object?.currency || payload.currency
      };
    } else if (provider.toLowerCase() === 'mercadopago') {
      return {
        paymentId: payload.data?.id || payload.id,
        userId: payload.data?.metadata?.user_id || payload.metadata?.user_id,
        amountCents: payload.data?.transaction_amount ? Math.round(payload.data.transaction_amount * 100) : payload.amount,
        currency: payload.data?.currency_id || payload.currency || 'BRL'
      };
    }

    return {
      paymentId: payload.id || payload.payment_id,
      userId: payload.user_id || payload.metadata?.user_id,
      amountCents: payload.amount_cents || payload.amount,
      currency: payload.currency || 'BRL'
    };
  }

  extractSubscriptionData(provider, payload) {
    if (provider.toLowerCase() === 'stripe') {
      const subscription = payload.data?.object?.subscription || payload.subscription;
      if (subscription) {
        return {
          userId: payload.data?.object?.metadata?.user_id || payload.metadata?.user_id,
          subscriptionId: subscription,
          endDate: payload.data?.object?.current_period_end 
            ? new Date(payload.data.object.current_period_end * 1000)
            : null
        };
      }
    } else if (provider.toLowerCase() === 'mercadopago') {
      const subscription = payload.data?.subscription_id || payload.subscription_id;
      if (subscription) {
        return {
          userId: payload.data?.metadata?.user_id || payload.metadata?.user_id,
          subscriptionId: subscription,
          endDate: payload.data?.date_of_expiration 
            ? new Date(payload.data.date_of_expiration)
            : null
        };
      }
    }

    return null;
  }

  async getUserSubscription(userId) {
    return await paymentsRepository.getUserActiveSubscription(userId);
  }

  async cancelSubscription(userId, subscriptionId) {
    // Primeiro, busca a assinatura
    const subscription = await paymentsRepository.getUserSubscriptionById(subscriptionId);
    
    if (!subscription) {
      throw new ApiError(404, 'Assinatura não encontrada');
    }

    if (subscription.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para cancelar esta assinatura');
    }

    if (subscription.status !== 'active') {
      throw new ApiError(400, 'Esta assinatura já foi cancelada ou está inativa');
    }

    // Se a assinatura for do Mercado Pago e tiver provider_subscription_id, cancela no Mercado Pago primeiro
    if (subscription.provider === 'mercadopago' && subscription.provider_subscription_id) {
      const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;
      
      if (!accessToken) {
        console.warn('⚠️ MERCADOPAGO_ACCESS_TOKEN não configurado. Cancelando apenas localmente.');
      } else {
        try {
          await axios.put(
            `https://api.mercadopago.com/preapproval/${subscription.provider_subscription_id}`,
            { status: 'cancelled' },
            {
              headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
              }
            }
          );
          console.log(`✅ Assinatura ${subscription.provider_subscription_id} cancelada no Mercado Pago`);
        } catch (error) {
          console.error(`❌ Erro ao cancelar assinatura no Mercado Pago:`, error.message);
          if (error.response) {
            console.error(`   Status: ${error.response.status}`);
            console.error(`   Data: ${JSON.stringify(error.response.data)}`);
          }
          // Lança exceção se falhar no cancelamento no Mercado Pago
          throw new ApiError(500, `Erro ao cancelar assinatura no Mercado Pago: ${error.message}`);
        }
      }
    }

    // Após o sucesso no Mercado Pago (ou se não for MP), cancela localmente no banco de dados
    const canceled = await paymentsRepository.cancelSubscription(userId, subscriptionId);
    
    if (!canceled) {
      throw new ApiError(500, 'Erro ao cancelar assinatura');
    }

    return canceled;
  }

  async getWebhookLogs(filters) {
    return await paymentsRepository.getAllWebhookLogs(filters);
  }

  async retryWebhook(logId) {
    const [logs] = await paymentsRepository.getUnprocessedWebhooks(1000);
    const log = logs.find(l => l.id === logId);
    
    if (!log) {
      throw new ApiError(404, 'Log de webhook não encontrado');
    }

    if (log.processed) {
      throw new ApiError(400, 'Webhook já foi processado');
    }

    const provider = log.provider;
    const headers = typeof log.headers === 'string' 
      ? JSON.parse(log.headers) 
      : log.headers;

    return await this.processWebhook(provider, log.raw_payload, headers);
  }
}

module.exports = new PaymentsService();



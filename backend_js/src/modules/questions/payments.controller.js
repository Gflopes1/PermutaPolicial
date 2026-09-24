const paymentsService = require('./payments.service');
const ApiError = require('../../core/utils/ApiError');

class PaymentsController {
  async processWebhook(req, res, next) {
    try {
      // Determina o provider - pode ser via URL param, header ou payload
      let provider = req.params.provider;
      
      // Tenta identificar automaticamente pelo header x-signature
      if (!provider) {
        if (req.headers['x-signature'] || req.headers['x-mercadopago-signature']) {
          provider = 'mercadopago';
        } else if (req.headers['stripe-signature']) {
          provider = 'stripe';
        } else {
          provider = 'mercadopago'; // Default para MercadoPago
        }
      }
      
      let rawPayload;
      
      if (req.rawBody) {
        rawPayload = req.rawBody.toString();
      } else if (typeof req.body === 'string') {
        rawPayload = req.body;
      } else {
        rawPayload = JSON.stringify(req.body);
      }
      
      const signature = req.headers['x-signature'] || req.headers['stripe-signature'] || req.headers['x-mercadopago-signature'];
      const secret = process.env[`${provider.toUpperCase()}_WEBHOOK_SECRET`] || process.env.MERCADOPAGO_WEBHOOK_SECRET;

      // Para MercadoPago, a validação pode ser opcional em desenvolvimento
      // Mas em produção, sempre valida
      if (provider.toLowerCase() === 'mercadopago') {
        if (signature && secret) {
          const isValid = await paymentsService.validateWebhookSignature(
            provider,
            rawPayload,
            signature,
            secret,
            req.headers,
            req.query // Query params para data.id
          );

          if (!isValid) {
            console.error('❌ Webhook MercadoPago: Assinatura inválida');
            return res.status(401).json({ error: 'Assinatura inválida' });
          }
        } else if (process.env.NODE_ENV === 'production') {
          // Em produção, sempre exige assinatura
          return res.status(401).json({ error: 'Assinatura não fornecida ou secret não configurado' });
        } else {
          console.warn('⚠️ Webhook MercadoPago: Executando sem validação de assinatura (modo desenvolvimento)');
        }
      } else {
        // Para outros providers (Stripe, etc), sempre valida
        if (!signature || !secret) {
          return res.status(401).json({ error: 'Assinatura não fornecida ou secret não configurado' });
        }

        const isValid = await paymentsService.validateWebhookSignature(
          provider,
          rawPayload,
          signature,
          secret,
          req.headers,
          req.query
        );

        if (!isValid) {
          return res.status(401).json({ error: 'Assinatura inválida' });
        }
      }

      // Processa o webhook
      const result = await paymentsService.processWebhook(provider, rawPayload, req.headers, req.query);
      
      // Responde com 200 ou 201 conforme documentação do Mercado Pago
      // O Mercado Pago espera 200/201 dentro de 22 segundos
      res.status(200).json(result);
    } catch (error) {
      console.error('💥 Erro ao processar webhook:', error);
      // Em caso de erro, ainda responde 200 para evitar retentativas desnecessárias
      // Mas loga o erro para investigação
      res.status(200).json({ 
        error: true, 
        message: error.message,
        processed: false 
      });
    }
  }

  async getWebhookLogs(req, res, next) {
    try {
      const filters = {
        page: parseInt(req.query.page) || 1,
        perPage: parseInt(req.query.per_page) || 50,
        provider: req.query.provider,
        processed: req.query.processed !== undefined ? req.query.processed === 'true' : undefined
      };

      const result = await paymentsService.getWebhookLogs(filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async retryWebhook(req, res, next) {
    try {
      const result = await paymentsService.retryWebhook(req.params.id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getUserSubscription(req, res, next) {
    try {
      const userId = req.user.id;
      const subscription = await paymentsService.getUserSubscription(userId);
      res.json(subscription);
    } catch (error) {
      next(error);
    }
  }

  async cancelSubscription(req, res, next) {
    try {
      const userId = req.user.id;
      const subscriptionId = parseInt(req.body.subscription_id);
      
      if (!subscriptionId || isNaN(subscriptionId)) {
        return next(new ApiError(400, 'ID da assinatura é obrigatório'));
      }

      const canceled = await paymentsService.cancelSubscription(userId, subscriptionId);
      res.json({ 
        status: 'success',
        message: 'Assinatura cancelada com sucesso',
        data: { subscription: canceled }
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PaymentsController();


const db = require('../../config/db');

class PaymentsRepository {
  async logWebhook(provider, rawPayload, headers) {
    const headersJson = JSON.stringify(headers);

    const [result] = await db.execute(
      `INSERT INTO payment_webhook_logs (provider, raw_payload, headers)
       VALUES (?, ?, ?)`,
      [provider, rawPayload, headersJson]
    );

    return result.insertId;
  }

  async markWebhookProcessed(logId, error = null) {
    await db.execute(
      `UPDATE payment_webhook_logs 
       SET processed = TRUE, error = ?, retry_count = retry_count + 1
       WHERE id = ?`,
      [error, logId]
    );
    return true;
  }

  async getUnprocessedWebhooks(limit = 10) {
    const [rows] = await db.execute(
      `SELECT * FROM payment_webhook_logs
       WHERE processed = FALSE
       ORDER BY received_at ASC
       LIMIT ?`,
      [limit]
    );
    return rows;
  }

  async checkEventProcessed(eventId) {
    const [rows] = await db.execute(
      'SELECT * FROM payment_events_processed WHERE event_id = ?',
      [eventId]
    );
    return rows[0] || null;
  }

  async markEventProcessing(eventId, provider) {
    await db.execute(
      `INSERT INTO payment_events_processed (event_id, provider, status)
       VALUES (?, ?, 'processing')
       ON DUPLICATE KEY UPDATE status = 'processing'`,
      [eventId, provider]
    );
    return true;
  }

  async markEventProcessed(eventId, status, note = null) {
    await db.execute(
      `UPDATE payment_events_processed 
       SET status = ?, processed_at = CURRENT_TIMESTAMP, note = ?
       WHERE event_id = ?`,
      [status, note, eventId]
    );
    return true;
  }

  async createPayment(paymentData) {
    const {
      provider,
      provider_payment_id,
      user_id,
      amount_cents,
      currency = 'BRL',
      status = 'pending',
      metadata
    } = paymentData;

    const metadataJson = metadata ? JSON.stringify(metadata) : null;

    const [result] = await db.execute(
      `INSERT INTO payments 
       (provider, provider_payment_id, user_id, amount_cents, currency, status, metadata)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [provider, provider_payment_id, user_id, amount_cents, currency, status, metadataJson]
    );

    return result.insertId;
  }

  async updatePaymentStatus(provider, providerPaymentId, status) {
    await db.execute(
      `UPDATE payments SET status = ?, updated_at = CURRENT_TIMESTAMP
       WHERE provider = ? AND provider_payment_id = ?`,
      [status, provider, providerPaymentId]
    );
    return true;
  }

  async createOrUpdateSubscription(subscriptionData) {
    const {
      user_id,
      plan_id = 'premium',
      status = 'active',
      start_at,
      end_at,
      provider,
      provider_subscription_id,
      metadata
    } = subscriptionData;

    const metadataJson = metadata ? JSON.stringify(metadata) : null;

    const [existing] = await db.execute(
      `SELECT id FROM user_subscriptions
       WHERE user_id = ? AND provider = ? AND provider_subscription_id = ?`,
      [user_id, provider, provider_subscription_id]
    );

    if (existing.length > 0) {
      await db.execute(
        `UPDATE user_subscriptions SET
         plan_id = ?, status = ?, start_at = ?, end_at = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [plan_id, status, start_at, end_at, metadataJson, existing[0].id]
      );
      return existing[0].id;
    } else {
      const [result] = await db.execute(
        `INSERT INTO user_subscriptions 
         (user_id, plan_id, status, start_at, end_at, provider, provider_subscription_id, metadata)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [user_id, plan_id, status, start_at, end_at, provider, provider_subscription_id, metadataJson]
      );
      return result.insertId;
    }
  }

  async getUserActiveSubscription(userId) {
    try {
      // ✅ SEGURANÇA: Seleciona apenas campos necessários
      const [rows] = await db.execute(
        `SELECT id, user_id, plan_id, status, start_at, end_at, provider, 
         provider_subscription_id, auto_renew, created_at, updated_at
         FROM user_subscriptions
         WHERE user_id = ? AND status = 'active' AND (end_at IS NULL OR end_at > NOW())
         ORDER BY created_at DESC
         LIMIT 1`,
        [userId]
      );
      return rows[0] || null;
    } catch (error) {
      // Se a tabela não existir ou houver erro, retorna null
      // Isso permite que o sistema continue funcionando mesmo sem a tabela de subscriptions
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_TABLE_ERROR') {
        return null;
      }
      // Re-lança outros erros para serem tratados pelo service
      throw error;
    }
  }

  async cancelSubscription(userId, subscriptionId) {
    // Cancela a assinatura específica do usuário
    const [result] = await db.execute(
      `UPDATE user_subscriptions 
       SET status = 'canceled', 
           end_at = NOW(),
           updated_at = NOW()
       WHERE id = ? AND user_id = ? AND status = 'active'`,
      [subscriptionId, userId]
    );
    
    if (result.affectedRows === 0) {
      return null;
    }

    // Retorna a assinatura cancelada
    const [rows] = await db.execute(
      'SELECT * FROM user_subscriptions WHERE id = ?',
      [subscriptionId]
    );
    
    return rows[0] || null;
  }

  async getUserSubscriptionById(subscriptionId) {
    const [rows] = await db.execute(
      'SELECT * FROM user_subscriptions WHERE id = ?',
      [subscriptionId]
    );
    return rows[0] || null;
  }

  async getAllWebhookLogs({ page = 1, perPage = 50, provider, processed }) {
    const offset = (page - 1) * perPage;
    let whereConditions = [];
    let params = [];

    if (provider) {
      whereConditions.push('provider = ?');
      params.push(provider);
    }

    if (processed !== undefined) {
      whereConditions.push('processed = ?');
      params.push(processed);
    }

    const whereClause = whereConditions.length > 0 
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    const [rows] = await db.execute(
      `SELECT * FROM payment_webhook_logs
       ${whereClause}
       ORDER BY received_at DESC
       LIMIT ? OFFSET ?`,
      [...params, perPage, offset]
    );

    const [countRows] = await db.execute(
      `SELECT COUNT(*) as total FROM payment_webhook_logs ${whereClause}`,
      params
    );

    return {
      data: rows,
      total: countRows[0]?.total || 0,
      page,
      perPage
    };
  }
}

module.exports = new PaymentsRepository();



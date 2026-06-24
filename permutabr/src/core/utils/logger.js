// /src/core/utils/logger.js
// ✅ SEGURANÇA: Logger sanitizado que remove dados sensíveis dos logs

class Logger {
  // Campos sensíveis que devem ser removidos ou mascarados
  SENSITIVE_FIELDS = [
    'senha',
    'password',
    'senha_hash',
    'password_hash',
    'token',
    'access_token',
    'refresh_token',
    'jwt',
    'authorization',
    'api_key',
    'secret',
    'secret_key',
    'private_key',
    'credit_card',
    'cvv',
    'cpf',
    'rg',
    'email' // Pode ser parcialmente mascarado
  ];

  // Sanitiza um objeto removendo ou mascarando campos sensíveis
  sanitize(data) {
    if (!data || typeof data !== 'object') {
      return data;
    }

    if (Array.isArray(data)) {
      return data.map(item => this.sanitize(item));
    }

    const sanitized = { ...data };

    for (const key in sanitized) {
      const lowerKey = key.toLowerCase();
      
      // Verifica se o campo é sensível
      const isSensitive = this.SENSITIVE_FIELDS.some(field => 
        lowerKey.includes(field) || lowerKey === field
      );

      if (isSensitive) {
        if (lowerKey.includes('email')) {
          // Mascara email parcialmente: user@domain.com -> u***@domain.com
          const email = String(sanitized[key]);
          const [local, domain] = email.split('@');
          if (local && domain) {
            sanitized[key] = `${local[0]}***@${domain}`;
          } else {
            sanitized[key] = '***';
          }
        } else if (lowerKey.includes('token') || lowerKey.includes('secret') || lowerKey.includes('key')) {
          // Remove completamente tokens e chaves
          sanitized[key] = '[REDACTED]';
        } else {
          // Mascara outros campos sensíveis
          sanitized[key] = '***';
        }
      } else if (typeof sanitized[key] === 'object' && sanitized[key] !== null) {
        // Recursivamente sanitiza objetos aninhados
        sanitized[key] = this.sanitize(sanitized[key]);
      }
    }

    return sanitized;
  }

  // Formata mensagem de log
  formatMessage(level, message, data = {}) {
    const timestamp = new Date().toISOString();
    const sanitizedData = this.sanitize(data);
    
    return {
      timestamp,
      level,
      message,
      ...sanitizedData
    };
  }

  /**
   * Logs de desenvolvimento: ENV=dev ou NODE_ENV=development (nunca ENV=prod).
   * Em produção (NODE_ENV=production sem ENV=dev), info/warn/debug/log ficam silenciosos.
   */
  get isDevLogging() {
    if (process.env.ENV === 'prod') return false;
    if (process.env.ENV === 'dev') return true;
    return process.env.NODE_ENV !== 'production';
  }

  /** @deprecated use isDevLogging */
  get isDevelopment() {
    return this.isDevLogging;
  }

  _buildDataFromArgs(args) {
    if (args.length === 0) return {};
    if (
      args.length === 1 &&
      typeof args[0] === 'object' &&
      args[0] !== null &&
      !Array.isArray(args[0])
    ) {
      return args[0];
    }
    return { detail: args.length === 1 ? args[0] : args };
  }

  log(message, ...args) {
    if (!this.isDevLogging) return;
    const logEntry = this.formatMessage('LOG', message, this._buildDataFromArgs(args));
    console.log(JSON.stringify(logEntry));
  }

  info(message, ...args) {
    if (!this.isDevLogging) return;
    const logEntry = this.formatMessage('INFO', message, this._buildDataFromArgs(args));
    console.log(JSON.stringify(logEntry));
  }

  error(message, data = {}) {
    // ERROR: Sempre loga (importante para monitoramento em produção)
    // Mas sanitiza dados sensíveis
    const logEntry = this.formatMessage('ERROR', message, data);
    console.error(JSON.stringify(logEntry));
  }

  warn(message, ...args) {
    if (!this.isDevLogging) return;
    const logEntry = this.formatMessage('WARN', message, this._buildDataFromArgs(args));
    console.warn(JSON.stringify(logEntry));
  }

  debug(message, ...args) {
    if (!this.isDevLogging) return;
    const logEntry = this.formatMessage('DEBUG', message, this._buildDataFromArgs(args));
    console.log(JSON.stringify(logEntry));
  }

  // Método para logs críticos que devem aparecer em produção (ex: erros de sistema)
  critical(message, data = {}) {
    // CRITICAL: Sempre loga, mesmo em produção
    const logEntry = this.formatMessage('CRITICAL', message, data);
    console.error(JSON.stringify(logEntry));
  }
}

module.exports = new Logger();


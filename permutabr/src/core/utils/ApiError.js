// /src/core/utils/ApiError.js

class ApiError extends Error {
  constructor(statusCode, message, details = null, code = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.code = code;
    this.name = 'ApiError';
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      status: 'error',
      message: this.message,
      ...(this.code && { code: this.code }),
      ...(this.details && { details: this.details }),
    };
  }
}

module.exports = ApiError;
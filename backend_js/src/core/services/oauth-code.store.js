// Códigos OAuth de uso único (TTL curto) — evita JWT na URL.
const crypto = require('crypto');

const TTL_MS = 120 * 1000;
const store = new Map();

function purgeExpired() {
  const now = Date.now();
  for (const [code, entry] of store.entries()) {
    if (entry.expiresAt <= now) store.delete(code);
  }
}

function createCode(payload) {
  purgeExpired();
  const code = crypto.randomBytes(32).toString('hex');
  store.set(code, {
    ...payload,
    expiresAt: Date.now() + TTL_MS,
    used: false,
  });
  return code;
}

function consumeCode(code) {
  if (!code || typeof code !== 'string') return null;
  purgeExpired();
  const entry = store.get(code);
  if (!entry || entry.used || entry.expiresAt <= Date.now()) {
    if (entry) store.delete(code);
    return null;
  }
  entry.used = true;
  store.delete(code);
  return {
    token: entry.token,
    completar: !!entry.completar,
    next: entry.next || null,
  };
}

module.exports = { createCode, consumeCode, TTL_MS };

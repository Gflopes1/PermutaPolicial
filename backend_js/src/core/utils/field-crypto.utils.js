// Criptografia AES-256-GCM para campos sensíveis em repouso (formato v1)

const crypto = require('crypto');

const VERSION_PREFIX = 'v1';
const IV_BYTES = 12;
const TAG_BYTES = 16;

function getMasterKey() {
  const raw = process.env.ENCRYPTION_MASTER_KEY;
  if (!raw) {
    throw new Error('ENCRYPTION_MASTER_KEY não configurada.');
  }
  const key = Buffer.from(raw, 'base64');
  if (key.length !== 32) {
    throw new Error('ENCRYPTION_MASTER_KEY deve ser 32 bytes codificados em base64.');
  }
  return key;
}

function encryptField(plaintext) {
  if (plaintext == null) return null;
  const text = String(plaintext);
  if (text.length === 0) return null;

  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv('aes-256-gcm', getMasterKey(), iv);
  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return [
    VERSION_PREFIX,
    iv.toString('base64'),
    authTag.toString('base64'),
    encrypted.toString('base64'),
  ].join(':');
}

function decryptField(stored) {
  if (stored == null) return null;
  const value = String(stored);
  if (value.length === 0) return null;

  const parts = value.split(':');
  if (parts.length !== 4 || parts[0] !== VERSION_PREFIX) {
    throw new Error('Formato de campo criptografado inválido ou versão não suportada.');
  }

  const iv = Buffer.from(parts[1], 'base64');
  const authTag = Buffer.from(parts[2], 'base64');
  const ciphertext = Buffer.from(parts[3], 'base64');

  if (iv.length !== IV_BYTES || authTag.length !== TAG_BYTES) {
    throw new Error('Dado criptografado adulterado (IV ou authTag inválido).');
  }

  try {
    const decipher = crypto.createDecipheriv('aes-256-gcm', getMasterKey(), iv);
    decipher.setAuthTag(authTag);
    const decrypted = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
    return decrypted.toString('utf8');
  } catch (error) {
    throw new Error('Falha ao decifrar campo sensível: dado adulterado ou chave incorreta.');
  }
}

module.exports = {
  encryptField,
  decryptField,
};

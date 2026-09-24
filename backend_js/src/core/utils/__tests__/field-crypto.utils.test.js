process.env.ENCRYPTION_MASTER_KEY = Buffer.alloc(32, 7).toString('base64');

const { encryptField, decryptField } = require('../field-crypto.utils');

describe('field-crypto.utils', () => {
  it('roundtrip encrypt/decrypt', () => {
    const plain = 'Operação sigilosa 🔒';
    const stored = encryptField(plain);
    expect(stored).toMatch(/^v1:/);
    expect(decryptField(stored)).toBe(plain);
  });

  it('null e string vazia retornam null', () => {
    expect(encryptField(null)).toBeNull();
    expect(encryptField('')).toBeNull();
    expect(decryptField(null)).toBeNull();
  });

  it('unicode/emoji roundtrip', () => {
    const plain = 'Suspeito na Rua José — café ☕';
    expect(decryptField(encryptField(plain))).toBe(plain);
  });

  it('detecta adulteração do ciphertext', () => {
    const stored = encryptField('secreto');
    const parts = stored.split(':');
    const tampered = `${parts[0]}:${parts[1]}:${parts[2]}:${parts[3].slice(0, -2)}AA`;
    expect(() => decryptField(tampered)).toThrow(/adulterado|Falha ao decifrar/);
  });
});

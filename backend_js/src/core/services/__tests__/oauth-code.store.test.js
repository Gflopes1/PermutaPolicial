const { createCode, consumeCode } = require('../oauth-code.store');

describe('oauth-code.store', () => {
  it('creates and consumes a one-time code', () => {
    const code = createCode({ token: 'jwt-test', completar: true, next: '/dashboard' });
    expect(code).toHaveLength(64);

    const payload = consumeCode(code);
    expect(payload).toEqual({
      token: 'jwt-test',
      completar: true,
      next: '/dashboard',
    });
  });

  it('rejects reuse of the same code', () => {
    const code = createCode({ token: 'jwt-test' });
    expect(consumeCode(code)).toBeTruthy();
    expect(consumeCode(code)).toBeNull();
  });
});

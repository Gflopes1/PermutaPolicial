const {
  getCachedUser,
  setCachedUser,
  invalidateUser,
} = require('../auth-user-cache');

describe('auth-user-cache', () => {
  it('stores and retrieves user within TTL', () => {
    setCachedUser(42, { id: 42, nome: 'Teste' });
    expect(getCachedUser(42)).toEqual({ id: 42, nome: 'Teste' });
  });

  it('invalidates cached user', () => {
    setCachedUser(7, { id: 7 });
    invalidateUser(7);
    expect(getCachedUser(7)).toBeNull();
  });
});

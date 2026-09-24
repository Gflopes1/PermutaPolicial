// Cache TTL curto para reduzir SELECT em cada request autenticada.
const TTL_MS = 60 * 1000;
const cache = new Map();

function cacheKey(policialId) {
  return String(policialId);
}

function getCachedUser(policialId) {
  const entry = cache.get(cacheKey(policialId));
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    cache.delete(cacheKey(policialId));
    return null;
  }
  return entry.user;
}

function setCachedUser(policialId, user) {
  cache.set(cacheKey(policialId), {
    user,
    expiresAt: Date.now() + TTL_MS,
  });
}

function invalidateUser(policialId) {
  cache.delete(cacheKey(policialId));
}

function clearAuthUserCache() {
  cache.clear();
}

module.exports = {
  TTL_MS,
  getCachedUser,
  setCachedUser,
  invalidateUser,
  clearAuthUserCache,
};

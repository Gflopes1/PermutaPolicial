const crypto = require('crypto');
const { REFERRAL_TIERS } = require('./referral.constants');

function sanitizeNamePrefix(nome) {
  const letters = String(nome || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z]/g, '')
    .toUpperCase();
  const prefix = letters.slice(0, 3);
  return prefix.length >= 2 ? prefix : 'REF';
}

function randomSuffix(length = 4) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = crypto.randomBytes(length);
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += chars[bytes[i] % chars.length];
  }
  return out;
}

function generateReferralCode(nome) {
  return `${sanitizeNamePrefix(nome)}${randomSuffix(4)}`;
}

function computeTier(verifiedCount) {
  const count = Number(verifiedCount) || 0;
  for (const entry of REFERRAL_TIERS) {
    if (count >= entry.min) {
      return {
        tier: entry.tier,
        label: entry.label,
        verified_count: count,
      };
    }
  }
  return { tier: 'usuario', label: 'Usuário', verified_count: count };
}

function getNextLevelProgress(verifiedCount) {
  const count = Number(verifiedCount) || 0;
  const thresholds = [3, 5, 10, 25, 50];
  const next = thresholds.find((t) => count < t);
  if (!next) {
    return { next_level: null, next_threshold: null, remaining: 0, progress: 1 };
  }
  const prev = thresholds[thresholds.indexOf(next) - 1] ?? 0;
  const range = next - prev;
  const current = count - prev;
  return {
    next_level: next,
    next_threshold: next,
    remaining: next - count,
    progress: Math.min(1, Math.max(0, current / range)),
  };
}

function buildReferralLink(code) {
  const { REFERRAL_BASE_URL } = require('./referral.constants');
  return `${REFERRAL_BASE_URL}/${encodeURIComponent(code)}`;
}

module.exports = {
  sanitizeNamePrefix,
  generateReferralCode,
  computeTier,
  getNextLevelProgress,
  buildReferralLink,
};

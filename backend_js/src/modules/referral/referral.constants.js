const REFERRAL_BASE_URL = process.env.REFERRAL_BASE_URL || 'https://br.permutapolicial.com.br/r';

const REFERRAL_TIERS = [
  { min: 50, tier: 'elite', label: 'Embaixador Elite' },
  { min: 25, tier: 'ouro', label: 'Embaixador Ouro' },
  { min: 10, tier: 'prata', label: 'Embaixador Prata' },
  { min: 5, tier: 'embaixador', label: 'Embaixador' },
  { min: 3, tier: 'bronze', label: 'Embaixador Bronze' },
  { min: 0, tier: 'usuario', label: 'Usuário' },
];

const REFERRAL_CAPTURE_DAYS = 30;

module.exports = {
  REFERRAL_BASE_URL,
  REFERRAL_TIERS,
  REFERRAL_CAPTURE_DAYS,
};

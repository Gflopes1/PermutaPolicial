// /src/modules/share-intention/share-intention.service.js

const sharp = require('sharp');
const db = require('../../config/db');

const BASE_URL = process.env.BASE_URL || 'https://br.permutapolicial.com.br';
const BRAND_COLOR = '#1565C0'; // Blue primary
const BRAND_DARK = '#0D47A1';

class ShareIntentionService {
  async getIntencaoDetails(intencaoId) {
    if (!intencaoId) return null;

    const [rows] = await db.execute(
      `SELECT 
        i.id, 
        i.policial_id,
        p.nome_guerra,
        f.nome as forca_nome,
        p.cargo,
        m_origem.nome as municipio_origem,
        e_origem.uf as uf_origem,
        m_destino.nome as municipio_destino,
        e_destino.uf as uf_destino,
        u_origem.nome as unidade_origem,
        u_destino.nome as unidade_destino
      FROM intencoes i
      INNER JOIN policiais p ON p.id = i.policial_id
      LEFT JOIN forcas f ON f.id = p.forca_id
      LEFT JOIN municipios m_origem ON m_origem.id = COALESCE(i.municipio_atual_id, p.municipio_atual_id)
      LEFT JOIN estados e_origem ON e_origem.id = m_origem.estado_id
      LEFT JOIN municipios m_destino ON m_destino.id = i.municipio_destino_id
      LEFT JOIN estados e_destino ON e_destino.id = m_destino.estado_id
      LEFT JOIN unidades u_origem ON u_origem.id = COALESCE(i.unidade_atual_id, p.unidade_atual_id)
      LEFT JOIN unidades u_destino ON u_destino.id = i.unidade_destino_id
      WHERE i.id = ?
      LIMIT 1`,
      [intencaoId]
    );

    return rows[0] || null;
  }

  async getPermutasConcluidas() {
    try {
      const [[result]] = await db.execute('SELECT COUNT(*) as count FROM permutas_concluidas_feedback');
      return result?.count || 217; // fallback
    } catch {
      return 217;
    }
  }

  async buildShareLandingHTML(code, intencaoId) {
    const intencao = await this.getIntencaoDetails(intencaoId);
    const permutasCount = await this.getPermutasConcluidas();

    let ogTitle = 'Permuta Policial — Encontre sua permuta';
    let ogDescription = `Plataforma para permutas entre agentes de segurança. ${permutasCount}+ permutas concluídas.`;

    if (intencao) {
      const origem = intencao.municipio_origem
        ? `${intencao.municipio_origem}-${intencao.uf_origem}`
        : intencao.unidade_origem || 'origem';
      const destino = intencao.municipio_destino
        ? `${intencao.municipio_destino}-${intencao.uf_destino}`
        : intencao.unidade_destino || 'destino';

      ogTitle = `Procuro permuta: ${origem} → ${destino}`;
      ogDescription = `${intencao.forca_nome || 'Agente'} procura permuta de ${origem} para ${destino}. Cadastre-se no Permuta Policial!`;
    }

    const imageUrl = intencaoId
      ? `${BASE_URL}/r/${code}/preview.png?i=${intencaoId}`
      : `${BASE_URL}/r/${code}/preview.png`;

    const registerUrl = `${BASE_URL}/auth?ref=${code}`;

    return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${ogTitle}</title>
  
  <!-- Open Graph / Facebook -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${BASE_URL}/r/${code}${intencaoId ? '?i=' + intencaoId : ''}">
  <meta property="og:title" content="${ogTitle}">
  <meta property="og:description" content="${ogDescription}">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  
  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:url" content="${BASE_URL}/r/${code}${intencaoId ? '?i=' + intencaoId : ''}">
  <meta name="twitter:title" content="${ogTitle}">
  <meta name="twitter:description" content="${ogDescription}">
  <meta name="twitter:image" content="${imageUrl}">
  
  <meta http-equiv="refresh" content="0;url=${registerUrl}">
</head>
<body>
  <p>Redirecionando para cadastro...</p>
  <p>Se não for redirecionado, <a href="${registerUrl}">clique aqui</a>.</p>
</body>
</html>`;
  }

  async generatePreviewImage(code, intencaoId) {
    const intencao = await this.getIntencaoDetails(intencaoId);
    const permutasCount = await this.getPermutasConcluidas();

    let titleText = 'Procuro permuta';
    let subtitleText = 'Cadastre-se no Permuta Policial';
    let routeText = '';

    if (intencao) {
      const origem = intencao.municipio_origem
        ? `${intencao.municipio_origem}-${intencao.uf_origem}`
        : intencao.unidade_origem || 'origem';
      const destino = intencao.municipio_destino
        ? `${intencao.municipio_destino}-${intencao.uf_destino}`
        : intencao.unidade_destino || 'destino';

      titleText = `Procuro permuta`;
      routeText = `${origem} → ${destino}`;
      subtitleText = intencao.forca_nome || 'Agente de segurança';
    }

    // Criar SVG (1200x630) — renderizado via sharp
    const svg = `
<svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
  <!-- Background gradient -->
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${BRAND_COLOR};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${BRAND_DARK};stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#grad)" />
  
  <!-- Logo placeholder (circle) -->
  <circle cx="600" cy="120" r="50" fill="white" opacity="0.9" />
  <text x="600" y="135" font-family="Arial, sans-serif" font-size="32" font-weight="bold" fill="${BRAND_COLOR}" text-anchor="middle">PP</text>
  
  <!-- Title -->
  <text x="600" y="240" font-family="Arial, sans-serif" font-size="48" font-weight="bold" fill="white" text-anchor="middle">${titleText}</text>
  
  <!-- Route (large) -->
  ${routeText ? `<text x="600" y="320" font-family="Arial, sans-serif" font-size="56" font-weight="bold" fill="white" text-anchor="middle">${routeText}</text>` : ''}
  
  <!-- Subtitle -->
  <text x="600" y="390" font-family="Arial, sans-serif" font-size="32" fill="white" opacity="0.9" text-anchor="middle">${subtitleText}</text>
  
  <!-- Social proof -->
  <text x="600" y="480" font-family="Arial, sans-serif" font-size="28" fill="white" opacity="0.85" text-anchor="middle">${permutasCount}+ permutas concluídas</text>
  
  <!-- CTA -->
  <rect x="450" y="520" width="300" height="60" rx="8" fill="white" opacity="0.95" />
  <text x="600" y="560" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="${BRAND_COLOR}" text-anchor="middle">Cadastre-se</text>
</svg>`;

    const buffer = await sharp(Buffer.from(svg))
      .png()
      .toBuffer();

    return buffer;
  }
}

module.exports = new ShareIntentionService();

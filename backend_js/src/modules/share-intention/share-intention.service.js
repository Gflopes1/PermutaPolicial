// /src/modules/share-intention/share-intention.service.js
//
// Landing pública /r/:code (link de indicação) com Open Graph dinâmico + imagem
// /r/:code/preview.png gerada via sharp.
//
// Privacidade: NUNCA expor nome, nome de guerra, telefone, e-mail ou id funcional.
// Apenas força (sigla), posto/graduação, cidade de origem e destino da intenção.

const fs = require('fs').promises;
const path = require('path');
const sharp = require('sharp');
const db = require('../../config/db');
const { isAllowedFrontendOrigin, normalizeOrigin } = require('../../core/utils/frontend-url.utils');

const DEFAULT_BASE_URL = 'https://br.permutapolicial.com.br';
const BRAND_COLOR = '#1565C0';
const BRAND_DARK = '#0D47A1';
// Fonte genérica: librsvg (sharp) resolve via fontconfig. DejaVu Sans existe na maioria das
// distros (fonts-dejavu-core / dejavu-sans-fonts); fallback para sans-serif.
const FONT_FAMILY = "'DejaVu Sans', 'Liberation Sans', Arial, Helvetica, sans-serif";

const CODE_REGEX = /^[A-Za-z0-9]{3,12}$/;

const PREVIEW_CACHE_TTL_MS = 10 * 60 * 1000;
const PREVIEW_CACHE_MAX = 300;
const STATS_CACHE_TTL_MS = 60 * 60 * 1000;

const previewCache = new Map();
let statsCache = { value: null, expiresAt: 0 };

function escapeXml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

const escapeHtml = escapeXml;

function normalizeCode(code) {
  const c = String(code || '').trim();
  return CODE_REGEX.test(c) ? c.toUpperCase() : null;
}

function normalizeIntencaoId(raw) {
  if (raw === undefined || raw === null || raw === '') return null;
  if (!/^\d{1,10}$/.test(String(raw))) return null;
  const n = parseInt(raw, 10);
  return Number.isSafeInteger(n) && n > 0 ? n : null;
}

/**
 * Base pública (https://host) para og:url/og:image. Usa o host da requisição quando ele
 * pertence aos frontends permitidos (prod/dev); senão FRONTEND_URL/BASE_URL; senão prod.
 */
function resolveBaseUrl(req) {
  const host = req && typeof req.get === 'function' ? req.get('host') : null;
  if (host) {
    const candidate = `https://${host}`;
    if (isAllowedFrontendOrigin(candidate)) return normalizeOrigin(candidate);
  }
  for (const raw of [process.env.FRONTEND_URL, process.env.BASE_URL]) {
    const origin = normalizeOrigin(raw);
    if (origin && origin.startsWith('https://')) return origin;
  }
  return DEFAULT_BASE_URL;
}

function resolveFlutterWebRoot() {
  if (process.env.FLUTTER_WEB_ROOT) return process.env.FLUTTER_WEB_ROOT;
  return path.resolve(__dirname, '../../../../permuta_policial/build/web');
}

function lugar(nome, uf, mostrarUf) {
  if (!nome) return null;
  return mostrarUf && uf ? `${nome}-${uf}` : nome;
}

class ShareIntentionService {
  async findCodeOwner(code) {
    const [rows] = await db.execute(
      'SELECT user_id FROM referral_codes WHERE code = ? LIMIT 1',
      [code]
    );
    return rows[0]?.user_id ?? null;
  }

  /** Intenção somente se pertencer ao dono do código. Sem dados pessoais. */
  async findIntencaoForOwner(intencaoId, ownerId) {
    const [rows] = await db.execute(
      `SELECT
         i.id,
         i.tipo_intencao,
         p.ocultar_no_mapa,
         f.sigla AS forca_sigla,
         pg.nome AS posto_nome,
         m_o.nome AS origem_nome,
         e_o.sigla AS origem_uf,
         e_d.sigla AS destino_estado_uf,
         m_d.nome AS destino_municipio_nome,
         e_md.sigla AS destino_municipio_uf,
         u_d.nome AS destino_unidade_nome,
         m_ud.nome AS destino_unidade_municipio,
         e_ud.sigla AS destino_unidade_uf
       FROM intencoes i
       JOIN policiais p ON p.id = i.policial_id
       LEFT JOIN forcas_policiais f ON f.id = p.forca_id
       LEFT JOIN postos_graduacoes pg ON pg.id = p.posto_graduacao_id
       LEFT JOIN unidades u_lot ON u_lot.id = p.unidade_atual_id
       LEFT JOIN municipios m_o ON m_o.id = COALESCE(p.municipio_atual_id, u_lot.municipio_id, i.municipio_atual_id)
       LEFT JOIN estados e_o ON e_o.id = m_o.estado_id
       LEFT JOIN estados e_d ON e_d.id = i.estado_id
       LEFT JOIN municipios m_d ON m_d.id = i.municipio_id
       LEFT JOIN estados e_md ON e_md.id = m_d.estado_id
       LEFT JOIN unidades u_d ON u_d.id = i.unidade_id
       LEFT JOIN municipios m_ud ON m_ud.id = u_d.municipio_id
       LEFT JOIN estados e_ud ON e_ud.id = m_ud.estado_id
       WHERE i.id = ? AND i.policial_id = ?
       LIMIT 1`,
      [intencaoId, ownerId]
    );
    const row = rows[0];
    if (!row) return null;
    // Usuário que optou por ficar oculto no mapa: não expor detalhes da intenção.
    if (Number(row.ocultar_no_mapa) === 1) return null;
    return row;
  }

  async getVerifiedCount() {
    const now = Date.now();
    if (statsCache.value !== null && statsCache.expiresAt > now) return statsCache.value;
    try {
      const [[row]] = await db.execute(
        "SELECT COUNT(*) AS total FROM policiais WHERE status_verificacao = 'VERIFICADO'"
      );
      const total = Number(row?.total || 0);
      statsCache = { value: total, expiresAt: now + STATS_CACHE_TTL_MS };
      return total;
    } catch (_) {
      return 0;
    }
  }

  /**
   * Resolve o contexto de compartilhamento. Nunca lança por dados ausentes/erro de DB:
   * cai para conteúdo genérico (o link precisa funcionar sempre).
   */
  async resolveContext(rawCode, rawIntencaoId) {
    const code = normalizeCode(rawCode);
    const intencaoId = normalizeIntencaoId(rawIntencaoId);
    const ctx = { code: null, intencaoId: null, info: null };
    if (!code) return ctx;

    try {
      const ownerId = await this.findCodeOwner(code);
      if (!ownerId) return ctx;
      ctx.code = code;
      if (intencaoId) {
        const row = await this.findIntencaoForOwner(intencaoId, ownerId);
        if (row) {
          ctx.intencaoId = intencaoId;
          ctx.info = this.describe(row);
        }
      }
    } catch (err) {
      console.error('[share-intention] Falha ao resolver contexto:', err.message);
      // DB indisponível: mantém o código (o app Flutter valida na landing)
      if (!ctx.code) ctx.code = code;
    }
    return ctx;
  }

  describe(row) {
    let destinoUf = null;
    if (row.tipo_intencao === 'UNIDADE' && row.destino_unidade_nome) destinoUf = row.destino_unidade_uf;
    else if (row.tipo_intencao === 'MUNICIPIO' && row.destino_municipio_nome) destinoUf = row.destino_municipio_uf;
    else destinoUf = row.destino_estado_uf;

    // UF só quando interestadual (ex.: PF/PRF), para textos curtos
    const interestadual = !!(row.origem_uf && destinoUf && row.origem_uf !== destinoUf);
    const origem = lugar(row.origem_nome, row.origem_uf, interestadual);

    let destino = null;
    if (row.tipo_intencao === 'UNIDADE' && row.destino_unidade_nome) {
      const cidade = lugar(row.destino_unidade_municipio, destinoUf, interestadual);
      destino = cidade ? `${row.destino_unidade_nome} (${cidade})` : row.destino_unidade_nome;
    } else if (row.tipo_intencao === 'MUNICIPIO' && row.destino_municipio_nome) {
      destino = lugar(row.destino_municipio_nome, destinoUf, interestadual);
    } else if (row.destino_estado_uf) {
      destino = `o estado ${row.destino_estado_uf}`;
    }

    const forca = row.forca_sigla || null;
    const posto = row.posto_nome || null;
    const quem = forca ? (posto ? `${forca} (${posto})` : forca) : posto;

    let frase = 'Procuro permuta';
    if (quem && origem) frase = `Sou ${quem} em ${origem} e procuro permuta`;
    else if (quem) frase = `Sou ${quem} e procuro permuta`;
    else if (origem) frase = `Estou em ${origem} e procuro permuta`;
    if (destino) frase += ` para ${destino}`;

    return { quem, origem, destino, frase };
  }

  buildMeta(ctx, baseUrl) {
    const qs = ctx.intencaoId ? `?i=${ctx.intencaoId}` : '';
    const codePath = ctx.code ? `/r/${ctx.code}` : '/';
    const pageUrl = ctx.code ? `${baseUrl}${codePath}${qs}` : baseUrl;
    const imageUrl = ctx.code
      ? `${baseUrl}/r/${ctx.code}/preview.png${qs}`
      : `${baseUrl}/icons/Icon-512.png`;
    const registerUrl = ctx.code
      ? `${baseUrl}/auth/register?ref=${encodeURIComponent(ctx.code)}`
      : `${baseUrl}/auth/register`;

    const title = ctx.info
      ? ctx.info.frase
      : 'Permuta Policial — encontre sua permuta';
    const description = ctx.info
      ? 'Se você quer vir para cá, cadastre-se no Permuta Policial e veja as permutas compatíveis. Grátis.'
      : 'Plataforma que conecta agentes de segurança que querem trocar de lotação. Cadastre-se grátis.';

    return { title, description, pageUrl, imageUrl, registerUrl };
  }

  metaBlock(meta, { withRefresh }) {
    const e = escapeHtml;
    const lines = [
      `<title>${e(meta.title)}</title>`,
      `<meta name="description" content="${e(meta.description)}">`,
      '<meta name="robots" content="noindex, follow">',
      '<meta property="og:type" content="website">',
      '<meta property="og:site_name" content="Permuta Policial">',
      '<meta property="og:locale" content="pt_BR">',
      `<meta property="og:url" content="${e(meta.pageUrl)}">`,
      `<meta property="og:title" content="${e(meta.title)}">`,
      `<meta property="og:description" content="${e(meta.description)}">`,
      `<meta property="og:image" content="${e(meta.imageUrl)}">`,
      `<meta property="og:image:secure_url" content="${e(meta.imageUrl)}">`,
      '<meta property="og:image:type" content="image/png">',
      '<meta property="og:image:width" content="1200">',
      '<meta property="og:image:height" content="630">',
      '<meta name="twitter:card" content="summary_large_image">',
      `<meta name="twitter:title" content="${e(meta.title)}">`,
      `<meta name="twitter:description" content="${e(meta.description)}">`,
      `<meta name="twitter:image" content="${e(meta.imageUrl)}">`,
    ];
    if (withRefresh) {
      lines.push(`<meta http-equiv="refresh" content="0;url=${e(meta.registerUrl)}">`);
    } else {
      // Sem JS (raro): manda direto para o cadastro com ref
      lines.push(`<noscript><meta http-equiv="refresh" content="0;url=${e(meta.registerUrl)}"></noscript>`);
    }
    return lines.join('\n  ');
  }

  injectIntoIndex(template, meta) {
    const cleaned = template
      .replace(/<title>[\s\S]*?<\/title>\s*/i, '')
      .replace(/<meta\s+(?:property|name)\s*=\s*"(?:og:[^"]*|twitter:[^"]*|description|robots)"[^>]*>\s*/gi, '');
    const block = this.metaBlock(meta, { withRefresh: false });
    if (/<\/head>/i.test(cleaned)) {
      return cleaned.replace(/<\/head>/i, `  ${block}\n</head>`);
    }
    return null;
  }

  fallbackHtml(meta) {
    const e = escapeHtml;
    return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${this.metaBlock(meta, { withRefresh: true })}
</head>
<body style="font-family:sans-serif;text-align:center;padding:2rem;">
  <p>Redirecionando para o cadastro…</p>
  <p><a href="${e(meta.registerUrl)}">Clique aqui se não for redirecionado</a>.</p>
</body>
</html>`;
  }

  /**
   * HTML da landing /r/:code.
   * Preferência: index.html do Flutter Web (FLUTTER_WEB_ROOT) com metas OG injetadas — o app
   * abre a rota /r/:code (ReferralLandingScreen: valida código, salva ref, registra clique,
   * redireciona para /auth/register?ref=CODE). Fallback: HTML mínimo com meta refresh para
   * /auth/register?ref=CODE (o wizard de cadastro salva o ref a partir da query).
   * @returns {{ html: string, flutter: boolean }}
   */
  async buildShareLandingHTML(rawCode, rawIntencaoId, req) {
    const ctx = await this.resolveContext(rawCode, rawIntencaoId);
    const meta = this.buildMeta(ctx, resolveBaseUrl(req));

    if (ctx.code) {
      try {
        const template = await fs.readFile(path.join(resolveFlutterWebRoot(), 'index.html'), 'utf8');
        const html = this.injectIntoIndex(template, meta);
        if (html) return { html, flutter: true };
      } catch (_) {
        // sem build Flutter acessível: usa fallback
      }
    }
    return { html: this.fallbackHtml(meta), flutter: false };
  }

  buildSvg(info, verifiedCount) {
    const lines = [];
    const text = (y, size, content, { bold = false, opacity = 1, color = 'white' } = {}) =>
      `<text x="600" y="${y}" font-family="${FONT_FAMILY}" font-size="${size}"${bold ? ' font-weight="bold"' : ''} fill="${color}"${opacity < 1 ? ` fill-opacity="${opacity}"` : ''} text-anchor="middle">${escapeXml(content)}</text>`;
    const fit = (str, max, min, width = 1100) => {
      // Aproximação: largura média ~0.64em (bold) por caractere
      const size = Math.floor(width / (Math.max(1, String(str).length) * 0.64));
      return Math.max(min, Math.min(max, size));
    };
    const clip = (str, maxLen) => (str.length > maxLen ? `${str.slice(0, maxLen - 1)}…` : str);

    lines.push(text(95, 34, 'PERMUTA POLICIAL', { bold: true, opacity: 0.9 }));

    if (info) {
      lines.push(text(185, 52, 'Procuro permuta', { bold: true }));
      if (info.quem) {
        const quem = clip(info.quem, 48);
        lines.push(text(250, fit(quem, 38, 26), quem, { opacity: 0.92 }));
      }
      const origem = clip(info.origem || 'Minha lotação', 48);
      const destino = clip(String(info.destino || 'Novo destino').replace(/^o estado /, ''), 48);
      const oneLine = `${origem} → ${destino}`;
      if (oneLine.length <= 34) {
        lines.push(text(360, fit(oneLine, 60, 40), oneLine, { bold: true }));
      } else {
        lines.push(text(340, fit(origem, 52, 30), origem, { bold: true }));
        lines.push(text(410, fit(`→ ${destino}`, 52, 30), `→ ${destino}`, { bold: true }));
      }
      lines.push(text(475, 28, 'Quer vir para cá? Vamos trocar!', { opacity: 0.9 }));
    } else {
      lines.push(text(230, 60, 'Encontre sua permuta', { bold: true }));
      lines.push(text(310, 32, 'Matches diretos, triangulares e por proximidade', { opacity: 0.92 }));
      if (verifiedCount >= 100) {
        const fmt = verifiedCount.toLocaleString('pt-BR');
        lines.push(text(400, 30, `${fmt}+ agentes verificados`, { opacity: 0.9 }));
      }
    }

    return `<svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="${BRAND_COLOR}"/>
      <stop offset="100%" stop-color="${BRAND_DARK}"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#grad)"/>
  ${lines.join('\n  ')}
  <rect x="420" y="515" width="360" height="66" rx="10" fill="white" fill-opacity="0.95"/>
  <text x="600" y="559" font-family="${FONT_FAMILY}" font-size="28" font-weight="bold" fill="${BRAND_COLOR}" text-anchor="middle">Cadastre-se grátis</text>
</svg>`;
  }

  async generatePreviewImage(rawCode, rawIntencaoId) {
    const ctx = await this.resolveContext(rawCode, rawIntencaoId);
    const key = `${ctx.code || '-'}:${ctx.intencaoId || '-'}`;
    const now = Date.now();
    const cached = previewCache.get(key);
    if (cached && cached.expiresAt > now) return cached.buffer;

    const verifiedCount = ctx.info ? 0 : await this.getVerifiedCount();
    const svg = this.buildSvg(ctx.info, verifiedCount);
    const buffer = await sharp(Buffer.from(svg, 'utf8')).png({ compressionLevel: 9 }).toBuffer();

    if (previewCache.size >= PREVIEW_CACHE_MAX) {
      previewCache.delete(previewCache.keys().next().value);
    }
    previewCache.set(key, { buffer, expiresAt: now + PREVIEW_CACHE_TTL_MS });
    return buffer;
  }
}

const service = new ShareIntentionService();
service._internals = { escapeXml, normalizeCode, normalizeIntencaoId, resolveBaseUrl };
module.exports = service;

/**
 * Gera sitemap.xml (índice), sitemap-landings.xml, sitemap-static.xml e robots.txt
 * para deploy estático no Cloudflare (raiz do domínio).
 *
 * Uso: node landings/scripts/generate-sitemap.js
 */

const fs = require('fs');
const path = require('path');

const BASE = 'https://br.permutapolicial.com.br';
const LASTMOD = new Date().toISOString().slice(0, 10);
const OUT = path.join(__dirname, '../public');

const LANDINGS = [
  { path: '/app/pm.html', label: 'Polícia Militar' },
  { path: '/app/bm.html', label: 'Bombeiros Militares' },
  { path: '/app/pc.html', label: 'Polícia Civil' },
  { path: '/app/prf.html', label: 'PRF' },
  { path: '/app/pf.html', label: 'Polícia Federal' },
  { path: '/app/gm.html', label: 'Guarda Municipal' },
];

const STATIC_PAGES = [
  { path: '/', changefreq: 'weekly', priority: '1.0', comment: 'Página principal (Flutter Web)' },
  { path: '/auth', changefreq: 'monthly', priority: '0.8', comment: 'Autenticação' },
  { path: '/landing', changefreq: 'monthly', priority: '0.8', comment: 'Landing in-app' },
  { path: '/mapa/visitante', changefreq: 'weekly', priority: '0.8', comment: 'Mapa público' },
  { path: '/help.html', changefreq: 'monthly', priority: '0.7', comment: 'Central de Ajuda (HTML)' },
  { path: '/help.md', changefreq: 'monthly', priority: '0.6', comment: 'Central de Ajuda (Markdown)' },
  { path: '/termos.html', changefreq: 'yearly', priority: '0.6', comment: 'Termos de Uso (HTML)' },
  { path: '/termos.md', changefreq: 'yearly', priority: '0.5', comment: 'Termos de Uso (Markdown)' },
  { path: '/privacidade.html', changefreq: 'yearly', priority: '0.6', comment: 'Política de Privacidade (HTML)' },
  { path: '/privacidade.md', changefreq: 'yearly', priority: '0.5', comment: 'Política de Privacidade (Markdown)' },
];

function urlEntry({ path: loc, changefreq, priority }) {
  return `  <url>
    <loc>${BASE}${loc}</loc>
    <lastmod>${LASTMOD}</lastmod>
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
  </url>`;
}

function urlset(entries, comments = []) {
  const body = entries
    .map((entry, i) => {
      const comment = comments[i] ? `\n  <!-- ${comments[i]} -->` : '';
      return `${comment}\n${urlEntry(entry)}`;
    })
    .join('\n');

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${body}
</urlset>
`;
}

function sitemapIndex(files) {
  const entries = files
    .map(
      (file) => `  <sitemap>
    <loc>${BASE}/${file}</loc>
    <lastmod>${LASTMOD}</lastmod>
  </sitemap>`
    )
    .join('\n');

  return `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${entries}
</sitemapindex>
`;
}

const robotsTxt = `# Permuta Policial — robots.txt (Cloudflare)
User-agent: *
Allow: /
Allow: /app/
Allow: /help.html
Allow: /help.md
Allow: /termos.html
Allow: /termos.md
Allow: /privacidade.html
Allow: /privacidade.md
Allow: /llms.txt
Allow: /llms-full.txt
Allow: /mapa/visitante

# Áreas privadas / API (SPA — não indexar)
Disallow: /api/
Disallow: /admin
Disallow: /dashboard
Disallow: /meus-dados
Disallow: /completar-perfil
Disallow: /notificacoes
Disallow: /chat/
Disallow: /_next/

# Sitemap index (Cloudflare / Google Search Console)
Sitemap: ${BASE}/sitemap.xml
`;

function main() {
  if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

  const landingsXml = urlset(
    LANDINGS.map((l) => ({ path: l.path, changefreq: 'monthly', priority: '0.9' })),
    LANDINGS.map((l) => l.label)
  );

  const staticXml = urlset(
    STATIC_PAGES.map(({ path: p, changefreq, priority }) => ({ path: p, changefreq, priority })),
    STATIC_PAGES.map((p) => p.comment)
  );

  const indexXml = sitemapIndex(['sitemap-static.xml', 'sitemap-landings.xml']);

  fs.writeFileSync(path.join(OUT, 'sitemap.xml'), indexXml, 'utf8');
  fs.writeFileSync(path.join(OUT, 'sitemap-landings.xml'), landingsXml, 'utf8');
  fs.writeFileSync(path.join(OUT, 'sitemap-static.xml'), staticXml, 'utf8');
  fs.writeFileSync(path.join(OUT, 'robots.txt'), robotsTxt, 'utf8');

  console.log('✅ sitemap.xml (índice)');
  console.log('✅ sitemap-static.xml');
  console.log('✅ sitemap-landings.xml');
  console.log('✅ robots.txt');
  console.log(`   lastmod: ${LASTMOD}`);
}

main();

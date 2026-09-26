const SITE = 'https://br.permutapolicial.com.br';
const LOGO = `${SITE}/assets/logo_tatico.png`;
const API = `${SITE}/api`;
const FONT_BASE = '/app/fonts';
const CSP = [
  "default-src 'self'",
  "script-src 'self' https://unpkg.com https://static.cloudflareinsights.com",
  "style-src 'self' 'unsafe-inline' https://unpkg.com",
  `img-src 'self' data: ${SITE} https://*.tile.openstreetmap.org https://tile.openstreetmap.org https://a.tile.openstreetmap.org https://b.tile.openstreetmap.org https://c.tile.openstreetmap.org https://unpkg.com`,
  "font-src 'self'",
  `connect-src 'self' ${SITE} https://*.tile.openstreetmap.org https://tile.openstreetmap.org https://cloudflareinsights.com`,
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ');

const INTER_FONTS = `
    @font-face {
      font-family: 'Inter';
      font-style: normal;
      font-weight: 400;
      font-display: swap;
      src: url('${FONT_BASE}/inter-latin-400-normal.woff2') format('woff2');
      unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
    }
    @font-face {
      font-family: 'Inter';
      font-style: normal;
      font-weight: 600;
      font-display: swap;
      src: url('${FONT_BASE}/inter-latin-600-normal.woff2') format('woff2');
      unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
    }
    @font-face {
      font-family: 'Inter';
      font-style: normal;
      font-weight: 700;
      font-display: swap;
      src: url('${FONT_BASE}/inter-latin-700-normal.woff2') format('woff2');
      unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
    }`;

const PLATFORM_FEATURES = [
  { icon: '⇄', title: 'Matches Diretos', desc: 'Encontre colegas que querem exatamente a sua lotação e você quer a deles.' },
  { icon: '△', title: 'Permutas Triangulares', desc: 'Ciclos de 3 policiais formando cadeia A→B→C→A automaticamente.' },
  { icon: '◎', title: 'Match por Proximidade', desc: 'Compatibilidade por raio em km quando a unidade exata não coincide.' },
  { icon: '◉', title: 'Motor Inteligente', desc: 'Também encontra ciclos com 4 ou mais participantes quando não há match direto, ordenados por compatibilidade.' },
  { icon: '🗺', title: 'Mapa de Permutas', desc: 'Visualize demanda e oferta agregadas por município em todo o Brasil.' },
  { icon: '📍', title: 'Até 3 Intenções', desc: 'Cadastre prioridades de destino por estado, município ou unidade.' },
  { icon: '👁', title: 'Interessados', desc: 'Veja quem quer ir para a sua região, mesmo sem match direto.' },
  { icon: '🔒', title: 'Contato Seguro', desc: 'Solicitação de contato, chat anônimo e compartilhamento controlado de dados.' },
  { icon: '✓', title: 'Perfis Verificados', desc: 'Verificação de identidade para garantir acesso apenas a agentes reais.' },
  { icon: '🛡', title: 'Mapa Tático', desc: 'Mapa colaborativo operacional para equipes (Beta).' },
  { icon: '📋', title: 'Hub de Editais', desc: 'Editais de formação e transferência com simulador de escolha de vagas.' },
  { icon: '📝', title: 'Questões & Simulados', desc: 'Banco de questões e simulados para concursos e provas.' },
  { icon: '🛒', title: 'Marketplace', desc: 'Compra e venda de equipamentos entre profissionais de segurança.' },
  { icon: '📅', title: 'Gestor de Escalas', desc: 'Organize escalas, soldo e compromissos operacionais.' },
  { icon: '🎁', title: 'Programa de Indicação', desc: 'Indique colegas e acompanhe metas por corporação.' },
  { icon: '💬', title: 'Fórum', desc: 'Comunidade para troca de experiências entre agentes.' },
];

const STEPS = [
  { n: '1', title: 'Crie sua conta', desc: 'Cadastro gratuito com verificação de identidade.' },
  { n: '2', title: 'Informe lotação e intenções', desc: 'Onde você está e até 3 destinos desejados.' },
  { n: '3', title: 'Receba matches', desc: 'Diretos, triangulares, por proximidade ou ciclos N-way.' },
  { n: '4', title: 'Entre em contato', desc: 'Solicite contato de forma segura e negocie a permuta.' },
];

function escapeHtmlAttr(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;');
}

function generateHTML(forceId, data) {
  const authUrl = `${SITE}/auth`;
  const mapaUrl = `${SITE}/mapa/visitante`;
  // Forças federais: permuta pode ser interestadual (ex.: PRF Manaus-AM -> Porto Velho-RO)
  const isFederal = ['PF', 'PRF'].includes(data.tipoPermuta);
  const estadoDestinoField = isFederal
    ? `
            <div class="form-group" style="grid-column:1/-1;">
              <label for="estadoDestino">UF do destino (se for outro estado)</label>
              <input type="text" id="estadoDestino" name="estadoDestino" placeholder="Ex: RO" maxlength="2" pattern="[A-Za-z]{2}" style="text-transform:uppercase;">
            </div>`
    : '';
  const featuresHTML = PLATFORM_FEATURES.map(
    (f) => `
      <article class="feature-card">
        <div class="feature-icon">${f.icon}</div>
        <h3>${f.title}</h3>
        <p>${f.desc}</p>
      </article>`
  ).join('');

  const stepsHTML = STEPS.map(
    (s) => `
      <div class="step-card">
        <span class="step-num">${s.n}</span>
        <h3>${s.title}</h3>
        <p>${s.desc}</p>
      </div>`
  ).join('');

  const toolsHTML = [
    { title: 'Ambiente de Permutas', desc: 'Motor clássico + inteligente unificados', href: `${SITE}/permutas`, tag: 'Principal' },
    { title: 'Mapa Visitante', desc: 'Explore o mapa sem login', href: mapaUrl, tag: 'Público' },
    { title: 'Editais', desc: 'Simulador de escolha de vagas', href: `${SITE}/editais`, tag: 'Premium' },
    { title: 'Marketplace', desc: 'Equipamentos entre agentes', href: `${SITE}/marketplace`, tag: '' },
  ].map(
    (t) => `
      <a href="${t.href}" class="tool-card">
        ${t.tag ? `<span class="tool-tag">${t.tag}</span>` : ''}
        <h3>${t.title}</h3>
        <p>${t.desc}</p>
      </a>`
  ).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtmlAttr(data.name)} - Permuta Policial | Plataforma de Permutas</title>
  <meta name="description" content="${escapeHtmlAttr(data.metaDescription)}">
  <link rel="canonical" href="${SITE}/app/${forceId}.html">
  <meta property="og:url" content="${SITE}/app/${forceId}.html">
  <meta property="og:title" content="${escapeHtmlAttr(data.name)} - Permuta Policial">
  <meta property="og:description" content="${escapeHtmlAttr(data.metaDescription)}">
  <meta property="og:image" content="${LOGO}">
  <meta http-equiv="Content-Security-Policy" content="${escapeHtmlAttr(CSP)}">
  <link rel="icon" href="${LOGO}" type="image/png">
  <link rel="preload" href="${FONT_BASE}/inter-latin-400-normal.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
  <style>
    ${INTER_FONTS}
    :root {
      --primary: ${data.primary};
      --primary-dark: ${data.primaryDark};
      --primary-light: ${data.primaryLight};
      --secondary: ${data.secondary};
      --bg: ${data.background};
      --text: #1a202c;
      --muted: #64748b;
      --card: #ffffff;
      --border: rgba(15, 28, 46, 0.1);
      --shadow: 0 4px 24px rgba(15, 28, 46, 0.08);
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      font-family: 'Inter', system-ui, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
    }
    .container { max-width: 1140px; margin: 0 auto; padding: 0 1.25rem; }
    a { color: inherit; text-decoration: none; }

    /* Header */
    .header {
      position: sticky; top: 0; z-index: 1000;
      background: rgba(15, 28, 46, 0.97);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid rgba(255,255,255,0.08);
    }
    .header-inner {
      display: flex; align-items: center; justify-content: space-between;
      padding: 0.75rem 0; gap: 1rem;
    }
    .brand { display: flex; align-items: center; gap: 0.75rem; }
    .brand img { width: 44px; height: 44px; object-fit: contain; }
    .brand-text h1 { color: #fff; font-size: 1.05rem; font-weight: 700; line-height: 1.2; }
    .brand-text span { color: rgba(255,255,255,0.65); font-size: 0.75rem; }
    .nav-desktop { display: none; align-items: center; gap: 1.5rem; }
    .nav-desktop a { color: rgba(255,255,255,0.85); font-size: 0.9rem; font-weight: 600; transition: color .2s; }
    .nav-desktop a:hover { color: #fff; }
    .btn {
      display: inline-flex; align-items: center; justify-content: center; gap: 0.4rem;
      padding: 0.65rem 1.25rem; border-radius: 10px; font-weight: 600; font-size: 0.9rem;
      border: none; cursor: pointer; transition: transform .15s, opacity .15s, box-shadow .15s;
    }
    .btn:hover { transform: translateY(-1px); }
    .btn-primary { background: var(--secondary); color: #fff; box-shadow: 0 4px 14px rgba(0,0,0,0.2); }
    .btn-outline { background: transparent; color: #fff; border: 1.5px solid rgba(255,255,255,0.35); }
    .btn-dark { background: var(--primary); color: #fff; }
    .btn-lg { padding: 0.9rem 1.75rem; font-size: 1rem; border-radius: 12px; }
    .menu-btn {
      display: flex; background: none; border: none; color: #fff;
      font-size: 1.5rem; cursor: pointer; padding: 0.25rem;
    }
    .nav-mobile {
      display: none; flex-direction: column; gap: 0.5rem;
      padding: 0 0 1rem;
    }
    .nav-mobile.open { display: flex; }
    .nav-mobile a {
      color: rgba(255,255,255,0.9); padding: 0.6rem 0.5rem;
      border-bottom: 1px solid rgba(255,255,255,0.06); font-weight: 600;
    }

    /* Hero */
    .hero {
      background: linear-gradient(145deg, var(--primary-dark) 0%, var(--primary) 55%, #1e3a5f 100%);
      color: #fff; padding: 4rem 0 5rem; position: relative; overflow: hidden;
    }
    .hero::before {
      content: ''; position: absolute; inset: 0;
      background: radial-gradient(circle at 80% 20%, rgba(255,255,255,0.06) 0%, transparent 50%);
    }
    .hero-grid {
      display: grid; gap: 2.5rem; align-items: center; position: relative;
    }
    .hero-badge {
      display: inline-block; background: rgba(255,255,255,0.12);
      border: 1px solid rgba(255,255,255,0.2); border-radius: 999px;
      padding: 0.35rem 0.9rem; font-size: 0.8rem; font-weight: 600;
      margin-bottom: 1rem; letter-spacing: 0.02em;
    }
    .hero h2 {
      font-size: clamp(1.75rem, 5vw, 2.75rem); font-weight: 700;
      line-height: 1.15; margin-bottom: 1rem;
    }
    .hero-lead { font-size: 1.05rem; color: rgba(255,255,255,0.82); max-width: 540px; margin-bottom: 1.75rem; }
    .hero-actions { display: flex; flex-wrap: wrap; gap: 0.75rem; }
    .hero-stats {
      display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem;
      margin-top: 2rem; padding-top: 2rem; border-top: 1px solid rgba(255,255,255,0.12);
    }
    .hero-stat strong { display: block; font-size: 1.5rem; font-weight: 700; }
    .hero-stat span { font-size: 0.78rem; color: rgba(255,255,255,0.65); }

    /* Sections */
    section { padding: 4rem 0; }
    .section-head { text-align: center; max-width: 640px; margin: 0 auto 2.5rem; }
    .section-head h2 { font-size: clamp(1.5rem, 4vw, 2rem); font-weight: 700; color: var(--primary-dark); margin-bottom: 0.5rem; }
    .section-head p { color: var(--muted); font-size: 1rem; }
    .section-alt { background: rgba(15, 28, 46, 0.03); }

    /* Features grid */
    .features-grid {
      display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1rem;
    }
    .feature-card {
      background: var(--card); border: 1px solid var(--border); border-radius: 14px;
      padding: 1.25rem; box-shadow: var(--shadow); transition: transform .2s, box-shadow .2s;
    }
    .feature-card:hover { transform: translateY(-3px); box-shadow: 0 8px 32px rgba(15,28,46,0.12); }
    .feature-icon {
      width: 40px; height: 40px; border-radius: 10px;
      background: linear-gradient(135deg, var(--primary), var(--primary-light));
      color: #fff; display: flex; align-items: center; justify-content: center;
      font-size: 1.1rem; margin-bottom: 0.75rem;
    }
    .feature-card h3 { font-size: 0.95rem; font-weight: 700; margin-bottom: 0.35rem; color: var(--primary-dark); }
    .feature-card p { font-size: 0.82rem; color: var(--muted); line-height: 1.5; }

    /* Map section */
    .map-panel {
      background: var(--card); border-radius: 18px; border: 1px solid var(--border);
      box-shadow: var(--shadow); overflow: hidden;
    }
    .map-toolbar {
      display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between;
      gap: 0.75rem; padding: 1rem 1.25rem; border-bottom: 1px solid var(--border);
      background: rgba(15,28,46,0.02);
    }
    .map-tabs { display: flex; gap: 0.4rem; flex-wrap: wrap; }
    .map-tab {
      padding: 0.45rem 0.9rem; border-radius: 8px; border: 1px solid var(--border);
      background: #fff; font-size: 0.82rem; font-weight: 600; cursor: pointer;
      color: var(--muted); transition: all .15s;
    }
    .map-tab.active { background: var(--primary); color: #fff; border-color: var(--primary); }
    .map-status { font-size: 0.78rem; color: var(--muted); }
    #mapPreview { height: 420px; background: #e2e8f0; }
    .map-legend {
      display: flex; flex-wrap: wrap; gap: 1rem; padding: 0.85rem 1.25rem;
      font-size: 0.78rem; color: var(--muted); border-top: 1px solid var(--border);
    }
    .legend-dot {
      display: inline-block; width: 10px; height: 10px; border-radius: 50%;
      margin-right: 0.35rem; vertical-align: middle;
    }

    /* Simulator */
    .sim-grid { display: grid; gap: 1.5rem; }
    .sim-form {
      background: var(--card); border-radius: 18px; border: 1px solid var(--border);
      padding: 1.5rem; box-shadow: var(--shadow);
    }
    .sim-form h3 { font-size: 1.1rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 0.35rem; }
    .sim-form > p { font-size: 0.85rem; color: var(--muted); margin-bottom: 1.25rem; }
    .form-row { display: grid; gap: 0.75rem; margin-bottom: 0.75rem; }
    .form-group label { display: block; font-size: 0.78rem; font-weight: 600; color: var(--primary-dark); margin-bottom: 0.3rem; }
    .form-group input, .form-group select {
      width: 100%; padding: 0.65rem 0.85rem; border: 1px solid var(--border);
      border-radius: 10px; font-size: 0.9rem; font-family: inherit;
      background: #fff; transition: border-color .15s;
    }
    .form-group input:focus, .form-group select:focus {
      outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(26,54,93,0.12);
    }
    .sim-results {
      background: var(--card); border-radius: 18px; border: 1px solid var(--border);
      padding: 1.5rem; box-shadow: var(--shadow); min-height: 280px;
    }
    .sim-results.empty { display: flex; align-items: center; justify-content: center; text-align: center; color: var(--muted); font-size: 0.9rem; }
    .match-item {
      border: 1px solid var(--border); border-radius: 12px; padding: 1rem;
      margin-bottom: 0.75rem; background: rgba(15,28,46,0.02);
    }
    .match-item:last-child { margin-bottom: 0; }
    .match-type {
      display: inline-block; font-size: 0.7rem; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.04em; padding: 0.2rem 0.55rem; border-radius: 6px; margin-bottom: 0.5rem;
    }
    .match-type.direct { background: #dcfce7; color: #166534; }
    .match-type.triangle { background: #dbeafe; color: #1e40af; }
    .match-type.interest { background: #fef3c7; color: #92400e; }
    .match-item h4 { font-size: 0.9rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 0.25rem; }
    .match-item p { font-size: 0.82rem; color: var(--muted); }
    .sim-loading { text-align: center; padding: 2rem; color: var(--muted); }
    .sim-loading .spinner {
      width: 36px; height: 36px; border: 3px solid var(--border);
      border-top-color: var(--primary); border-radius: 50%;
      animation: spin 0.8s linear infinite; margin: 0 auto 1rem;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .sim-cta {
      margin-top: 1rem; padding: 1rem; border-radius: 12px;
      background: linear-gradient(135deg, var(--primary-dark), var(--primary));
      color: #fff; text-align: center;
    }
    .sim-cta p { font-size: 0.85rem; margin-bottom: 0.75rem; opacity: 0.9; }
    .sim-stats { display: grid; gap: 1rem; }
    .sim-stat {
      border: 1px solid var(--border); border-radius: 14px; padding: 1.25rem;
      text-align: center; background: rgba(15,28,46,0.02);
    }
    .sim-stat strong {
      display: block; font-size: 2rem; font-weight: 700; color: var(--primary-dark);
      line-height: 1.1; margin-bottom: 0.35rem;
    }
    .sim-stat span { font-size: 0.85rem; color: var(--muted); }

    /* Steps */
    .steps-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
    .step-card {
      background: var(--card); border-radius: 14px; padding: 1.25rem;
      border: 1px solid var(--border); text-align: center; box-shadow: var(--shadow);
    }
    .step-num {
      display: inline-flex; width: 36px; height: 36px; border-radius: 50%;
      background: var(--primary); color: #fff; font-weight: 700; font-size: 0.9rem;
      align-items: center; justify-content: center; margin-bottom: 0.75rem;
    }
    .step-card h3 { font-size: 0.95rem; font-weight: 700; margin-bottom: 0.35rem; }
    .step-card p { font-size: 0.82rem; color: var(--muted); }

    /* Security */
    .security-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
    .security-card {
      background: var(--card); border-radius: 14px; padding: 1.5rem;
      border-top: 4px solid var(--secondary); box-shadow: var(--shadow); text-align: center;
    }
    .security-card .emoji { font-size: 2rem; margin-bottom: 0.75rem; }
    .security-card h3 { font-size: 1rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 0.4rem; }
    .security-card p { font-size: 0.85rem; color: var(--muted); }

    /* Tools */
    .tools-grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
    .tool-card {
      background: var(--card); border: 1px solid var(--border); border-radius: 14px;
      padding: 1.25rem; box-shadow: var(--shadow); transition: transform .2s, border-color .2s;
      position: relative;
    }
    .tool-card:hover { transform: translateY(-2px); border-color: var(--primary-light); }
    .tool-tag {
      position: absolute; top: 0.75rem; right: 0.75rem;
      font-size: 0.65rem; font-weight: 700; text-transform: uppercase;
      background: var(--primary); color: #fff; padding: 0.15rem 0.45rem; border-radius: 4px;
    }
    .tool-card h3 { font-size: 0.95rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 0.3rem; }
    .tool-card p { font-size: 0.82rem; color: var(--muted); }

    /* Why + CTA */
    .why-block {
      background: linear-gradient(135deg, var(--primary-dark), var(--primary));
      color: #fff; border-radius: 18px; padding: 2.5rem 2rem; text-align: center;
    }
    .why-block h2 { font-size: clamp(1.4rem, 3vw, 1.85rem); font-weight: 700; margin-bottom: 1rem; }
    .why-block p { font-size: 1rem; opacity: 0.88; max-width: 680px; margin: 0 auto; line-height: 1.7; }
    .cta-block {
      background: var(--card); border-radius: 18px; border: 1px solid var(--border);
      padding: 2.5rem 2rem; text-align: center; box-shadow: var(--shadow);
      border-top: 4px solid var(--secondary);
    }
    .cta-block h2 { font-size: 1.75rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 0.5rem; }
    .cta-block p { color: var(--muted); margin-bottom: 1.5rem; }
    .cta-actions { display: flex; flex-wrap: wrap; gap: 0.75rem; justify-content: center; }

    /* Footer */
    .footer {
      background: var(--primary-dark); color: rgba(255,255,255,0.75);
      padding: 3rem 0 1.5rem; font-size: 0.85rem;
    }
    .footer-grid { display: grid; gap: 2rem; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); margin-bottom: 2rem; }
    .footer h3 { color: #fff; font-size: 0.95rem; font-weight: 700; margin-bottom: 0.75rem; }
    .footer-links { list-style: none; }
    .footer-links li { margin-bottom: 0.4rem; }
    .footer-links a { color: rgba(255,255,255,0.65); transition: color .15s; }
    .footer-links a:hover { color: #fff; }
    .footer-bottom {
      border-top: 1px solid rgba(255,255,255,0.1); padding-top: 1.25rem;
      display: flex; flex-wrap: wrap; gap: 0.5rem 1.5rem; justify-content: space-between;
      font-size: 0.78rem; color: rgba(255,255,255,0.45);
    }

    @media (min-width: 768px) {
      .nav-desktop { display: flex; }
      .menu-btn { display: none; }
      .hero-grid { grid-template-columns: 1fr 1fr; }
      .form-row { grid-template-columns: 1fr 1fr; }
      .sim-grid { grid-template-columns: 1fr 1fr; align-items: start; }
    }
    @media (min-width: 1024px) {
      .form-row.triple { grid-template-columns: 1fr 1fr 1fr; }
    }
  </style>
</head>
<body data-force="${forceId}" data-force-name="${data.name}" data-tipo-permuta="${data.tipoPermuta}" data-api-base="${API}" data-auth-url="${authUrl}" data-primary="${data.primary}">

  <header class="header">
    <div class="container">
      <div class="header-inner">
        <a href="${SITE}" class="brand">
          <img src="${LOGO}" alt="Permuta Policial" width="44" height="44" loading="lazy" decoding="async">
          <div class="brand-text">
            <h1>Permuta Policial</h1>
            <span>${data.name}</span>
          </div>
        </a>
        <nav class="nav-desktop">
          <a href="#features">Funcionalidades</a>
          <a href="#mapa">Mapa</a>
          <a href="#simulador">Simulador</a>
          <a href="${authUrl}">Entrar</a>
          <a href="${authUrl}" class="btn btn-primary">Criar Conta Grátis</a>
        </nav>
        <button class="menu-btn" id="menuButton" aria-expanded="false" aria-label="Menu">☰</button>
      </div>
      <nav class="nav-mobile" id="navMenu">
        <a href="#features">Funcionalidades</a>
        <a href="#mapa">Mapa</a>
        <a href="#simulador">Simulador</a>
        <a href="${authUrl}">Entrar</a>
        <a href="${authUrl}">Criar Conta Grátis</a>
      </nav>
    </div>
  </header>

  <section class="hero">
    <div class="container">
      <div class="hero-grid">
        <div>
          <span class="hero-badge">${data.name} · Plataforma Nacional</span>
          <h2>${data.headline}</h2>
          <p class="hero-lead">${data.description}</p>
          <div class="hero-actions">
            <a href="${authUrl}" class="btn btn-primary btn-lg">Criar Conta Grátis</a>
            <a href="#simulador" class="btn btn-outline btn-lg">Simular Permuta</a>
          </div>
          <div class="hero-stats">
            <div class="hero-stat"><strong>10+</strong><span>Funcionalidades</span></div>
            <div class="hero-stat"><strong id="unitCount">—</strong><span>Unidades ativas</span></div>
            <div class="hero-stat"><strong id="userCount">—</strong><span>Usuários verificados</span></div>
          </div>
        </div>
        <div class="map-panel" style="box-shadow: 0 20px 60px rgba(0,0,0,0.3);">
          <div class="map-toolbar" style="padding: 0.75rem 1rem;">
            <strong style="font-size: 0.85rem; color: var(--primary-dark);">Prévia do Mapa de Permutas</strong>
            <a href="${mapaUrl}" class="btn btn-dark" style="padding: 0.4rem 0.8rem; font-size: 0.78rem;">Abrir mapa completo</a>
          </div>
          <div id="mapHero" style="height: 280px; background: #e2e8f0;"></div>
        </div>
      </div>
    </div>
  </section>

  <section id="features">
    <div class="container">
      <div class="section-head">
        <h2>Tudo que a plataforma oferece</h2>
        <p>Do match inteligente ao marketplace — uma solução completa para agentes de segurança pública.</p>
      </div>
      <div class="features-grid">${featuresHTML}</div>
    </div>
  </section>

  <section id="mapa" class="section-alt">
    <div class="container">
      <div class="section-head">
        <h2>Mapa de Permutas em tempo real</h2>
        <p>Atividade agregada de intenções de permuta. Dados reais, sem identificação individual.</p>
      </div>
      <div class="map-panel">
        <div class="map-toolbar">
          <strong style="font-size:0.85rem;color:var(--primary-dark);">Atividade por região</strong>
          <span class="map-status" id="mapStatus">Carregando mapa…</span>
        </div>
        <div id="mapPreview"></div>
        <div class="map-legend">
          <span><span class="legend-dot" style="background:var(--primary);"></span>Intenções de permuta</span>
          <span>Tamanho do marcador = volume de atividade na região</span>
        </div>
      </div>
    </div>
  </section>

  <section id="simulador">
    <div class="container">
      <div class="section-head">
        <h2>Simule sua permuta</h2>
        <p>Informe sua lotação atual e destino desejado. Resultados agregados — identidades protegidas.</p>
      </div>
      <div class="sim-grid">
        <form class="sim-form" id="searchForm">
          <h3>Simulação para ${data.name}</h3>
          <p>Estimativa com base no motor de permutas. Cadastre-se para ver contatos e detalhes reais.</p>
          <div class="form-row triple">
            <div class="form-group">
              <label for="cidadeAtual">Cidade / Unidade atual</label>
              <input type="text" id="cidadeAtual" name="cidadeAtual" placeholder="Ex: Campinas" required>
            </div>
            <div class="form-group">
              <label for="cidadeDestino">Destino desejado</label>
              <input type="text" id="cidadeDestino" name="cidadeDestino" placeholder="Ex: Santos" required>
            </div>
            <div class="form-group">
              <label for="estado">${isFederal ? 'UF atual *' : 'Estado (UF) *'}</label>
              <input type="text" id="estado" name="estado" placeholder="Ex: SP" maxlength="2" pattern="[A-Za-z]{2}" autocomplete="address-level1" required style="text-transform:uppercase;">
            </div>${estadoDestinoField}
          </div>
          <button type="submit" class="btn btn-dark btn-lg" style="width:100%; margin-top:0.5rem;">Simular compatibilidade</button>
        </form>
        <div class="sim-results empty" id="searchFeedback">
          Preencha o formulário para ver quantas permutas são possíveis e quantos colegas demonstram interesse na sua região (raio de 50 km).
        </div>
      </div>
    </div>
  </section>

  <section class="section-alt">
    <div class="container">
      <div class="section-head">
        <h2>Como funciona</h2>
        <p>Quatro passos simples para encontrar sua permuta ideal.</p>
      </div>
      <div class="steps-grid">${stepsHTML}</div>
    </div>
  </section>

  <section>
    <div class="container">
      <div class="section-head">
        <h2>Segurança e confiança</h2>
        <p>Plataforma independente, em conformidade com a legislação brasileira.</p>
      </div>
      <div class="security-grid">
        <div class="security-card">
          <div class="emoji">🔒</div>
          <h3>Perfis autenticados</h3>
          <p>Verificação de usuários para a liberação do acesso às funcionalidades.</p>
        </div>
        <div class="security-card">
          <div class="emoji">⚖️</div>
          <h3>Conformidade legal</h3>
          <p>Sem uso de símbolos oficiais. Site independente, sem vínculo governamental.</p>
        </div>
        <div class="security-card">
          <div class="emoji">🛡️</div>
          <h3>Privacidade controlada</h3>
          <p>Opção de ocultar dados no mapa até aceitar compartilhar contato.</p>
        </div>
      </div>
    </div>
  </section>

  <section class="section-alt">
    <div class="container">
      <div class="section-head">
        <h2>Acesse também</h2>
        <p>Ferramentas complementares disponíveis na plataforma.</p>
      </div>
      <div class="tools-grid">${toolsHTML}</div>
    </div>
  </section>

  <section>
    <div class="container">
      <div class="why-block">
        <h2>Por que ${data.name} usa o Permuta Policial?</h2>
        <p>${data.whyBenefit}</p>
      </div>
    </div>
  </section>

  <section>
    <div class="container">
      <div class="cta-block">
        <h2>Pronto para encontrar sua permuta?</h2>
        <p>Junte-se à comunidade de agentes que já usam a plataforma.</p>
        <div class="cta-actions">
          <a href="${authUrl}" class="btn btn-dark btn-lg">Criar Conta Grátis</a>
          <a href="${mapaUrl}" class="btn btn-outline btn-lg" style="color:var(--primary);border-color:var(--primary);">Explorar Mapa</a>
        </div>
      </div>
    </div>
  </section>

  <footer class="footer">
    <div class="container">
      <div class="footer-grid">
        <div>
          <h3>Permuta Policial</h3>
          <p>Plataforma brasileira feita para conectar agentes de segurança pública e viabilizar permutas de forma mais rápida e inteligente.</p>
        </div>
        <div>
          <h3>Corporações</h3>
          <ul class="footer-links">
            <li><a href="${SITE}/app/pm.html">Polícia Militar</a></li>
            <li><a href="${SITE}/app/bm.html">Bombeiros Militares</a></li>
            <li><a href="${SITE}/app/pc.html">Polícia Civil</a></li>
            <li><a href="${SITE}/app/prf.html">PRF</a></li>
            <li><a href="${SITE}/app/pf.html">Polícia Federal</a></li>
            <li><a href="${SITE}/app/gm.html">Guarda Municipal</a></li>
          </ul>
        </div>
        <div>
          <h3>Links</h3>
          <ul class="footer-links">
            <li><a href="${authUrl}">Criar Conta</a></li>
            <li><a href="${mapaUrl}">Mapa Visitante</a></li>
            <li><a href="${SITE}/help.html">Central de Ajuda</a></li>
            <li><a href="${SITE}/termos.html">Termos de Uso</a></li>
          </ul>
        </div>
      </div>
      <div class="footer-bottom">
        <span>© <span id="currentYear"></span> Permuta Policial. Todos os direitos reservados.</span>
        <span>Site independente, sem vínculo governamental.</span>
      </div>
    </div>
  </footer>

  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin="" defer></script>
  <script src="/app/landing.js" defer></script>
  <script src="/version-check.js" defer></script>
</body>
</html>`;
}

module.exports = { generateHTML, PLATFORM_FEATURES };

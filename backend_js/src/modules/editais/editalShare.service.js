const fs = require('fs').promises;
const path = require('path');
const editaisRepository = require('./editais.repository');

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function getBaseUrl() {
  // FRONTEND_URL é o domínio público onde o link /edital/:id é compartilhado
  return (process.env.FRONTEND_URL || process.env.BASE_URL || 'https://br.permutapolicial.com.br')
    .replace(/\/$/, '');
}

function resolveFlutterWebRoot() {
  if (process.env.FLUTTER_WEB_ROOT) {
    return process.env.FLUTTER_WEB_ROOT;
  }

  return path.resolve(__dirname, '../../../../permuta_policial/build/web');
}

async function readIndexTemplate() {
  const indexPath = path.join(resolveFlutterWebRoot(), 'index.html');
  return fs.readFile(indexPath, 'utf8');
}

function replaceMeta(html, matcher, replacement) {
  if (matcher.test(html)) {
    return html.replace(matcher, replacement);
  }
  return html.replace('</head>', `${replacement}\n</head>`);
}

function buildDescription(edital, stats) {
  const tipo = edital.tipo === 'TRANSFERENCIA_INTERNA' ? 'transferência interna' : 'formação';
  const forca = edital.forca_nome || edital.forca_sigla || 'força policial';
  const partes = [
    `Consulte sua classificação no edital de ${tipo} da ${forca}.`,
    `${stats.total_vagas} vagas em ${stats.total_unidades} cidades.`,
    `${stats.total_participantes} candidatos na lista`,
    `e ${stats.total_intencoes} intenções já registradas.`,
    'Grátis e sem login.',
  ];

  if (edital.criterio_label) {
    partes.splice(1, 0, `Critério: ${edital.criterio_label}.`);
  }

  return partes.join(' ');
}

function buildTitle(edital) {
  const sigla = edital.forca_sigla ? ` · ${edital.forca_sigla}` : '';
  return `${edital.titulo}${sigla} | Permuta Policial`;
}

function injectShareMeta(html, { title, description, imageUrl, pageUrl }) {
  let output = html;

  output = replaceMeta(
    output,
    /<title>[^<]*<\/title>/,
    `<title>${escapeHtml(title)}</title>`
  );

  output = replaceMeta(
    output,
    /<meta name="description" content="[^"]*">/,
    `<meta name="description" content="${escapeHtml(description)}">`
  );

  const ogFields = {
    'og:title': title,
    'og:description': description,
    'og:image': imageUrl,
    'og:url': pageUrl,
  };

  for (const [property, value] of Object.entries(ogFields)) {
    output = replaceMeta(
      output,
      new RegExp(`<meta property="${property}" content="[^"]*">`),
      `<meta property="${property}" content="${escapeHtml(value)}">`
    );
  }

  output = replaceMeta(
    output,
    /<meta name="twitter:title" content="[^"]*">/,
    `<meta name="twitter:title" content="${escapeHtml(title)}">`
  );
  output = replaceMeta(
    output,
    /<meta name="twitter:description" content="[^"]*">/,
    `<meta name="twitter:description" content="${escapeHtml(description)}">`
  );
  output = replaceMeta(
    output,
    /<meta name="twitter:image" content="[^"]*">/,
    `<meta name="twitter:image" content="${escapeHtml(imageUrl)}">`
  );

  return output;
}

function buildFallbackHtml({ title, description, imageUrl, pageUrl }) {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeHtml(description)}">
  <meta property="og:title" content="${escapeHtml(title)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:image" content="${escapeHtml(imageUrl)}">
  <meta property="og:url" content="${escapeHtml(pageUrl)}">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Permuta Policial">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeHtml(title)}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <meta name="twitter:image" content="${escapeHtml(imageUrl)}">
  <link rel="icon" type="image/png" href="/favicon.png">
</head>
<body style="margin:0;background:#181A20;">
  <script src="/flutter_bootstrap.js" async></script>
</body>
</html>`;
}

class EditalShareService {
  async buildShareHtml(editalId) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital || edital.status === 'RASCUNHO') {
      return null;
    }

    const stats = await editaisRepository.getResumoPublico(editalId);
    const baseUrl = getBaseUrl();
    const pageUrl = `${baseUrl}/edital/${editalId}`;
    const imageUrl = `${baseUrl}/icons/ic_launcher.png`;
    const title = buildTitle(edital);
    const description = buildDescription(edital, stats);
    const meta = { title, description, imageUrl, pageUrl };

    try {
      const template = await readIndexTemplate();
      return injectShareMeta(template, meta);
    } catch (_) {
      return buildFallbackHtml(meta);
    }
  }
}

module.exports = new EditalShareService();

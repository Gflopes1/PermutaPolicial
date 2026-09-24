#!/usr/bin/env node

/**
 * Atualiza versão no index.html e gera version.json para detecção de deploy.
 *
 * Uso:
 *   node update-version.js           — antes do flutter build (web/)
 *   node update-version.js --post-build — após flutter build (build/web/)
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

const isPostBuild = process.argv.includes('--post-build');
const baseDir = __dirname;
const webDir = isPostBuild
  ? path.join(baseDir, 'build', 'web')
  : path.join(baseDir, 'web');

const pubspecPath = path.join(baseDir, 'pubspec.yaml');
const indexHtmlPath = path.join(webDir, 'index.html');
const versionJsonPath = path.join(webDir, 'version.json');
const mainJsPath = path.join(webDir, 'main.dart.js');

function getGitCommit() {
  try {
    return execSync('git rev-parse --short HEAD', {
      cwd: baseDir,
      stdio: ['ignore', 'pipe', 'ignore'],
    })
      .toString()
      .trim();
  } catch (_) {
    return null;
  }
}

function readMainJsFingerprint() {
  if (!fs.existsSync(mainJsPath)) {
    return null;
  }
  const buf = fs.readFileSync(mainJsPath);
  return {
    mainJsSize: buf.length,
    mainJsSha256: crypto.createHash('sha256').update(buf).digest('hex').slice(0, 16),
  };
}

function patchMainJsPartCacheBust(mainJsPath, buildId) {
  if (!fs.existsSync(mainJsPath)) {
    console.warn('⚠️ main.dart.js não encontrado para patch de .part.js');
    return;
  }

  let js = fs.readFileSync(mainJsPath, 'utf8');
  const needle = '{createScriptURL:a=>a}';
  const safeBuildId = JSON.stringify(buildId);
  const replacement =
    '{createScriptURL:a=>a.indexOf(".part.js")>=0?a+(a.indexOf("?")>=0?"&":"?")+"_v="+encodeURIComponent(' +
    safeBuildId +
    '):a}';

  if (!js.includes(needle)) {
    console.warn('⚠️ Padrão createScriptURL não encontrado em main.dart.js (patch .part.js ignorado).');
    return;
  }

  js = js.replace(needle, replacement);
  fs.writeFileSync(mainJsPath, js, 'utf8');
}

function patchFlutterBootstrapTag(indexHtml, buildId) {
  const bust = encodeURIComponent(buildId);
  const bootstrapRegex =
    /<script\s+src="flutter_bootstrap\.js(?:\?[^"]*)?"\s+async="?"><\/script>/;

  if (bootstrapRegex.test(indexHtml)) {
    return indexHtml.replace(
      bootstrapRegex,
      `<script src="flutter_bootstrap.js?v=${bust}" async=""></script>`
    );
  }

  return indexHtml.replace(
    /<script\s+src="flutter_bootstrap\.js"\s+async=""><\/script>/,
    `<script src="flutter_bootstrap.js?v=${bust}" async=""></script>`
  );
}

function patchVersionCheckTag(indexHtml, buildId) {
  const bust = encodeURIComponent(buildId);
  const versionCheckRegex = /<script\s+src="version-check\.js(?:\?[^"]*)?"><\/script>/;

  if (versionCheckRegex.test(indexHtml)) {
    return indexHtml.replace(
      versionCheckRegex,
      `<script src="version-check.js?v=${bust}"></script>`
    );
  }

  return indexHtml.replace(
    /<script\s+src="version-check\.js"><\/script>/,
    `<script src="version-check.js?v=${bust}"></script>`
  );
}

function patchFlutterBootstrapMainJs(buildId) {
  const bootstrapPath = path.join(webDir, 'flutter_bootstrap.js');
  if (!fs.existsSync(bootstrapPath)) {
    console.warn('⚠️ flutter_bootstrap.js não encontrado para patch de mainJsPath');
    return;
  }

  let js = fs.readFileSync(bootstrapPath, 'utf8');
  const bust = buildId.replace(/['"\\]/g, '\\$&'); // Escape quotes

  // Patch 1: buildConfig.mainJsPath com ?v=buildId
  const buildConfigRegex = /("mainJsPath"\s*:\s*"main\.dart\.js")/;
  if (buildConfigRegex.test(js)) {
    js = js.replace(
      buildConfigRegex,
      `"mainJsPath":"main.dart.js?v=${bust}"`
    );
  }

  // Patch 2: Se houver _flutter.loader.load() direto, adiciona config
  const loaderLoadRegex = /(_flutter\.loader\.load\(\s*)\)/;
  if (loaderLoadRegex.test(js) && !js.includes('entrypointUrl')) {
    js = js.replace(
      loaderLoadRegex,
      `$1{config:{entrypointUrl:"main.dart.js?v=${bust}"}})`
    );
  }

  fs.writeFileSync(bootstrapPath, js, 'utf8');
  console.log(`   ✓ flutter_bootstrap.js patched: main.dart.js?v=${buildId}`);
}

function loadExistingVersionPayload() {
  if (!fs.existsSync(versionJsonPath)) {
    return null;
  }
  try {
    return JSON.parse(fs.readFileSync(versionJsonPath, 'utf8'));
  } catch (_) {
    return null;
  }
}

try {
  if (isPostBuild && !fs.existsSync(webDir)) {
    console.error('❌ build/web não encontrado. Rode flutter build web antes do --post-build.');
    process.exit(1);
  }

  let fullVersion;
  let build;
  let buildId;
  let builtAt;

  const existing = isPostBuild ? loadExistingVersionPayload() : null;

  if (isPostBuild && existing && existing.buildId) {
    fullVersion = existing.version;
    build = existing.build;
    buildId = existing.buildId;
    builtAt = existing.builtAt || new Date().toISOString();
  } else {
    const pubspecContent = fs.readFileSync(pubspecPath, 'utf8');
    const versionMatch = pubspecContent.match(/^version:\s*(.+)$/m);
    if (!versionMatch) {
      console.error('❌ Erro: Não foi possível encontrar a versão no pubspec.yaml');
      process.exit(1);
    }

    const fullVersionRaw = versionMatch[1].trim();
    fullVersion = fullVersionRaw.split('+')[0];
    build = fullVersionRaw.split('+')[1];

    if (!fullVersion || !build) {
      console.error('❌ Erro: Formato de versão inválido. Esperado: X.Y.Z+BUILD');
      process.exit(1);
    }

    const commit = getGitCommit();
    buildId = commit
      ? `${fullVersionRaw}-${commit}-${Date.now()}`
      : `${fullVersionRaw}-${Date.now()}`;
    builtAt = new Date().toISOString();
  }

  if (!fs.existsSync(indexHtmlPath)) {
    console.error(`❌ index.html não encontrado: ${indexHtmlPath}`);
    process.exit(1);
  }

  let indexHtml = fs.readFileSync(indexHtmlPath, 'utf8');

  if (!isPostBuild) {
    const versionMetaRegex = /<meta\s+name="app-version"\s+content="[^"]*">/;
    const buildMetaRegex = /<meta\s+name="app-build"\s+content="[^"]*">/;
    const buildIdMetaRegex = /<meta\s+name="app-build-id"\s+content="[^"]*">/;

    if (!versionMetaRegex.test(indexHtml)) {
      console.error('❌ Erro: Meta tag app-version não encontrada no index.html');
      process.exit(1);
    }

    if (!buildMetaRegex.test(indexHtml)) {
      console.error('❌ Erro: Meta tag app-build não encontrada no index.html');
      process.exit(1);
    }

    indexHtml = indexHtml.replace(
      versionMetaRegex,
      `<meta name="app-version" content="${fullVersion}+${build}">`
    );

    indexHtml = indexHtml.replace(
      buildMetaRegex,
      `<meta name="app-build" content="${build}">`
    );

    const fullVersionRaw = `${fullVersion}+${build}`;

    if (buildIdMetaRegex.test(indexHtml)) {
      indexHtml = indexHtml.replace(
        buildIdMetaRegex,
        `<meta name="app-build-id" content="${buildId}">`
      );
    } else {
      indexHtml = indexHtml.replace(
        buildMetaRegex,
        `<meta name="app-build" content="${build}">\n  <meta name="app-build-id" content="${buildId}">`
      );
    }

    const embedScript = `<script>window.__permutaAppBuild=${JSON.stringify({
      version: fullVersionRaw,
      build,
      buildId,
      builtAt,
    })};</script>`;

    if (indexHtml.includes('window.__permutaAppBuild')) {
      indexHtml = indexHtml.replace(
        /<script>window\.__permutaAppBuild=[^<]*<\/script>/,
        embedScript
      );
    } else {
      indexHtml = indexHtml.replace(
        /<meta\s+name="app-build-id"\s+content="[^"]*">/,
        `$&\n  ${embedScript}`
      );
    }
  }

  indexHtml = patchFlutterBootstrapTag(indexHtml, buildId);
  indexHtml = patchVersionCheckTag(indexHtml, buildId);
  fs.writeFileSync(indexHtmlPath, indexHtml, 'utf8');

  // Patch em main.dart.js ANTES do fingerprint — senão mainJsSize fica errado e
  // version-check.js entra em loop de "nova versão" + reload automático.
  if (isPostBuild) {
    patchMainJsPartCacheBust(mainJsPath, buildId);
    patchFlutterBootstrapMainJs(buildId);
  }

  const versionPayload = {
    version: `${fullVersion}+${build}`,
    build,
    buildId,
    builtAt,
    ...(readMainJsFingerprint() || {}),
  };

  fs.writeFileSync(versionJsonPath, `${JSON.stringify(versionPayload, null, 2)}\n`, 'utf8');

  if (isPostBuild) {
    const sourceVersionJson = path.join(baseDir, 'web', 'version.json');
    fs.writeFileSync(sourceVersionJson, `${JSON.stringify(versionPayload, null, 2)}\n`, 'utf8');
  }

  console.log(`✅ Versão atualizada (${isPostBuild ? 'post-build' : 'pre-build'})!`);
  console.log(`   Versão: ${versionPayload.version}`);
  console.log(`   Build ID: ${buildId}`);
  if (versionPayload.mainJsSize) {
    console.log(`   main.dart.js: ${versionPayload.mainJsSize} bytes (sha ${versionPayload.mainJsSha256})`);
  }
  console.log(`   Arquivos: ${indexHtmlPath}, ${versionJsonPath}`);
} catch (error) {
  console.error('❌ Erro ao atualizar versão:', error.message);
  process.exit(1);
}

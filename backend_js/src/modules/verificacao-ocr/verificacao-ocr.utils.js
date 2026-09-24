const { isValidMatricula } = require('../../core/config/matricula-regex.config');

function normalizeName(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function levenshtein(a, b) {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;

  const matrix = Array.from({ length: b.length + 1 }, (_, i) => [i]);
  for (let j = 0; j <= a.length; j += 1) matrix[0][j] = j;

  for (let i = 1; i <= b.length; i += 1) {
    for (let j = 1; j <= a.length; j += 1) {
      const cost = b.charAt(i - 1) === a.charAt(j - 1) ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      );
    }
  }
  return matrix[b.length][a.length];
}

function namePartsMatch(nomeCadastrado, source) {
  const exp = normalizeName(nomeCadastrado);
  const norm = normalizeName(source);
  if (!exp || !norm) return false;
  const parts = exp.split(' ').filter((p) => p.length > 2);
  return parts.length >= 2 && parts.every((p) => norm.includes(p));
}

function namesMatch(nomeCadastrado, nomeExtraido) {
  const a = normalizeName(nomeCadastrado);
  const b = normalizeName(nomeExtraido);
  if (!a || !b) return false;
  if (a === b) return true;

  // Um nome contém o outro (ex.: "João Silva" vs "JOAO DA SILVA SANTOS")
  if (a.includes(b) || b.includes(a)) return true;
  if (namePartsMatch(nomeCadastrado, nomeExtraido)) return true;

  const maxLen = Math.max(a.length, b.length);
  const distance = levenshtein(a, b);
  const threshold = Math.max(2, Math.floor(maxLen * 0.15));
  return distance <= threshold;
}

function normalizeMatricula(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '');
}

function matriculasMatch(matriculaCadastrada, matriculaExtraida) {
  const expected = normalizeMatricula(matriculaCadastrada);
  const captured = normalizeMatricula(matriculaExtraida);
  if (!expected || expected.length < 4 || !captured) return false;
  if (expected === captured) return true;
  // Id esperada presente no que o OCR capturou (mesmo com outros números ao redor).
  if (captured.includes(expected)) return true;
  if (expected.includes(captured) && captured.length >= 4) return true;
  return false;
}

function matchFromSources(matcher, ...sources) {
  const seen = new Set();
  for (const source of sources) {
    const value = String(source || '').trim();
    if (!value || seen.has(value)) continue;
    seen.add(value);
    if (matcher(value)) return true;
  }
  return false;
}

function buildOcrCorpus({
  nomeExtraido,
  matriculaExtraida,
  forcaExtraida,
  cargoExtraido,
  ocrRawText,
}) {
  return [nomeExtraido, matriculaExtraida, forcaExtraida, cargoExtraido, ocrRawText]
    .map((v) => String(v || '').trim())
    .filter(Boolean)
    .join('\n');
}

function evaluateAutoVerification({
  nomeCadastrado,
  idFuncionalCadastrado,
  forcaSigla,
  nomeExtraido,
  matriculaExtraida,
  forcaExtraida,
  cargoExtraido,
  ocrRawText,
}) {
  const corpus = buildOcrCorpus({
    nomeExtraido,
    matriculaExtraida,
    forcaExtraida,
    cargoExtraido,
    ocrRawText,
  });

  const nomeOk = matchFromSources(
    (source) => namesMatch(nomeCadastrado, source) || namePartsMatch(nomeCadastrado, source),
    corpus,
    ocrRawText,
    nomeExtraido,
    matriculaExtraida,
    forcaExtraida,
    cargoExtraido
  );
  const matriculaOk = matchFromSources(
    (source) => matriculasMatch(idFuncionalCadastrado, source),
    corpus,
    ocrRawText,
    matriculaExtraida,
    nomeExtraido,
    forcaExtraida,
    cargoExtraido
  );

  return {
    autoVerify: nomeOk && matriculaOk,
    nomeOk,
    matriculaOk,
    formatoOk: isValidMatricula(matriculaExtraida, forcaSigla),
  };
}

module.exports = {
  normalizeName,
  namesMatch,
  namePartsMatch,
  normalizeMatricula,
  matriculasMatch,
  buildOcrCorpus,
  evaluateAutoVerification,
};

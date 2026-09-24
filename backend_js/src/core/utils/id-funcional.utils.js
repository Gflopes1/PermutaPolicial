function normalizeIdFuncional(value) {
  return String(value ?? '')
    .trim()
    .replace(/[.\-\s]/g, '')
    .replace(/^0+(?=\d)/, '');
}

function idFuncionaisMatch(a, b) {
  const na = normalizeIdFuncional(a);
  const nb = normalizeIdFuncional(b);
  if (!na || !nb) return false;
  return na === nb;
}

module.exports = {
  normalizeIdFuncional,
  idFuncionaisMatch,
};

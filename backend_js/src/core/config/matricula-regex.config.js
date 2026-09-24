// Regex de matrícula/ID funcional por sigla da força — ajuste conforme cada corporação.
// Chave: sigla em maiúsculas. 'default' é fallback.

const MATRICULA_REGEX_BY_FORCA = {
  default: /^[\dA-Za-z.\-/]{4,20}$/,
  PMESP: /^\d{6,8}$/,
  PMERJ: /^\d{5,7}$/,
  PMSP: /^\d{6,8}$/,
  PRF: /^\d{5,7}$/,
  PF: /^\d{5,7}$/,
  PCSP: /^\d{5,8}$/,
  BMRS: /^\d{5,8}$/,
};

function getMatriculaRegex(forcaSigla) {
  const sigla = String(forcaSigla || '').trim().toUpperCase();
  const pattern = MATRICULA_REGEX_BY_FORCA[sigla] || MATRICULA_REGEX_BY_FORCA.default;
  return pattern;
}

function isValidMatricula(matricula, forcaSigla) {
  if (!matricula || typeof matricula !== 'string') return false;
  const normalized = matricula.trim();
  if (!normalized) return false;
  return getMatriculaRegex(forcaSigla).test(normalized);
}

module.exports = {
  MATRICULA_REGEX_BY_FORCA,
  getMatriculaRegex,
  isValidMatricula,
};

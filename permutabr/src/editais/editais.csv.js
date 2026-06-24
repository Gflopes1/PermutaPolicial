function parseCsvLines(text) {
  return text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0 && !l.startsWith('#'));
}

function splitLine(line) {
  if (line.includes(';')) return line.split(';').map((c) => c.trim());
  return line.split(',').map((c) => c.trim());
}

function parseVagasCsv(text) {
  const lines = parseCsvLines(text);
  const start = lines[0]?.toLowerCase().includes('opm') ? 1 : 0;
  const vagas = [];
  for (let i = start; i < lines.length; i++) {
    const cols = splitLine(lines[i]);
    if (cols.length < 2) continue;
    const crpm = cols.length >= 3 ? cols[0] : null;
    const opm = cols.length >= 3 ? cols[1] : cols[0];
    const vagasStr = cols.length >= 3 ? cols[2] : cols[1];
    vagas.push({
      crpm: crpm || null,
      opm,
      vagas_disponiveis: parseInt(vagasStr, 10) || 0,
      ordem: i - start + 1,
    });
  }
  return vagas;
}

function parseParticipantesCsv(text) {
  const lines = parseCsvLines(text);
  const start =
    lines[0]?.toLowerCase().includes('id_funcional') ||
    lines[0]?.toLowerCase().includes('funcional')
      ? 1
      : 0;
  const participantes = [];
  for (let i = start; i < lines.length; i++) {
    const cols = splitLine(lines[i]);
    if (cols.length < 2) continue;
    participantes.push({
      id_funcional: cols[0],
      posicao_prioridade: parseInt(cols[1], 10) || 0,
    });
  }
  return participantes;
}

module.exports = { parseVagasCsv, parseParticipantesCsv };

// /src/core/utils/policial-cleanup.js
// Limpeza de registros vinculados antes de DELETE em policiais

const intencoesRepository = require('../../modules/intencoes/intencoes.repository');

async function cleanupPolicialDependencies(connection, policialId) {
  const exec = (sql, params = [policialId]) => connection.execute(sql, params);

  await intencoesRepository.archiveForAccountRemoval(connection, policialId);
  try {
    await exec('DELETE FROM intencoes_avisos_email WHERE policial_id = ?');
  } catch (_) { /* tabela opcional */ }
  await exec('DELETE FROM codigos_recuperacao WHERE policial_id = ?');
  try {
    await exec('DELETE FROM permutas_concluidas_feedback WHERE policial_id = ?');
  } catch (_) { /* tabela opcional */ }
  try {
    await exec('DELETE FROM sugestoes_unidades WHERE sugerido_por_policial_id = ?');
  } catch (_) { /* coluna pode não existir */ }
  await exec('UPDATE questions SET aprovada_por = NULL WHERE aprovada_por = ?');
}

module.exports = { cleanupPolicialDependencies };

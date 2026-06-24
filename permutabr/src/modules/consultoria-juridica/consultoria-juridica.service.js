const consultoriaRepository = require('./consultoria-juridica.repository');
const consultoriaStorage = require('./consultoria-juridica-storage.service');
const ApiError = require('../../core/utils/ApiError');

function parseBool(value, defaultValue = true) {
  if (value === undefined || value === null || value === '') return defaultValue;
  if (value === true || value === 'true' || value === '1' || value === 1) return true;
  if (value === false || value === 'false' || value === '0' || value === 0) return false;
  return defaultValue;
}

function parseBody(body) {
  return {
    nome: (body.nome || '').trim(),
    descricao_curta: (body.descricao_curta || '').trim(),
    descricao_detalhada: (body.descricao_detalhada || '').trim() || null,
    site_url: (body.site_url || '').trim() || null,
    contato_whatsapp: (body.contato_whatsapp || '').trim() || null,
    contato_telefone: (body.contato_telefone || '').trim() || null,
    contato_email: (body.contato_email || '').trim() || null,
    ordem: parseInt(body.ordem, 10) || 0,
    ativo: parseBool(body.ativo, true),
  };
}

async function listPublic() {
  return await consultoriaRepository.findAll({ onlyActive: true });
}

async function getPublicById(req) {
  const id = parseInt(req.params.id, 10);
  const advogado = await consultoriaRepository.findById(id, { onlyActive: true });
  if (!advogado) throw new ApiError(404, 'Profissional não encontrado.');
  return advogado;
}

async function registerClick(req) {
  const id = parseInt(req.params.id, 10);
  const tipo = req.body.tipo;
  const advogado = await consultoriaRepository.findById(id, { onlyActive: true });
  if (!advogado) throw new ApiError(404, 'Profissional não encontrado.');

  if (tipo === 'contato') {
    const hasContact = advogado.contato_whatsapp || advogado.contato_telefone || advogado.contato_email;
    if (!hasContact) throw new ApiError(400, 'Este profissional não possui contato cadastrado.');
  }
  if (tipo === 'site' && !advogado.site_url) {
    throw new ApiError(400, 'Este profissional não possui site cadastrado.');
  }

  await consultoriaRepository.registerClick(id, req.user.id, tipo);
  return { success: true };
}

async function listAdmin() {
  return await consultoriaRepository.findAll();
}

async function getAdminById(req) {
  const id = parseInt(req.params.id, 10);
  const advogado = await consultoriaRepository.findById(id);
  if (!advogado) throw new ApiError(404, 'Profissional não encontrado.');
  return advogado;
}

async function createAdmin(req) {
  const body = parseBody(req.body);
  if (!body.nome || !body.descricao_curta) {
    throw new ApiError(400, 'Nome e descrição curta são obrigatórios.');
  }

  let fotoUrl = null;
  if (req.file?.buffer) {
    fotoUrl = await consultoriaStorage.uploadPhoto(req.file.buffer);
  }
  if (!fotoUrl) {
    throw new ApiError(400, 'Foto é obrigatória.');
  }

  const id = await consultoriaRepository.create({ ...body, foto_url: fotoUrl });
  return await consultoriaRepository.findById(id);
}

async function updateAdmin(req) {
  const id = parseInt(req.params.id, 10);
  const existing = await consultoriaRepository.findById(id);
  if (!existing) throw new ApiError(404, 'Profissional não encontrado.');

  const body = parseBody(req.body);
  if (!body.nome || !body.descricao_curta) {
    throw new ApiError(400, 'Nome e descrição curta são obrigatórios.');
  }

  let fotoUrl = existing.foto_url;
  if (req.file?.buffer) {
    fotoUrl = await consultoriaStorage.uploadPhoto(req.file.buffer);
    await consultoriaStorage.deletePhoto(existing.foto_url);
  }

  const ok = await consultoriaRepository.update(id, { ...body, foto_url: fotoUrl });
  if (!ok) throw new ApiError(500, 'Erro ao atualizar profissional.');
  return await consultoriaRepository.findById(id);
}

async function deleteAdmin(req) {
  const id = parseInt(req.params.id, 10);
  const existing = await consultoriaRepository.findById(id);
  if (!existing) throw new ApiError(404, 'Profissional não encontrado.');

  const ok = await consultoriaRepository.delete(id);
  if (!ok) throw new ApiError(500, 'Erro ao excluir profissional.');
  await consultoriaStorage.deletePhoto(existing.foto_url);
  return { message: 'Profissional excluído com sucesso.' };
}

async function getClickStats() {
  return await consultoriaRepository.getClickStats();
}

module.exports = {
  listPublic,
  getPublicById,
  registerClick,
  listAdmin,
  getAdminById,
  createAdmin,
  updateAdmin,
  deleteAdmin,
  getClickStats,
};

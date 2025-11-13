// /src/modules/marketplace/marketplace.controller.js

const marketplaceService = require('./marketplace.service');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

// Processa e comprime as imagens
async function processarImagens(files) {
  if (!files || files.length === 0) return [];
  
  const uploadDir = path.join(__dirname, '../../../uploads/marketplace');
  const imagensProcessadas = [];
  
  for (const file of files) {
    const inputPath = file.path;
    const outputPath = path.join(uploadDir, 'compressed-' + path.basename(inputPath));
    
    try {
      // Comprime a imagem mantendo qualidade razoável
      await sharp(inputPath)
        .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 80 })
        .toFile(outputPath);
      
      // Remove o arquivo original
      fs.unlinkSync(inputPath);
      
      // Retorna o caminho relativo para salvar no banco
      imagensProcessadas.push('/uploads/marketplace/' + path.basename(outputPath));
    } catch (error) {
      console.error('Erro ao processar imagem:', error);
      // Se falhar, mantém o original
      imagensProcessadas.push('/uploads/marketplace/' + path.basename(inputPath));
    }
  }
  
  return imagensProcessadas;
}

module.exports = {
  getAll: handleRequest(async (req) => {
    const { tipo, search, page = 1, limit = 20 } = req.query;
    return await marketplaceService.getAll({ tipo, search, page: parseInt(page), limit: parseInt(limit) });
  }, 200),
  
  getById: handleRequest((req) => marketplaceService.getById(req.params.id), 200),
  
  getByUsuario: handleRequest((req) => marketplaceService.getByUsuario(req.params.policialId), 200),
  
  create: handleRequest(async (req) => {
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos,
      policial_id: req.user.id
    };
    return await marketplaceService.create(dados);
  }, 201),
  
  update: handleRequest(async (req) => {
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos.length > 0 ? fotos : undefined
    };
    return await marketplaceService.update(req.params.id, dados, req.user.id);
  }, 200),
  
  delete: handleRequest((req) => marketplaceService.delete(req.params.id, req.user.id), 200),
  
  getAllAdmin: handleRequest(async (req) => {
    const { status, page = 1, limit = 20 } = req.query;
    return await marketplaceService.getAllAdmin({ status, page: parseInt(page), limit: parseInt(limit) });
  }, 200),
  
  aprovar: handleRequest((req) => marketplaceService.aprovar(req.params.id), 200),
  
  rejeitar: handleRequest((req) => marketplaceService.rejeitar(req.params.id), 200),
  
  deleteAdmin: handleRequest((req) => marketplaceService.deleteAdmin(req.params.id), 200),
};


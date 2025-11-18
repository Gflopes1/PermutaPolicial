// /src/modules/marketplace/marketplace.controller.js

const marketplaceService = require('./marketplace.service');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    console.log(`✅ Success ${req.method} ${req.originalUrl}:`, result);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    console.error(`❌ Error ${req.method} ${req.originalUrl}:`, error);
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
    const { tipo, search, estado, cidade, page = 1, limit = 20 } = req.query;
    console.log('📋 getAll chamado:', { tipo, search, estado, cidade, page, limit });
    const result = await marketplaceService.getAll({ 
      tipo, 
      search,
      estado,
      cidade,
      page: parseInt(page), 
      limit: parseInt(limit) 
    });
    console.log(`📋 getAll retornou ${result.length} itens`);
    return result;
  }, 200),
  
  getById: handleRequest(async (req) => {
    console.log('🔍 getById chamado:', req.params.id);
    return await marketplaceService.getById(req.params.id);
  }, 200),
  
  getByUsuario: handleRequest(async (req) => {
    console.log('👤 getByUsuario chamado:', req.params.policialId);
    const result = await marketplaceService.getByUsuario(req.params.policialId);
    console.log(`👤 getByUsuario retornou ${result.length} itens`);
    return result;
  }, 200),
  
  create: handleRequest(async (req) => {
    console.log('➕ create chamado');
    console.log('Body:', req.body);
    console.log('Files:', req.files?.length || 0);
    console.log('User:', req.user?.id);
    
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos,
      policial_id: req.user.id
    };
    console.log('Dados a criar:', dados);
    
    const result = await marketplaceService.create(dados);
    console.log('✅ Item criado:', result);
    return result;
  }, 201),
  
  update: handleRequest(async (req) => {
    console.log('✏️ update chamado:', req.params.id);
    console.log('Body:', req.body);
    console.log('Files:', req.files?.length || 0);
    
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos.length > 0 ? fotos : undefined
    };
    return await marketplaceService.update(req.params.id, dados, req.user.id);
  }, 200),
  
  delete: handleRequest(async (req) => {
    console.log('🗑️ delete chamado:', req.params.id);
    return await marketplaceService.delete(req.params.id, req.user.id);
  }, 200),
  
  getAllAdmin: handleRequest(async (req) => {
    const { status, page = 1, limit = 20 } = req.query;
    console.log('🔐 getAllAdmin chamado:', { status, page, limit });
    const result = await marketplaceService.getAllAdmin({ 
      status, 
      page: parseInt(page), 
      limit: parseInt(limit) 
    });
    console.log(`🔐 getAllAdmin retornou ${result.length} itens`);
    return result;
  }, 200),
  
  aprovar: handleRequest(async (req) => {
    console.log('✅ aprovar chamado:', req.params.id);
    return await marketplaceService.aprovar(req.params.id);
  }, 200),
  
  rejeitar: handleRequest(async (req) => {
    console.log('❌ rejeitar chamado:', req.params.id);
    return await marketplaceService.rejeitar(req.params.id);
  }, 200),
  
  deleteAdmin: handleRequest(async (req) => {
    console.log('🗑️ deleteAdmin chamado:', req.params.id);
    return await marketplaceService.deleteAdmin(req.params.id);
  }, 200),
};
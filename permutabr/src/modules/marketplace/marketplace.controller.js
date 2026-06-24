// /src/modules/marketplace/marketplace.controller.js

const marketplaceService = require('./marketplace.service');
const storageService = require('../../core/services/storage.service');
const sharp = require('sharp');
const path = require('path');
const logger = require('../../core/utils/logger');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    logger.log(`✅ Success ${req.method} ${req.originalUrl}:`, result);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    console.error(`❌ Error ${req.method} ${req.originalUrl}:`, error);
    next(error);
  }
};

// Processa, comprime e faz upload das imagens para o R2
async function processarImagens(files) {
  if (!files || files.length === 0) return [];
  
  const imagensProcessadas = [];
  
  for (const file of files) {
    try {
      // Processa o buffer da imagem com sharp
      const processedBuffer = await sharp(file.buffer)
        .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 80 })
        .toBuffer();
      
      // Gera nome único para o arquivo
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const fileName = `marketplace-${uniqueSuffix}.jpg`;
      
      // Faz upload para o R2
      const fileUrl = await storageService.uploadFile(
        processedBuffer,
        fileName,
        'image/jpeg',
        'marketplace'
      );
      
      imagensProcessadas.push(fileUrl);
    } catch (error) {
      console.error('❌ Erro ao processar imagem:', error);
      // Se falhar, tenta fazer upload do buffer original
      try {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname) || '.jpg';
        const fileName = `marketplace-${uniqueSuffix}${ext}`;
        
        const fileUrl = await storageService.uploadFile(
          file.buffer,
          fileName,
          file.mimetype,
          'marketplace'
        );
        
        imagensProcessadas.push(fileUrl);
      } catch (uploadError) {
        console.error('❌ Erro ao fazer upload da imagem original:', uploadError);
        // Continua sem adicionar esta imagem
      }
    }
  }
  
  return imagensProcessadas;
}

module.exports = {
  getAll: handleRequest(async (req) => {
    const { tipo, search, estado, cidade, page = 1, limit = 20 } = req.query;
    logger.log('📋 getAll chamado:', { tipo, search, estado, cidade, page, limit });
    const result = await marketplaceService.getAll({ 
      tipo, 
      search,
      estado,
      cidade,
      page: parseInt(page), 
      limit: parseInt(limit) 
    });
    logger.log(`📋 getAll retornou ${result.length} itens`);
    return result;
  }, 200),
  
  getById: handleRequest(async (req) => {
    logger.log('🔍 getById chamado:', req.params.id);
    return await marketplaceService.getById(req.params.id);
  }, 200),
  
  getByUsuario: handleRequest(async (req) => {
    logger.log('👤 getByUsuario chamado:', req.params.policialId);
    const result = await marketplaceService.getByUsuario(req.params.policialId);
    logger.log(`👤 getByUsuario retornou ${result.length} itens`);
    return result;
  }, 200),
  
  create: handleRequest(async (req) => {
    logger.log('➕ create chamado');
    logger.log('Body:', req.body);
    logger.log('Files:', req.files?.length || 0);
    logger.log('User:', req.user?.id);
    
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos,
      policial_id: req.user.id
    };
    logger.log('Dados a criar:', dados);
    
    const result = await marketplaceService.create(dados);
    logger.log('✅ Item criado:', result);
    return result;
  }, 201),
  
  update: handleRequest(async (req) => {
    logger.log('✏️ update chamado:', req.params.id);
    logger.log('Body:', req.body);
    logger.log('Files:', req.files?.length || 0);
    
    const fotos = await processarImagens(req.files);
    const dados = {
      ...req.body,
      fotos: fotos.length > 0 ? fotos : undefined
    };
    return await marketplaceService.update(req.params.id, dados, req.user.id);
  }, 200),
  
  delete: handleRequest(async (req) => {
    logger.log('🗑️ delete chamado:', req.params.id);
    return await marketplaceService.delete(req.params.id, req.user.id);
  }, 200),
  
  getAllAdmin: handleRequest(async (req) => {
    const { status, page = 1, limit = 20 } = req.query;
    logger.log('🔐 getAllAdmin chamado:', { status, page, limit });
    const result = await marketplaceService.getAllAdmin({ 
      status, 
      page: parseInt(page), 
      limit: parseInt(limit) 
    });
    logger.log(`🔐 getAllAdmin retornou ${result.length} itens`);
    return result;
  }, 200),
  
  aprovar: handleRequest(async (req) => {
    logger.log('✅ aprovar chamado:', req.params.id);
    return await marketplaceService.aprovar(req.params.id);
  }, 200),
  
  rejeitar: handleRequest(async (req) => {
    logger.log('❌ rejeitar chamado:', req.params.id);
    return await marketplaceService.rejeitar(req.params.id);
  }, 200),
  
  deleteAdmin: handleRequest(async (req) => {
    logger.log('🗑️ deleteAdmin chamado:', req.params.id);
    return await marketplaceService.deleteAdmin(req.params.id);
  }, 200),

  countPendentes: handleRequest(async (req) => {
    logger.log('🔢 countPendentes chamado');
    const count = await marketplaceService.countPendentes();
    return { count };
  }, 200),
};
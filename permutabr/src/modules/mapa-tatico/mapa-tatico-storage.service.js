// Armazenamento de fotos no Cloudflare R2 (CDN)

const path = require('path');
const sharp = require('sharp');
const storageService = require('../../core/services/storage.service');
const { validateImageMagicBytes } = require('./mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');

const UPLOAD_FOLDER = 'mapa-tatico';

function generateFileName(ext = 'jpg') {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}.${ext}`;
}

function isStorageConfigured() {
  return !!(process.env.AWS_BUCKET_NAME && process.env.AWS_ENDPOINT);
}

/**
 * Valida magic bytes, reprocessa com sharp e envia para R2/CDN.
 * @param {Buffer} buffer
 * @param {string} [_mimeType] - ignorado; tipo real vem dos magic bytes
 * @returns {Promise<string>} URL pública na CDN
 */
async function uploadPhoto(buffer, _mimeType = 'image/jpeg') {
  if (!isStorageConfigured()) {
    throw new ApiError(
      503,
      'Upload de fotos temporariamente indisponível. Crie o ponto sem foto ou tente mais tarde.',
      null,
      'PHOTO_UPLOAD_UNAVAILABLE'
    );
  }

  const { mime } = validateImageMagicBytes(buffer);

  let processedBuffer;
  let outputMime = 'image/jpeg';
  let ext = 'jpg';

  try {
    processedBuffer = await sharp(buffer)
      .rotate()
      .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 82, mozjpeg: true })
      .toBuffer();
  } catch (err) {
    if (mime === 'image/png') {
      processedBuffer = await sharp(buffer).rotate().png({ compressionLevel: 8 }).toBuffer();
      outputMime = 'image/png';
      ext = 'png';
    } else {
      throw new ApiError(400, 'Não foi possível processar a imagem enviada.');
    }
  }

  const fileName = generateFileName(ext);
  const year = new Date().getFullYear().toString();
  const folder = path.posix.join(UPLOAD_FOLDER, year);

  try {
    return await storageService.uploadFile(
      processedBuffer,
      fileName,
      outputMime,
      folder
    );
  } catch (error) {
    console.error('[mapa-tatico-storage] Falha no upload da foto:', {
      folder,
      fileName,
      bytes: processedBuffer?.length,
      mime: outputMime,
      storage: storageService.getConfig?.() || {},
      message: error.message,
    });
    throw new ApiError(
      503,
      `Upload de foto falhou: ${error.message || 'erro no storage'}`,
      null,
      'PHOTO_UPLOAD_FAILED'
    );
  }
}

/**
 * Remove foto do R2 (ignora URLs legadas em /uploads/).
 */
async function deletePhoto(photoUrl) {
  if (!photoUrl) return;
  if (photoUrl.includes('/uploads/mapa-tatico/')) return;
  await storageService.deleteFile(photoUrl);
}

module.exports = {
  uploadPhoto,
  deletePhoto,
  isStorageConfigured,
  UPLOAD_FOLDER,
};

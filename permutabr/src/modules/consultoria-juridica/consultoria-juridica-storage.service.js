const path = require('path');
const sharp = require('sharp');
const storageService = require('../../core/services/storage.service');
const { validateImageMagicBytes } = require('../mapa-tatico/mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');

const UPLOAD_FOLDER = 'consultoria-juridica';

function generateFileName(ext = 'jpg') {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}.${ext}`;
}

function isStorageConfigured() {
  return !!(process.env.AWS_BUCKET_NAME && process.env.AWS_ENDPOINT);
}

async function uploadPhoto(buffer) {
  if (!isStorageConfigured()) {
    throw new ApiError(
      503,
      'Upload de fotos temporariamente indisponível.',
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
      .resize(1200, 1600, { fit: 'inside', withoutEnlargement: true })
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
    return await storageService.uploadFile(processedBuffer, fileName, outputMime, folder);
  } catch (error) {
    throw new ApiError(
      503,
      `Upload de foto falhou: ${error.message || 'erro no storage'}`,
      null,
      'PHOTO_UPLOAD_FAILED'
    );
  }
}

async function deletePhoto(photoUrl) {
  if (!photoUrl) return;
  await storageService.deleteFile(photoUrl);
}

module.exports = {
  uploadPhoto,
  deletePhoto,
  isStorageConfigured,
  UPLOAD_FOLDER,
};

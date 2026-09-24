const path = require('path');
const sharp = require('sharp');
const storageService = require('../../core/services/storage.service');
const { validateImageMagicBytes } = require('../mapa-tatico/mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');

const UPLOAD_FOLDER = 'verificacao-ocr';

function generateFileName(ext = 'jpg') {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}.${ext}`;
}

function isStorageConfigured() {
  return !!(process.env.AWS_BUCKET_NAME && process.env.AWS_ENDPOINT);
}

async function uploadRedactedImage(buffer) {
  if (!isStorageConfigured()) {
    throw new ApiError(
      503,
      'Upload de documento temporariamente indisponível.',
      null,
      'OCR_UPLOAD_UNAVAILABLE'
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
      .jpeg({ quality: 85, mozjpeg: true })
      .toBuffer();
  } catch (err) {
    if (mime === 'image/png') {
      processedBuffer = await sharp(buffer)
        .rotate()
        .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
        .png({ compressionLevel: 8 })
        .toBuffer();
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
      `Upload do documento falhou: ${error.message || 'erro no storage'}`,
      null,
      'OCR_UPLOAD_FAILED'
    );
  }
}

module.exports = {
  uploadRedactedImage,
  isStorageConfigured,
  UPLOAD_FOLDER,
};

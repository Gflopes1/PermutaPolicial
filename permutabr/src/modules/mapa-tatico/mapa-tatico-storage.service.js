// /src/modules/mapa-tatico/mapa-tatico-storage.service.js
// Armazenamento de fotos em filesystem (preparado para migração S3/R2)

const fs = require('fs');
const path = require('path');

const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads', 'mapa-tatico');
const BASE_URL = process.env.BASE_URL || '';

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function generateFileName() {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Faz upload de uma foto para o filesystem
 * @param {Buffer} buffer - Buffer do arquivo
 * @param {string} mimeType - Tipo MIME (ex: image/jpeg)
 * @returns {Promise<string>} URL relativa ou absoluta do arquivo (ex: /uploads/mapa-tatico/2025/xxx.jpg)
 */
async function uploadPhoto(buffer, mimeType = 'image/jpeg') {
  const year = new Date().getFullYear().toString();
  const dirPath = path.join(UPLOADS_DIR, year);
  ensureDir(dirPath);

  const ext = mimeType.includes('png') ? 'png' : 'jpg';
  const fileName = `${generateFileName()}.${ext}`;
  const filePath = path.join(dirPath, fileName);

  fs.writeFileSync(filePath, buffer);

  const relativePath = `/uploads/mapa-tatico/${year}/${fileName}`;
  return BASE_URL ? `${BASE_URL.replace(/\/$/, '')}${relativePath}` : relativePath;
}

module.exports = {
  uploadPhoto,
  UPLOADS_DIR,
};

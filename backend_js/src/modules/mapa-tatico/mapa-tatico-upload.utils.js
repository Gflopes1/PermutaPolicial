const ApiError = require('../../core/utils/ApiError');
const { validateImageMagicBytes } = require('./mapa-tatico-security.utils');

function getUploadedPhotoFiles(req) {
  if (Array.isArray(req.files) && req.files.length) {
    return req.files.filter((f) => f?.buffer);
  }
  if (req.files?.photos) {
    const photos = Array.isArray(req.files.photos) ? req.files.photos : [req.files.photos];
    return photos.filter((f) => f?.buffer);
  }
  if (req.files?.photo) {
    const photo = Array.isArray(req.files.photo) ? req.files.photo : [req.files.photo];
    return photo.filter((f) => f?.buffer);
  }
  if (req.file?.buffer) return [req.file];
  return [];
}

function validateUploadedImages(req, res, next) {
  try {
    for (const file of getUploadedPhotoFiles(req)) {
      validateImageMagicBytes(file.buffer);
    }
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getUploadedPhotoFiles,
  validateUploadedImages,
};

// /src/core/services/storage.service.js
// Serviço de armazenamento para Cloudflare R2

const { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const logger = require('../utils/logger');

function getCdnUrl() {
  const raw = process.env.CDN_URL || '';
  return raw.replace(/\/+$/, '');
}

/**
 * Endpoint R2 deve ser só a conta: https://<account_id>.r2.cloudflarestorage.com
 * (sem /nome-do-bucket — isso quebra a assinatura e retorna 401 Unauthorized).
 */
function normalizeR2Endpoint(rawEndpoint, bucketName) {
  if (!rawEndpoint) return '';
  let endpoint = rawEndpoint.trim().replace(/\/+$/, '');
  if (bucketName) {
    const bucketSuffix = `/${bucketName}`;
    if (endpoint.toLowerCase().endsWith(bucketSuffix.toLowerCase())) {
      endpoint = endpoint.slice(0, -bucketSuffix.length);
    }
  }
  return endpoint.replace(/\/+$/, '');
}

function getBucketName() {
  return (process.env.AWS_BUCKET_NAME || '').trim();
}

function getR2Endpoint() {
  return normalizeR2Endpoint(process.env.AWS_ENDPOINT, getBucketName());
}

function getStorageConfig() {
  const bucket = getBucketName();
  const rawEndpoint = (process.env.AWS_ENDPOINT || '').trim();
  const endpoint = getR2Endpoint();
  return {
    endpoint,
    rawEndpoint: rawEndpoint || '(não definido)',
    endpointNormalized: rawEndpoint !== endpoint && !!endpoint,
    bucket: bucket || '(não definido)',
    cdnUrl: getCdnUrl() || '(não definido)',
    hasCredentials: !!(
      (process.env.AWS_ACCESS_KEY_ID || '').trim() &&
      (process.env.AWS_SECRET_ACCESS_KEY || '').trim()
    ),
  };
}

let _s3Client = null;

function getS3Client() {
  if (_s3Client) return _s3Client;

  const endpoint = getR2Endpoint();
  if (!endpoint) {
    throw new Error('AWS_ENDPOINT não configurado');
  }

  _s3Client = new S3Client({
    region: 'auto',
    endpoint,
    forcePathStyle: true,
    credentials: {
      accessKeyId: (process.env.AWS_ACCESS_KEY_ID || '').trim(),
      secretAccessKey: (process.env.AWS_SECRET_ACCESS_KEY || '').trim(),
    },
  });

  const cfg = getStorageConfig();
  if (cfg.endpointNormalized) {
    logger.warn('[R2] AWS_ENDPOINT continha o nome do bucket; normalizado automaticamente', {
      rawEndpoint: cfg.rawEndpoint,
      endpoint: cfg.endpoint,
      bucket: cfg.bucket,
    });
  }

  return _s3Client;
}

class StorageService {
  /**
   * @param {Buffer} fileBuffer
   * @param {string} fileName
   * @param {string} mimeType
   * @param {string} folder
   * @returns {Promise<string>}
   */
  async uploadFile(fileBuffer, fileName, mimeType, folder = 'uploads') {
    const bucket = getBucketName();
    const endpoint = getR2Endpoint();
    if (!bucket || !endpoint) {
      const cfg = getStorageConfig();
      logger.error('[R2] Upload abortado — storage não configurado', cfg);
      throw new Error('Storage R2 não configurado (AWS_BUCKET_NAME / AWS_ENDPOINT)');
    }

    const key = `${folder}/${fileName}`;
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: fileBuffer,
      ContentType: mimeType,
      ContentDisposition: 'inline',
      CacheControl: 'public, max-age=31536000, immutable',
    });

    try {
      const result = await getS3Client().send(command);
      const cdn = getCdnUrl();
      const publicUrl = cdn ? `${cdn}/${key}` : `${endpoint}/${bucket}/${key}`;
      logger.info('[R2] Upload OK', {
        key,
        bucket,
        etag: result.ETag,
        publicUrl,
        bytes: fileBuffer?.length,
      });
      return publicUrl;
    } catch (error) {
      const cfg = getStorageConfig();
      const httpStatus = error.$metadata?.httpStatusCode;
      let hint = null;
      if (httpStatus === 401) {
        hint =
          'Credenciais R2 inválidas ou expiradas, ou AWS_ENDPOINT incorreto. ' +
          'Use https://<ACCOUNT_ID>.r2.cloudflarestorage.com (sem /bucket) e um token R2 com permissão Object Read & Write no bucket.';
      }
      logger.error('[R2] Erro no upload', {
        key,
        bucket,
        ...cfg,
        errorName: error.name,
        errorMessage: error.message,
        httpStatus,
        hint,
        requestId: error.$metadata?.requestId,
        stack: error.stack,
      });
      throw new Error(
        hint ? `Falha no upload R2: ${error.message || 'Unauthorized'} — ${hint}` : `Falha no upload R2: ${error.message || 'erro desconhecido'}`
      );
    }
  }

  async deleteFile(fileUrl) {
    if (!fileUrl) return;

    try {
      let key;
      const cdn = getCdnUrl();
      if (cdn && fileUrl.startsWith(cdn)) {
        key = fileUrl.slice(cdn.length + 1);
      } else if (getBucketName() && fileUrl.includes(getBucketName())) {
        const urlObj = new URL(fileUrl);
        key = urlObj.pathname.substring(1);
      } else {
        key = fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl;
      }

      await getS3Client().send(
        new DeleteObjectCommand({
          Bucket: getBucketName(),
          Key: key,
        })
      );
      logger.info('[R2] Arquivo deletado', { key });
    } catch (error) {
      logger.error('[R2] Erro ao deletar', {
        fileUrl,
        errorMessage: error.message,
      });
    }
  }

  getConfig() {
    return getStorageConfig();
  }

  /**
   * Lê objeto do R2 para servir via proxy da API (evita CORS no Flutter web).
   * @param {string} key ex: mapa-tatico/2026/arquivo.jpg
   */
  async getObject(key) {
    const bucket = getBucketName();
    if (!bucket || !key) {
      throw new Error('Storage R2 não configurado ou key inválida');
    }

    const result = await getS3Client().send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: key,
      })
    );

    return {
      stream: result.Body,
      contentType: result.ContentType || 'application/octet-stream',
      contentLength: result.ContentLength,
      etag: result.ETag,
    };
  }
}

module.exports = new StorageService();

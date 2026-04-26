// /src/core/services/storage.service.js
// Serviço de armazenamento para Cloudflare R2

const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');

const s3Client = new S3Client({
    region: 'auto',
    endpoint: process.env.AWS_ENDPOINT,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

class StorageService {
    /**
     * Faz upload de um arquivo para o Cloudflare R2
     * @param {Buffer} fileBuffer - Buffer do arquivo
     * @param {string} fileName - Nome do arquivo
     * @param {string} mimeType - Tipo MIME do arquivo
     * @param {string} folder - Pasta onde o arquivo será armazenado (default: 'uploads')
     * @returns {Promise<string>} URL pública do arquivo
     */
    async uploadFile(fileBuffer, fileName, mimeType, folder = 'uploads') {
        const key = `${folder}/${fileName}`;
        const command = new PutObjectCommand({
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: key,
            Body: fileBuffer,
            ContentType: mimeType
        });

        try {
            await s3Client.send(command);
            
            // Retorna URL pública (prioriza CDN se configurado)
            if (process.env.CDN_URL) {
                return `${process.env.CDN_URL}/${key}`;
            }
            return `${process.env.AWS_ENDPOINT}/${process.env.AWS_BUCKET_NAME}/${key}`;
        } catch (error) {
            console.error('❌ Erro Upload R2:', error);
            throw new Error('Falha no upload do arquivo');
        }
    }

    /**
     * Deleta um arquivo do Cloudflare R2
     * @param {string} fileUrl - URL completa do arquivo
     * @returns {Promise<void>}
     */
    async deleteFile(fileUrl) {
        if (!fileUrl) return;
        
        try {
            // Extrai a chave da URL
            let key;
            if (process.env.CDN_URL && fileUrl.startsWith(process.env.CDN_URL)) {
                // Remove o CDN_URL e a barra inicial
                key = fileUrl.replace(process.env.CDN_URL + '/', '');
            } else if (fileUrl.includes(process.env.AWS_BUCKET_NAME)) {
                // Extrai a chave da URL do endpoint
                const urlObj = new URL(fileUrl);
                key = urlObj.pathname.substring(1); // Remove a barra inicial
            } else {
                // Assume que é um caminho relativo ou já é a chave
                key = fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl;
            }

            await s3Client.send(new DeleteObjectCommand({
                Bucket: process.env.AWS_BUCKET_NAME,
                Key: key
            }));
            
            console.log(`✅ Arquivo deletado do R2: ${key}`);
        } catch (error) {
            console.error('❌ Erro Delete R2:', error);
            // Não lança erro para não quebrar o fluxo se o arquivo já não existir
        }
    }
}

module.exports = new StorageService();


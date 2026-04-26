// /src/modules/auth/oauth.service.js

const policiaisOAuthRepository = require('../policiais/policiais.oauth.repository');
const logger = require('../../core/utils/logger');

class OAuthService {
    /**
     * Determina força por domínio do email
     */
    getForcaIdPorDominio(email) {
        const dominio = email.toLowerCase().split('@')[1];
        
        const DOMINIOS_FORCAS = {
            'susepe.rs.gov.br': 79,  // SUSEPE
            'pc.rs.gov.br': 52,       // Polícia Civil RS
            'bm.rs.gov.br': null      // BMRS - já tem lógica específica
        };
        
        return DOMINIOS_FORCAS[dominio] || null;
    }

    /**
     * Verifica se email é de domínio .gov.br (agente verificado)
     */
    isAgenteVerificado(email) {
        const dominio = email.toLowerCase().split('@')[1];
        return dominio && dominio.endsWith('.gov.br');
    }

    /**
     * Processa autenticação OAuth genérica
     * @param {Object} params - Parâmetros de autenticação
     * @param {string} params.providerId - ID do provedor (Google ID ou Microsoft ID)
     * @param {string} params.providerName - Nome do provedor ('google' ou 'microsoft')
     * @param {string} params.email - Email do usuário
     * @param {string} params.nome - Nome do usuário
     * @param {string} [params.idFuncional] - ID funcional (opcional)
     * @param {string} [params.postoGraduacaoNome] - Nome do posto/graduação (opcional)
     */
    async processOAuth({
        providerId,
        providerName,
        email,
        nome,
        idFuncional = null,
        postoGraduacaoNome = null
    }) {
        try {
            const agenteVerificado = this.isAgenteVerificado(email) ? 1 : 0;
            const statusVerificacaoEmail = 'VERIFICADO';

            // 1. Busca por ID do provedor
            let user = providerName === 'google'
                ? await policiaisOAuthRepository.findByGoogleId(providerId)
                : await policiaisOAuthRepository.findByMicrosoftId(providerId);

            if (user) {
                logger.debug(`Usuário encontrado pelo ${providerName} ID`, { email: user.email });
                return user;
            }

            // 2. Busca por email para vincular conta existente
            user = await policiaisOAuthRepository.findByEmail(email);

            if (user) {
                logger.debug(`Vinculando conta ${providerName} ao usuário existente`, { email });
                
                if (providerName === 'google' && !user.google_id) {
                    await policiaisOAuthRepository.updateGoogleId(
                        user.id, providerId, agenteVerificado, statusVerificacaoEmail
                    );
                    user.google_id = providerId;
                } else if (providerName === 'microsoft' && !user.microsoft_id) {
                    await policiaisOAuthRepository.updateMicrosoftId(
                        user.id, providerId, agenteVerificado, statusVerificacaoEmail
                    );
                    user.microsoft_id = providerId;
                }
                
                user.agente_verificado = agenteVerificado;
                user.status_verificacao = statusVerificacaoEmail;
                return user;
            }

            // 3. Cria novo usuário
            logger.debug(`Criando novo usuário ${providerName}`, { email });
            
            let forcaId = this.getForcaIdPorDominio(email);
            
            // Lógica específica para BMRS
            if (email.endsWith('@bm.rs.gov.br') && !forcaId) {
                const forca = await policiaisOAuthRepository.findForcaBySigla('BMRS');
                if (forca) forcaId = forca.id;
            }

            let postoId = null;
            if (postoGraduacaoNome) {
                const posto = await policiaisOAuthRepository.findPostoByNome(postoGraduacaoNome);
                if (posto) postoId = posto.id;
            }

            logger.debug('Força atribuída automaticamente no OAuth', { 
                forcaId: forcaId || 'Nenhuma (escolha manual)',
                provider: providerName
            });

            const newUser = await policiaisOAuthRepository.create({
                nome,
                email,
                googleId: providerName === 'google' ? providerId : null,
                microsoftId: providerName === 'microsoft' ? providerId : null,
                forcaId,
                authProvider: providerName,
                statusVerificacao: statusVerificacaoEmail,
                agenteVerificado,
                idFuncional,
                postoGraduacaoId: postoId
            });

            logger.debug(`Usuário ${providerName} criado com sucesso`);
            return newUser;

        } catch (error) {
            logger.error(`Erro OAuth ${providerName}`, {
                error: error.message,
                stack: error.stack
            });
            throw error;
        }
    }
}

module.exports = new OAuthService();


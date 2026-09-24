const verificacaoOcrRepository = require('./verificacao-ocr.repository');
const ocrStorageService = require('./verificacao-ocr-storage.service');
const { evaluateAutoVerification } = require('./verificacao-ocr.utils');
const { ocrDebugLog, truncateOcrText } = require('./verificacao-ocr-debug');
const ApiError = require('../../core/utils/ApiError');

class VerificacaoOcrService {
  async submitVerification(policialId, fileBuffer, fields) {
    const policial = await verificacaoOcrRepository.findPolicialForVerification(policialId);
    if (!policial) {
      throw new ApiError(404, 'Usuário não encontrado.');
    }
    if (policial.status_verificacao !== 'VERIFICADO') {
      throw new ApiError(403, 'Confirme seu e-mail antes de solicitar verificação de agente.');
    }
    if (policial.agente_verificado === 1) {
      throw new ApiError(409, 'Sua conta já está verificada.');
    }

    const pending = await verificacaoOcrRepository.findPendingByUsuario(policialId);

    const tipoDocumento = fields.tipo_documento;
    const nomeExtraido = (fields.nome_extraido || '').trim().slice(0, 255) || null;
    const matriculaExtraida = (fields.matricula_extraida || '').trim().slice(0, 500) || null;
    const forcaExtraida = (fields.forca_extraida || '').trim().slice(0, 100) || null;
    const cargoExtraido = (fields.cargo_extraido || '').trim().slice(0, 100) || null;
    const ocrRawText = (fields.ocr_raw_text || '').trim().slice(0, 50000) || null;

    const imagemUrl = await ocrStorageService.uploadRedactedImage(fileBuffer);
    await verificacaoOcrRepository.setDocumentoVerificacaoUrl(policialId, imagemUrl);

    const evaluation = evaluateAutoVerification({
      nomeCadastrado: policial.nome,
      idFuncionalCadastrado: policial.id_funcional,
      forcaSigla: policial.forca_sigla,
      nomeExtraido,
      matriculaExtraida,
      forcaExtraida,
      cargoExtraido,
      ocrRawText,
    });

    ocrDebugLog('Verificação OCR — dados enviados pelo app e avaliação', {
      policialId,
      cadastro: {
        nome: policial.nome,
        idFuncional: policial.id_funcional,
        forcaSigla: policial.forca_sigla,
      },
      extraido: {
        tipoDocumento,
        nomeExtraido,
        matriculaExtraida,
        forcaExtraida,
        cargoExtraido,
      },
      ocrRawText: truncateOcrText(ocrRawText),
      avaliacao: {
        nomeOk: evaluation.nomeOk,
        matriculaOk: evaluation.matriculaOk,
        formatoOk: evaluation.formatoOk,
        autoVerify: evaluation.autoVerify,
      },
    });

    if (evaluation.autoVerify) {
      const success = await verificacaoOcrRepository.markAgentVerifiedAutomatico(policialId);
      const agenteVerificado = success
        ? true
        : await verificacaoOcrRepository.isAgentVerified(policialId);

      if (success) {
        const referralService = require('../referral/referral.service');
        referralService.markAgentVerified(policialId).catch(() => {});
        return {
          resultado: 'verificado_automaticamente',
          agente_verificado: true,
          metodo_verificacao: 'ocr_automatico',
        };
      }

      if (agenteVerificado) {
        return {
          resultado: 'verificado_automaticamente',
          agente_verificado: true,
          metodo_verificacao: 'ocr_automatico',
        };
      }
    }

    const reviewPayload = {
      usuarioId: policialId,
      tipoDocumento,
      imagemRedigidaUrl: imagemUrl,
      nomeExtraido,
      matriculaExtraida,
      forcaExtraida,
      cargoExtraido,
    };

    const pendingId = pending
      ? await verificacaoOcrRepository.replacePendingReview(pending.id, reviewPayload)
      : await verificacaoOcrRepository.createPendingReview(reviewPayload);

    const agenteVerificadoAtual = await verificacaoOcrRepository.isAgentVerified(policialId);

    return {
      resultado: 'enviado_para_revisao',
      agente_verificado: agenteVerificadoAtual,
      pending_id: pendingId,
      substituiu_pendente: !!pending,
      avaliacao: {
        nome_ok: evaluation.nomeOk,
        matricula_ok: evaluation.matriculaOk,
        formato_ok: evaluation.formatoOk,
      },
    };
  }

  async getMyStatus(policialId) {
    const policial = await verificacaoOcrRepository.findPolicialForVerification(policialId);
    if (!policial) {
      throw new ApiError(404, 'Usuário não encontrado.');
    }
    const pending = await verificacaoOcrRepository.findPendingByUsuario(policialId);
    const documentoVerificacaoUrl = await verificacaoOcrRepository.getDocumentoVerificacaoUrl(policialId);
    return {
      agente_verificado: policial.agente_verificado === 1,
      ocr_pendente: !!pending,
      ocr_pendente_id: pending?.id ?? null,
      documento_verificacao_url: documentoVerificacaoUrl,
    };
  }

  async getPendingReviews() {
    return verificacaoOcrRepository.findPendingReviews();
  }

  async approvePending(id, revisorId) {
    const result = await verificacaoOcrRepository.approvePending(id, revisorId);
    if (!result) {
      throw new ApiError(404, 'Verificação OCR não encontrada ou já processada.');
    }
    const referralService = require('../referral/referral.service');
    referralService.markAgentVerified(result.usuarioId).catch(() => {});
    return { message: 'Verificação OCR aprovada com sucesso.' };
  }

  async rejectPending(id, revisorId) {
    const success = await verificacaoOcrRepository.rejectPending(id, revisorId);
    if (!success) {
      throw new ApiError(404, 'Verificação OCR não encontrada ou já processada.');
    }
    return { message: 'Verificação OCR rejeitada.' };
  }
}

module.exports = new VerificacaoOcrService();

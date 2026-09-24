const verificacaoOcrService = require('./verificacao-ocr.service');
const verificacaoOcrVisionService = require('./verificacao-ocr-vision.service');
const ApiError = require('../../core/utils/ApiError');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  submitOcr: handleRequest(async (req) => {
    if (!req.file?.buffer) {
      throw new ApiError(400, 'Nenhuma imagem redigida foi enviada.');
    }
    return verificacaoOcrService.submitVerification(
      req.user.id,
      req.file.buffer,
      req.body
    );
  }, 200),

  getPendingOcrReviews: handleRequest(
    () => verificacaoOcrService.getPendingReviews(),
    200
  ),

  approveOcrReview: handleRequest(
    (req) => verificacaoOcrService.approvePending(parseInt(req.params.id, 10), req.user.id),
    200
  ),

  rejectOcrReview: handleRequest(
    (req) => verificacaoOcrService.rejectPending(parseInt(req.params.id, 10), req.user.id),
    200
  ),

  getMyOcrStatus: handleRequest(
    (req) => verificacaoOcrService.getMyStatus(req.user.id),
    200
  ),

  recognizeVision: handleRequest(async (req) => {
    if (!req.file?.buffer) {
      throw new ApiError(400, 'Nenhuma imagem foi enviada para OCR.');
    }
    return verificacaoOcrVisionService.recognizeDocumentText(req.file.buffer);
  }, 200),
};

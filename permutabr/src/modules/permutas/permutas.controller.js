// /src/modules/permutas/permutas.controller.js

const permutasService = require('./permutas.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
    try {
        const result = await servicePromise(req);
        res.status(successStatus).json({ status: 'success', data: result });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    findMatches: handleRequest(
        // MUDANÇA: A chamada agora passa apenas o ID do usuário.
        (req) => permutasService.findMatchesForPolicial(req.user.id),
        200
    ),
};
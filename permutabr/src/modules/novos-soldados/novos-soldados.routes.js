const express = require('express');
const db = require('../../config/db');
const authMiddleware = require('../../core/middlewares/auth.middleware.js');
const soldadoAuthMiddleware = require('../../core/middlewares/soldadoAuth.middleware.js');
const ApiError = require('../../core/utils/ApiError'); // Verifique se este caminho está correto

const router = express.Router();

// ==========================================================
// ROTA 1: CHECK-ACCESS (CORRIGIDA)
// ==========================================================
router.get(
  '/check-access',
  authMiddleware,
  soldadoAuthMiddleware,
  async (req, res, next) => {
    // Se o middleware 'soldadoAuthMiddleware' passar, o acesso é válido.
    // O middleware já terá anexado 'req.soldado_info'.
    
    // === CORREÇÃO: Envolvendo a resposta em "data" ===
    res.status(200).json({ 
        status: 'success',
        data: {
          message: 'Acesso autorizado.',
          posicao: req.soldado_info.posicao_curso 
        }
    });
  }
);
// ==========================================================


// ----------------------------------------------------------------------------------
// ROTA 2: SALVAR AS TRÊS INTENÇÕES (CORRIGIDA)
// ----------------------------------------------------------------------------------
router.post(
  '/salvar-intencoes',
  authMiddleware,
  soldadoAuthMiddleware, 
  async (req, res, next) => {
    const { escolha_1_id, escolha_2_id, escolha_3_id } = req.body;
    const policialIdFuncional = req.soldado_info.policial_id;

    try {
      await db.execute(
        `UPDATE novos_soldados 
         SET escolha_1_opm_id = ?, escolha_2_opm_id = ?, escolha_3_opm_id = ?
         WHERE policial_id = ?`,
        [escolha_1_id, escolha_2_id, escolha_3_id, policialIdFuncional]
      );
      
      // === CORREÇÃO: Envolvendo a resposta em "data" ===
      res.status(200).json({ 
        status: 'success',
        data: { message: 'Intenções salvas com sucesso!' }
      });

    } catch (error) {
      next(error);
    }
  }
);

// ----------------------------------------------------------------------------------
// ROTA 3: OBTER OS DADOS DA TELA (VAGAS + MINHAS ESCOLHAS) (CORRIGIDA)
// ----------------------------------------------------------------------------------
router.get(
  '/dados-tela',
  authMiddleware,
  soldadoAuthMiddleware,
  async (req, res, next) => {
    try {
      const policialIdFuncional = req.soldado_info.policial_id;
    
      const [vagas] = await db.execute(
        `SELECT id, opm, crpm, vagas_disponiveis FROM edital_novos_soldados ORDER BY crpm, opm`
      );

      const [minhasIntencoes] = await db.execute(
        `SELECT escolha_1_opm_id, escolha_2_opm_id, escolha_3_opm_id 
         FROM novos_soldados WHERE policial_id = ?`,
        [policialIdFuncional]
      );

      // === CORREÇÃO: Envolvendo a resposta em "data" ===
      res.status(200).json({
        status: 'success',
        data: {
          vagasDisponiveis: vagas,
          minhasIntencoes: minhasIntencoes.length > 0 ? minhasIntencoes[0] : null,
          minhaPosicao: req.soldado_info.posicao_curso
        }
      });

    } catch (error) {
      next(error);
    }
  }
);


// ----------------------------------------------------------------------------------
// ROTA 4: ANALISAR AS CHANCES DE UMA VAGA (CORRIGIDA)
// ----------------------------------------------------------------------------------
router.get(
  '/analise-vaga/:opm_id',
  authMiddleware,
  soldadoAuthMiddleware,
  async (req, res, next) => {
    const { opm_id } = req.params;
    const minhaPosicao = req.soldado_info.posicao_curso;

    try {
      const [vagaInfo] = await db.execute(
        'SELECT opm, vagas_disponiveis FROM edital_novos_soldados WHERE id = ?',
        [opm_id]
      );

      if (vagaInfo.length === 0) {
        throw new ApiError(404, 'Vaga (OPM) não encontrada.');
      }

      const [count1] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_1_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      const [count2] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_2_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      const [count3] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_3_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      // === CORREÇÃO: Envolvendo a resposta em "data" ===
      res.status(200).json({
        status: 'success',
        data: {
          vagaInfo: vagaInfo[0], // { opm: "...", vagas_disponiveis: 5 }
          minhaPosicao: minhaPosicao,
          competicao: {
            como_1_opcao: count1[0].total,
            como_2_opcao: count2[0].total,
            como_3_opcao: count3[0].total
          }
        }
      });

    } catch (error) {
      next(error);
    }
  }
);


module.exports = router;
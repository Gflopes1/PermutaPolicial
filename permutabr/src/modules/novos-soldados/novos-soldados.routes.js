const express = require('express');
const db = require('../../config/db');
const authMiddleware = require('../../core/middlewares/auth.middleware.js');
const soldadoAuthMiddleware = require('../../core/middlewares/soldadoAuth.middleware.js');
const ApiError = require('../../core/utils/ApiError'); // Verifique se este caminho está correto

const router = express.Router();

// ----------------------------------------------------------------------------------
// ROTA 1: SALVAR AS TRÊS INTENÇÕES
// ----------------------------------------------------------------------------------
router.post(
  '/salvar-intencoes',
  authMiddleware,
  soldadoAuthMiddleware, // Garante que o usuário pode aceder a este módulo
  async (req, res, next) => {
    const { escolha_1_id, escolha_2_id, escolha_3_id } = req.body;
    const policialId = req.user.id;

    try {
      await db.execute(
        `UPDATE novos_soldados 
         SET escolha_1_opm_id = ?, escolha_2_opm_id = ?, escolha_3_opm_id = ?
         WHERE policial_id = ?`,
        [escolha_1_id, escolha_2_id, escolha_3_id, policialId]
      );
      res.status(200).json({ message: 'Intenções salvas com sucesso!' });
    } catch (error) {
      next(error);
    }
  }
);

// ----------------------------------------------------------------------------------
// ROTA 2: OBTER OS DADOS DA TELA (VAGAS + MINHAS ESCOLHAS)
// ----------------------------------------------------------------------------------
router.get(
  '/dados-tela',
  authMiddleware,
  soldadoAuthMiddleware,
  async (req, res, next) => {
    try {
      // 1. Buscar as vagas do edital
      const [vagas] = await db.execute(
        `SELECT id, opm, crpm, vagas_disponiveis FROM edital_novos_soldados ORDER BY crpm, opm`
      );

      // 2. Buscar as minhas intenções atuais (para preencher os dropdowns)
      const [minhasIntencoes] = await db.execute(
        `SELECT escolha_1_opm_id, escolha_2_opm_id, escolha_3_opm_id 
         FROM novos_soldados WHERE policial_id = ?`,
        [req.user.id]
      );

      res.status(200).json({
        vagasDisponiveis: vagas,
        minhasIntencoes: minhasIntencoes.length > 0 ? minhasIntencoes[0] : null,
        minhaPosicao: req.soldado_info.posicao_curso // O middleware já buscou isto
      });

    } catch (error) {
      next(error);
    }
  }
);


// ----------------------------------------------------------------------------------
// ROTA 3: ANALISAR AS CHANCES DE UMA VAGA (A LÓGICA PRINCIPAL)
// ----------------------------------------------------------------------------------
router.get(
  '/analise-vaga/:opm_id',
  authMiddleware,
  soldadoAuthMiddleware,
  async (req, res, next) => {
    const { opm_id } = req.params;
    const minhaPosicao = req.soldado_info.posicao_curso;

    try {
      // 1. Pega os dados da vaga (quantos spots existem)
      const [vagaInfo] = await db.execute(
        'SELECT opm, vagas_disponiveis FROM edital_novos_soldados WHERE id = ?',
        [opm_id]
      );

      if (vagaInfo.length === 0) {
        throw new ApiError(404, 'Vaga (OPM) não encontrada.');
      }

      // 2. Conta quantos com POSIÇÃO MELHOR que a minha querem esta vaga
      
      // Contagem como 1ª Opção
      const [count1] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_1_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      // Contagem como 2ª Opção
      const [count2] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_2_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      // Contagem como 3ª Opção
      const [count3] = await db.execute(
        `SELECT COUNT(id) AS total FROM novos_soldados 
         WHERE posicao_curso < ? AND escolha_3_opm_id = ?`,
        [minhaPosicao, opm_id]
      );

      res.status(200).json({
        vagaInfo: vagaInfo[0], // { opm: "...", vagas_disponiveis: 5 }
        minhaPosicao: minhaPosicao,
        competicao: {
          como_1_opcao: count1[0].total,
          como_2_opcao: count2[0].total,
          como_3_opcao: count3[0].total
        }
      });

    } catch (error) {
      next(error);
    }
  }
);

// (O middleware soldadoAuth.middleware.js que criámos antes ainda é necessário e está perfeito)
// (A rota /check-access que criámos antes também está perfeita e pode ser mantida)

module.exports = router;
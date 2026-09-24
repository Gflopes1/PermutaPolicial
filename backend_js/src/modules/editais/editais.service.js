const ApiError = require('../../core/utils/ApiError');
const editaisRepository = require('./editais.repository');
const { parseVagasCsv, parseParticipantesCsv } = require('./editais.csv');

function isAgenteVerificado(user) {
  return !!(user?.agente_verificado && user.agente_verificado !== 0);
}

class EditaisService {
  getWhatsappConfig() {
    return editaisRepository.getWhatsappConfig();
  }

  updateWhatsappConfig(data) {
    return editaisRepository.updateWhatsappConfig(data);
  }

  async listForUser(user, { aba = 'abertos' }) {
    const status = aba === 'encerrados' ? 'ENCERRADO' : 'ABERTO';
    return editaisRepository.listPublic({
      status,
      forcaIdUsuario: user?.forca_id,
    });
  }

  async getDetalhe(editalId, user) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital) throw new ApiError(404, 'Edital não encontrado.');

    if (edital.status === 'RASCUNHO') {
      throw new ApiError(404, 'Edital não encontrado.');
    }

    let temAcesso = false;
    let minhaPosicao = null;

    if (isAgenteVerificado(user) && user.id_funcional) {
      const participante = await editaisRepository.findParticipanteByEditalAndIdFuncional(
        editalId,
        String(user.id_funcional)
      );
      if (participante) {
        temAcesso = true;
        minhaPosicao = participante.posicao_prioridade;
        await editaisRepository.linkPolicialToParticipante(
          editalId,
          String(user.id_funcional),
          user.id
        );
      }
    }

    const agenteVerificado = isAgenteVerificado(user);
    let motivoSemAcesso = null;
    if (!temAcesso) {
      if (!agenteVerificado) {
        motivoSemAcesso = 'agente_nao_verificado';
      } else if (!user?.id_funcional) {
        motivoSemAcesso = 'id_funcional_ausente';
      } else {
        motivoSemAcesso = 'nao_participante';
      }
    }

    return {
      ...edital,
      tem_acesso: temAcesso,
      agente_verificado: agenteVerificado,
      motivo_sem_acesso: motivoSemAcesso,
      minha_posicao: minhaPosicao,
      destacar_forca: user?.forca_id === edital.forca_id,
    };
  }

  /** Resumo aberto (sem login) usado na landing pública do edital. */
  async getResumoPublico(editalId) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital || edital.status === 'RASCUNHO') {
      throw new ApiError(404, 'Edital não encontrado.');
    }

    const estatisticas = await editaisRepository.getResumoPublico(editalId);

    return {
      edital: {
        id: edital.id,
        titulo: edital.titulo,
        tipo: edital.tipo,
        status: edital.status,
        resumo: edital.resumo,
        link_pdf: edital.link_pdf,
        forca_sigla: edital.forca_sigla,
        forca_nome: edital.forca_nome,
        criterio_label: edital.criterio_label,
        data_abertura: edital.data_abertura,
        data_encerramento: edital.data_encerramento,
      },
      estatisticas,
    };
  }

  async getConsultaPublica(editalId, idFuncional) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital || edital.status === 'RASCUNHO') {
      throw new ApiError(404, 'Edital não encontrado.');
    }

    const normalized = String(idFuncional ?? '').trim();
    if (!normalized) {
      throw new ApiError(400, 'Informe o ID funcional.');
    }

    const participante = await editaisRepository.findParticipanteByEditalAndIdFuncional(
      editalId,
      normalized
    );
    if (!participante) {
      throw new ApiError(
        404,
        'ID funcional não encontrado na lista deste edital.',
        null,
        'PARTICIPANTE_NAO_ENCONTRADO'
      );
    }

    const vagasComInscritos = await editaisRepository.countInteressadosPorVaga(editalId);
    let minhasEscolhas = [];

    if (participante.policial_id) {
      const intencoes = await editaisRepository.getIntencoes(participante.policial_id, editalId);
      if (intencoes) {
        const ids = [
          intencoes.escolha_1_vaga_id,
          intencoes.escolha_2_vaga_id,
          intencoes.escolha_3_vaga_id,
        ].filter(Boolean);
        minhasEscolhas = vagasComInscritos
          .filter((v) => ids.includes(v.vaga_id))
          .map((v) => ({
            vaga_id: v.vaga_id,
            opm: v.opm,
            crpm: v.crpm,
            unidade_nome: v.unidade_nome,
            total_inscritos: v.total_inscritos,
            opcao: ids.indexOf(v.vaga_id) + 1,
          }))
          .sort((a, b) => a.opcao - b.opcao);
      }
    }

    return {
      edital: {
        id: edital.id,
        titulo: edital.titulo,
        tipo: edital.tipo,
        status: edital.status,
        forca_sigla: edital.forca_sigla,
        forca_nome: edital.forca_nome,
        criterio_label: edital.criterio_label,
        data_encerramento: edital.data_encerramento,
      },
      classificacao: participante.posicao_prioridade,
      id_funcional: normalized,
      minhas_escolhas: minhasEscolhas,
      // Totais por cidade/OPM sem revelar antiguidade/senioridade de ninguém
      cidades: vagasComInscritos.map((v) => ({
        vaga_id: v.vaga_id,
        opm: v.opm,
        crpm: v.crpm,
        unidade_nome: v.unidade_nome,
        vagas_disponiveis: v.vagas_disponiveis,
        total_inscritos: Number(v.total_inscritos) || 0,
      })),
    };
  }

  async getDadosTela(editalId, user, participante) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital) throw new ApiError(404, 'Edital não encontrado.');

    await editaisRepository.linkPolicialToParticipante(
      editalId,
      String(user.id_funcional),
      user.id
    );

    const [vagas, intencoes, totalIntencoesRegistradas] = await Promise.all([
      editaisRepository.getVagasByEdital(editalId),
      editaisRepository.getIntencoes(user.id, editalId),
      editaisRepository.countIntencoesRegistradas(editalId),
    ]);

    return {
      vagasDisponiveis: vagas,
      minhasIntencoes: intencoes
        ? {
            escolha_1_vaga_id: intencoes.escolha_1_vaga_id,
            escolha_2_vaga_id: intencoes.escolha_2_vaga_id,
            escolha_3_vaga_id: intencoes.escolha_3_vaga_id,
          }
        : null,
      minhaPosicao: participante.posicao_prioridade,
      criterio_label: edital.criterio_label,
      max_opcoes: edital.max_opcoes,
      total_intencoes_registradas: totalIntencoesRegistradas,
    };
  }

  async salvarIntencoes(editalId, user, body) {
    await editaisRepository.saveIntencoes(user.id, editalId, {
      escolha1: body.escolha_1_id,
      escolha2: body.escolha_2_id,
      escolha3: body.escolha_3_id,
    });
    return { message: 'Intenções salvas com sucesso!' };
  }

  async analisarVaga(editalId, vagaId, participante) {
    const result = await editaisRepository.analisarVaga(
      editalId,
      vagaId,
      participante.posicao_prioridade
    );
    if (!result) throw new ApiError(404, 'Vaga não encontrada neste edital.');
    return {
      vagaInfo: result.vagaInfo,
      minhaPosicao: result.minhaPosicao,
      competicao: result.competicao,
    };
  }

  // Admin
  listAllAdmin() {
    return editaisRepository.listAllAdmin();
  }

  async createEdital(data) {
    const id = await editaisRepository.createEdital(data);
    return editaisRepository.findById(id);
  }

  async updateEdital(id, data) {
    const ok = await editaisRepository.updateEdital(id, data);
    if (!ok) throw new ApiError(404, 'Edital não encontrado.');
    return editaisRepository.findById(id);
  }

  async deleteEdital(id) {
    const ok = await editaisRepository.deleteEdital(id);
    if (!ok) throw new ApiError(404, 'Edital não encontrado.');
    return { message: 'Edital excluído.' };
  }

  async importarVagas(editalId, csvText, modo) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital) throw new ApiError(404, 'Edital não encontrado.');
    const vagas = parseVagasCsv(csvText);
    if (vagas.length === 0) throw new ApiError(400, 'Nenhuma vaga válida no CSV.');
    const count = await editaisRepository.replaceVagas(editalId, vagas, modo);
    return { importadas: count };
  }

  async importarParticipantes(editalId, csvText, modo) {
    const edital = await editaisRepository.findById(editalId);
    if (!edital) throw new ApiError(404, 'Edital não encontrado.');
    const participantes = parseParticipantesCsv(csvText);
    if (participantes.length === 0) {
      throw new ApiError(400, 'Nenhum participante válido no CSV.');
    }
    const count = await editaisRepository.upsertParticipantes(editalId, participantes, modo);
    return { importados: count };
  }
}

module.exports = new EditaisService();

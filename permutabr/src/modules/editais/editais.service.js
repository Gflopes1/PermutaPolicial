const ApiError = require('../../core/utils/ApiError');
const editaisRepository = require('./editais.repository');
const { parseVagasCsv, parseParticipantesCsv } = require('./editais.csv');

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

    if (user?.agente_verificado && user.id_funcional) {
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

    return {
      ...edital,
      tem_acesso: temAcesso,
      minha_posicao: minhaPosicao,
      destacar_forca: user?.forca_id === edital.forca_id,
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

    const vagas = await editaisRepository.getVagasByEdital(editalId);
    const intencoes = await editaisRepository.getIntencoes(user.id, editalId);

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

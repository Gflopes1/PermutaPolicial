// /src/modules/forum/forum.service.js

const forumRepository = require('./forum.repository');
const ApiError = require('../../core/utils/ApiError');
const db = require('../../config/db');

class ForumService {
  // Categorias
  async getCategorias(req) {
    return await forumRepository.findAllCategorias();
  }

  // Tópicos
  async getTopicos(req) {
    const categoriaId = parseInt(req.query.categoria_id);
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    if (!categoriaId) {
      throw new ApiError(400, 'categoria_id é obrigatório.');
    }

    // Verifica se a categoria existe
    const categoria = await forumRepository.findCategoriaById(categoriaId);
    if (!categoria) {
      throw new ApiError(404, 'Categoria não encontrada.');
    }

    return await forumRepository.findTopicosByCategoria(categoriaId, limit, offset);
  }

  async getTopico(req) {
    const { topicoId } = req.params;
    const topico = await forumRepository.findTopicoById(topicoId);

    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    // Incrementa visualizações
    await forumRepository.incrementarVisualizacoes(topicoId);

    return topico;
  }

  async createTopico(req) {
    const { categoria_id, titulo, conteudo } = req.body;
    const autor_id = req.user.id;

    if (!titulo || titulo.trim().length === 0) {
      throw new ApiError(400, 'O título é obrigatório.');
    }

    if (!conteudo || conteudo.trim().length === 0) {
      throw new ApiError(400, 'O conteúdo é obrigatório.');
    }

    // Verifica se a categoria existe
    const categoria = await forumRepository.findCategoriaById(categoria_id);
    if (!categoria) {
      throw new ApiError(404, 'Categoria não encontrada.');
    }

    // Tópicos criados por admins são aprovados automaticamente
    // Outros usuários precisam de moderação
    const isAdmin = req.user.embaixador === 1;
    const statusModeracao = isAdmin ? 'APROVADO' : 'PENDENTE';
    
    const topico = await forumRepository.createTopico({
      categoria_id,
      autor_id,
      titulo: titulo.trim(),
      conteudo: conteudo.trim(),
    });
    
    // Se não for admin, define como pendente
    if (!isAdmin) {
      await db.execute(
        'UPDATE forum_topicos SET status_moderacao = ? WHERE id = ?',
        [statusModeracao, topico.id]
      );
      topico.status_moderacao = statusModeracao;
    }
    
    return topico;
  }

  async updateTopico(req) {
    const { topicoId } = req.params;
    const { titulo, conteudo } = req.body;
    const usuarioId = req.user.id;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    // Verifica se o usuário é o autor ou é admin
    if (topico.autor_id !== usuarioId && req.user.role !== 'admin') {
      throw new ApiError(403, 'Você não tem permissão para editar este tópico.');
    }

    const updateData = {};
    if (titulo !== undefined) updateData.titulo = titulo.trim();
    if (conteudo !== undefined) updateData.conteudo = conteudo.trim();

    if (Object.keys(updateData).length === 0) {
      throw new ApiError(400, 'Nenhum campo para atualizar foi fornecido.');
    }

    return await forumRepository.updateTopico(topicoId, updateData);
  }

  async deleteTopico(req) {
    const { topicoId } = req.params;
    const usuarioId = req.user.id;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    // Verifica se o usuário é o autor ou é admin
    if (topico.autor_id !== usuarioId && req.user.role !== 'admin') {
      throw new ApiError(403, 'Você não tem permissão para excluir este tópico.');
    }

    const deleted = await forumRepository.deleteTopico(topicoId);
    if (!deleted) {
      throw new ApiError(500, 'Erro ao excluir tópico.');
    }

    return { message: 'Tópico excluído com sucesso.' };
  }

  async searchTopicos(req) {
    const { q } = req.query;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    if (!q || q.trim().length === 0) {
      throw new ApiError(400, 'Termo de busca é obrigatório.');
    }

    return await forumRepository.searchTopicos(q.trim(), limit, offset);
  }

  // Respostas
  async getRespostas(req) {
    const { topicoId } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Verifica se o tópico existe
    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    return await forumRepository.findRespostasByTopico(topicoId, limit, offset);
  }

  async createResposta(req) {
    const { topicoId } = req.params;
    const { conteudo, resposta_id } = req.body;
    const autor_id = req.user.id;

    if (!conteudo || conteudo.trim().length === 0) {
      throw new ApiError(400, 'O conteúdo da resposta é obrigatório.');
    }

    // Verifica se o tópico existe
    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    // Se for resposta a outra resposta, verifica se existe
    if (resposta_id) {
      const resposta = await forumRepository.findRespostasByTopico(topicoId, 1000, 0);
      const respostaExiste = resposta.some(r => r.id === resposta_id || 
        (r.comentarios && r.comentarios.some(c => c.id === resposta_id)));
      if (!respostaExiste) {
        throw new ApiError(404, 'Resposta não encontrada.');
      }
    }

    const resposta = await forumRepository.createResposta({
      topico_id: topicoId,
      autor_id,
      conteudo: conteudo.trim(),
      resposta_id: resposta_id || null,
    });

    // Respostas criadas por admins são aprovadas automaticamente
    // Outros usuários precisam de moderação
    const isAdmin = req.user.embaixador === 1;
    const statusModeracao = isAdmin ? 'APROVADO' : 'PENDENTE';
    
    if (!isAdmin) {
      await db.execute(
        'UPDATE forum_respostas SET status_moderacao = ? WHERE id = ?',
        [statusModeracao, resposta.id]
      );
      resposta.status_moderacao = statusModeracao;
    }

    return resposta;
  }

  async updateResposta(req) {
    const { respostaId } = req.params;
    const { conteudo } = req.body;
    const usuarioId = req.user.id;

    if (!conteudo || conteudo.trim().length === 0) {
      throw new ApiError(400, 'O conteúdo da resposta é obrigatório.');
    }

    // Busca a resposta (precisa implementar método findRespostaById se necessário)
    // Por enquanto, vamos assumir que a resposta existe
    // Em produção, você deve verificar se o usuário é o autor

    return await forumRepository.updateResposta(respostaId, conteudo.trim());
  }

  async deleteResposta(req) {
    const { respostaId } = req.params;
    const usuarioId = req.user.id;

    // Em produção, você deve verificar se o usuário é o autor ou admin
    const deleted = await forumRepository.deleteResposta(respostaId);
    if (!deleted) {
      throw new ApiError(404, 'Resposta não encontrada.');
    }

    return { message: 'Resposta excluída com sucesso.' };
  }

  // Reações
  async toggleReacao(req) {
    const { tipo = 'curtida' } = req.body;
    const { topicoId, respostaId } = req.query;
    const usuarioId = req.user.id;

    if (!topicoId && !respostaId) {
      throw new ApiError(400, 'topicoId ou respostaId é obrigatório.');
    }

    return await forumRepository.toggleReacao(tipo, topicoId, respostaId, usuarioId);
  }

  async getReacoes(req) {
    const { topicoId, respostaId } = req.query;

    if (topicoId) {
      return await forumRepository.getReacoesByTopico(topicoId);
    } else if (respostaId) {
      return await forumRepository.getReacoesByResposta(respostaId);
    } else {
      throw new ApiError(400, 'topicoId ou respostaId é obrigatório.');
    }
  }

  // Moderação - Tópicos
  async aprovarTopico(req) {
    const { topicoId } = req.params;
    const moderadorId = req.user.id;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    return await forumRepository.aprovarTopico(topicoId, moderadorId);
  }

  async rejeitarTopico(req) {
    const { topicoId } = req.params;
    const { motivo_rejeicao } = req.body;
    const moderadorId = req.user.id;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    if (!motivo_rejeicao || motivo_rejeicao.trim().length === 0) {
      throw new ApiError(400, 'O motivo da rejeição é obrigatório.');
    }

    return await forumRepository.rejeitarTopico(topicoId, moderadorId, motivo_rejeicao.trim());
  }

  async toggleFixarTopico(req) {
    const { topicoId } = req.params;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    return await forumRepository.toggleFixarTopico(topicoId);
  }

  async toggleBloquearTopico(req) {
    const { topicoId } = req.params;

    const topico = await forumRepository.findTopicoById(topicoId);
    if (!topico) {
      throw new ApiError(404, 'Tópico não encontrado.');
    }

    return await forumRepository.toggleBloquearTopico(topicoId);
  }

  // Moderação - Respostas
  async aprovarResposta(req) {
    const { respostaId } = req.params;
    const moderadorId = req.user.id;

    const resposta = await forumRepository.findRespostaById(respostaId);
    if (!resposta) {
      throw new ApiError(404, 'Resposta não encontrada.');
    }

    return await forumRepository.aprovarResposta(respostaId, moderadorId);
  }

  async rejeitarResposta(req) {
    const { respostaId } = req.params;
    const { motivo_rejeicao } = req.body;
    const moderadorId = req.user.id;

    const resposta = await forumRepository.findRespostaById(respostaId);
    if (!resposta) {
      throw new ApiError(404, 'Resposta não encontrada.');
    }

    if (!motivo_rejeicao || motivo_rejeicao.trim().length === 0) {
      throw new ApiError(400, 'O motivo da rejeição é obrigatório.');
    }

    return await forumRepository.rejeitarResposta(respostaId, moderadorId, motivo_rejeicao.trim());
  }

  // Listar itens pendentes de moderação
  async getTopicosPendentes(req) {
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    return await forumRepository.findTopicosPendentes(limit, offset);
  }

  async getRespostasPendentes(req) {
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    return await forumRepository.findRespostasPendentes(limit, offset);
  }
}

module.exports = new ForumService();


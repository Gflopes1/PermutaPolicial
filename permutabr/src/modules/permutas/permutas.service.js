// /src/modules/permutas/permutas.service.js

const policiaisRepository = require('../policiais/policiais.repository');
const intencoesRepository = require('../intencoes/intencoes.repository');
const permutasRepository = require('./permutas.repository');
const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const ApiError = require('../../core/utils/ApiError');

class PermutasService {
    async findMatchesForPolicial(policialId, filters) {
        try {
            const profile = await policiaisRepository.findProfileById(policialId);

            // ✅ VALIDAÇÃO SIMPLIFICADA - apenas o essencial
            // Aceita se tiver unidade OU município definido
            if (!profile || (!profile.unidade_atual_id && !profile.municipio_atual_id)) {
                return {
                    configuracao: {
                        regra_permuta: 'Defina sua lotação atual para ver as combinações.'
                    },
                    interessados: [], diretas: [], triangulares: []
                };
            }

            const intencoes = await intencoesRepository.findByPolicialId(policialId);

            const aceitaInterestadual = profile.lotacao_interestadual === 1;
            let forcaCondition = '', forcaParams = [], forcaMatchCondition = '';

            // ✅ LÓGICA CORRETA: apenas escopo (interestadual vs estadual)
            if (aceitaInterestadual) {
                // Permuta interestadual: mesma categoria de força (PM, PC, etc)
                forcaCondition = 'f2.tipo_permuta = ?';
                forcaParams = [profile.forca_tipo_permuta]; // BM, PM, PC, etc
                forcaMatchCondition = 'f_A.tipo_permuta = f_B.tipo_permuta';
            } else {
                // Permuta estadual: mesma força específica
                forcaCondition = 'p2.forca_id = ?';
                forcaParams = [profile.forca_id];
                forcaMatchCondition = 'A.forca_id = B.forca_id';
            }

            const [interessados, diretas, triangularesRaw, notificacoes] = await Promise.all([
                permutasRepository.findInteressados({ profile, forcaCondition, forcaParams }),
                permutasRepository.findDiretas({ profile, forcaMatchCondition }),
                permutasRepository.findTriangulares({ profile, forcaMatchCondition }),
                notificacoesRepository.findAllByUsuario(policialId)
            ]);

            // ✅ Cria mapas para verificar solicitações de contato e aceitações
            const solicitacoesPendentes = new Map(); // policialId -> true se há solicitação pendente
            const aceitacoes = new Map(); // policialId -> dados da aceitação
            
            notificacoes.forEach(notif => {
                if (notif.tipo === 'SOLICITACAO_CONTATO' && notif.referencia_id && notif.lida === 0) {
                    solicitacoesPendentes.set(notif.referencia_id, true);
                } else if (notif.tipo === 'SOLICITACAO_CONTATO_ACEITA' && notif.referencia_id) {
                    aceitacoes.set(notif.referencia_id, {
                        nome: notif.aceitador_nome,
                        contato: notif.aceitador_contato,
                        forcaNome: notif.aceitador_forca_nome,
                        forcaSigla: notif.aceitador_forca_sigla,
                        estadoSigla: notif.aceitador_estado_sigla,
                        cidadeNome: notif.aceitador_cidade_nome,
                        unidadeNome: notif.aceitador_unidade_nome,
                        postoNome: notif.aceitador_posto_nome,
                        // ✅ Mantém também em snake_case para compatibilidade
                        aceitador_nome: notif.aceitador_nome,
                        aceitador_contato: notif.aceitador_contato,
                        aceitador_forca_nome: notif.aceitador_forca_nome,
                        aceitador_forca_sigla: notif.aceitador_forca_sigla,
                        aceitador_estado_sigla: notif.aceitador_estado_sigla,
                        aceitador_cidade_nome: notif.aceitador_cidade_nome,
                        aceitador_unidade_nome: notif.aceitador_unidade_nome,
                        aceitador_posto_nome: notif.aceitador_posto_nome,
                    });
                }
            });

            // ✅ Função auxiliar para enriquecer um match com informações de solicitação
            const enriquecerMatch = (match) => {
                const matchId = match.id;
                return {
                    ...match,
                    ja_solicitado: solicitacoesPendentes.has(matchId),
                    aceitou_compartilhar: aceitacoes.has(matchId),
                    dados_aceitacao: aceitacoes.get(matchId) || null,
                };
            };

            const triangulares = triangularesRaw.map(row => {
                const policialB = {
                    id: row.policial_b_id,
                    nome: row.policial_b_nome,
                    qso: row.policial_b_qso,
                    postoGraduacaoNome: row.policial_b_posto_nome,
                    forcaSigla: row.policial_b_forca_sigla,
                    unidadeAtual: row.policial_b_unidade,
                    municipioAtual: row.policial_b_municipio,
                    estadoAtual: row.policial_b_estado,
                    ocultar_no_mapa: row.policial_b_ocultar_no_mapa || false,
                };
                const policialC = {
                    id: row.policial_c_id,
                    nome: row.policial_c_nome,
                    qso: row.policial_c_qso,
                    postoGraduacaoNome: row.policial_c_posto_nome,
                    forcaSigla: row.policial_c_forca_sigla,
                    unidadeAtual: row.policial_c_unidade,
                    municipioAtual: row.policial_c_municipio,
                    estadoAtual: row.policial_c_estado,
                    ocultar_no_mapa: row.policial_c_ocultar_no_mapa || false,
                };
                return {
                    policialB: enriquecerMatch(policialB),
                    policialC: enriquecerMatch(policialC),
                    fluxo: {
                        a_para_b: row.descricao_a,
                        b_para_c: row.descricao_b,
                        c_para_a: row.descricao_c
                    }
                };
            });

            const regraPermuta = intencoes.length === 0
                ? 'Adicione suas intenções de destino para encontrar combinações!'
                : (aceitaInterestadual
                    ? `Você pode permutar com qualquer ${profile.forca_tipo_permuta} de outros estados.`
                    : `Você só pode permutar dentro da ${profile.forca_sigla}.`);

            return {
                configuracao: {
                    aceita_permuta_interestadual: aceitaInterestadual,
                    tipo_permuta: profile.forca_tipo_permuta,
                    forca_sigla: profile.forca_sigla,
                    regra_permuta: regraPermuta
                },
                interessados: interessados.map(enriquecerMatch),
                diretas: diretas.map(enriquecerMatch),
                triangulares
            };

        } catch (error) {
            console.error('\n💥 ERRO CAPTURADO NO SERVICE:', error);
            throw error;
        }
    }
}

module.exports = new PermutasService();
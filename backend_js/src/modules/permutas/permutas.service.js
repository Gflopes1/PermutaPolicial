// /src/modules/permutas/permutas.service.js

const db = require('../../config/db');
const policiaisRepository = require('../policiais/policiais.repository');
const intencoesRepository = require('../intencoes/intencoes.repository');
const permutasRepository = require('./permutas.repository');
const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const matchAlertsService = require('../match-alerts/match-alerts.service');
const { attachLegacyMetrics } = require('./permutas-metrics');

async function resolveMunicipioAtual(profile, intencoes) {
    const [intencoesPerfil] = await db.execute(
        'SELECT unidade_atual_id, municipio_atual_id FROM intencoes WHERE policial_id = ? ORDER BY prioridade ASC LIMIT 1',
        [profile.id]
    );

    let unidadeAtualId = profile.unidade_atual_id;
    let municipioAtualId = profile.municipio_atual_id;

    if (
        intencoesPerfil.length > 0 &&
        (intencoesPerfil[0].unidade_atual_id || intencoesPerfil[0].municipio_atual_id)
    ) {
        unidadeAtualId = intencoesPerfil[0].unidade_atual_id;
        municipioAtualId = intencoesPerfil[0].municipio_atual_id;
    }

    if (!municipioAtualId && unidadeAtualId) {
        const [unidadeRows] = await db.execute(
            'SELECT municipio_id FROM unidades WHERE id = ?',
            [unidadeAtualId]
        );
        if (unidadeRows.length > 0) {
            municipioAtualId = unidadeRows[0].municipio_id;
        }
    }

    return municipioAtualId;
}

async function resolveIntencoesComRaio(intencoes) {
    const comRaio = intencoes.filter(
        (i) =>
            i.raio_km != null &&
            (i.tipo_intencao === 'MUNICIPIO' || i.tipo_intencao === 'UNIDADE')
    );

    const unidadeIds = [
        ...new Set(
            comRaio
                .filter((i) => i.tipo_intencao === 'UNIDADE' && i.unidade_id)
                .map((i) => i.unidade_id)
        ),
    ];

    const municipioByUnidadeId = new Map();
    if (unidadeIds.length > 0) {
        const placeholders = unidadeIds.map(() => '?').join(',');
        const [rows] = await db.execute(
            `SELECT id, municipio_id FROM unidades WHERE id IN (${placeholders})`,
            unidadeIds
        );
        for (const row of rows) {
            municipioByUnidadeId.set(row.id, row.municipio_id);
        }
    }

    const resolved = [];
    for (const intencao of comRaio) {
        let destinoMunicipioId = intencao.municipio_id;

        if (intencao.tipo_intencao === 'UNIDADE' && intencao.unidade_id) {
            destinoMunicipioId = municipioByUnidadeId.get(intencao.unidade_id) ?? null;
        }

        if (destinoMunicipioId) {
            resolved.push({
                ...intencao,
                destino_municipio_id: destinoMunicipioId,
            });
        }
    }

    return resolved;
}

class PermutasService {
    async findMatchesForPolicial(policialId) {
        try {
            const profile = await policiaisRepository.findProfileById(policialId);
            const intencoes = await intencoesRepository.findByPolicialId(policialId);

            const hasProfileLocation = profile?.unidade_atual_id || profile?.municipio_atual_id;
            const hasIntencaoLocation = intencoes.some(
                (i) => i.unidade_atual_id || i.municipio_atual_id
            );

            if (!profile || (!hasProfileLocation && !hasIntencaoLocation)) {
                return {
                    configuracao: {
                        regra_permuta: 'Defina sua lotação atual para ver as combinações.',
                    },
                    interessados: [],
                    diretas: [],
                    triangulares: [],
                    proximas: [],
                    triangulares_proximas: [],
                };
            }

            const municipioAtualId = await resolveMunicipioAtual(profile, intencoes);
            const intencoesComRaio = await resolveIntencoesComRaio(intencoes);

            const aceitaInterestadual = profile.lotacao_interestadual === 1;
            let forcaCondition = '';
            let forcaParams = [];
            let forcaMatchCondition = '';
            let forcaTriangularCondition = '';

            if (aceitaInterestadual) {
                forcaCondition = 'f2.tipo_permuta = ?';
                forcaParams = [profile.forca_tipo_permuta];
                forcaMatchCondition = 'f_A.tipo_permuta = f_B.tipo_permuta';
                forcaTriangularCondition =
                    'f_A.tipo_permuta = f_B.tipo_permuta AND f_B.tipo_permuta = f_C.tipo_permuta';
            } else {
                forcaCondition = 'p2.forca_id = ?';
                forcaParams = [profile.forca_id];
                forcaMatchCondition = 'A.forca_id = B.forca_id';
                forcaTriangularCondition = 'A.forca_id = B.forca_id AND B.forca_id = C.forca_id';
            }

            const proximasPromise =
                intencoesComRaio.length > 0 && municipioAtualId
                    ? permutasRepository.findProximasPorMinhasIntencoes({
                          profile,
                          forcaMatchCondition,
                          intencoesComRaio,
                          municipioAtualId,
                      })
                    : Promise.resolve([]);

            const [
                interessados,
                diretas,
                triangularesRaw,
                triangularesProximasRaw,
                notificacoes,
                proximasMinhas,
            ] = await Promise.all([
                permutasRepository.findInteressados({ profile, forcaCondition, forcaParams }),
                permutasRepository.findDiretas({ profile, forcaMatchCondition }),
                permutasRepository.findTriangulares({ profile, forcaTriangularCondition }),
                permutasRepository.findTriangularesProximas({ profile, forcaTriangularCondition }),
                notificacoesRepository.findContactStatusByUsuario(policialId),
                proximasPromise,
            ]);

            const solicitacoesPendentes = new Map();
            const aceitacoes = new Map();

            notificacoes.forEach((notif) => {
                if (
                    notif.tipo === 'SOLICITACAO_CONTATO' &&
                    notif.referencia_id &&
                    notif.lida === 0
                ) {
                    solicitacoesPendentes.set(notif.referencia_id, true);
                } else if (notif.tipo === 'SOLICITACAO_CONTATO_ACEITA' && notif.referencia_id) {
                    aceitacoes.set(notif.referencia_id, {
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

            const enriquecerMatch = (match) => {
                const matchId = match.id;
                return {
                    ...match,
                    ja_solicitado: solicitacoesPendentes.has(matchId),
                    aceitou_compartilhar: aceitacoes.has(matchId),
                    dados_aceitacao: aceitacoes.get(matchId) || null,
                };
            };

            const mapTriangularRow = (row) => {
                const policialB = {
                    id: row.policial_b_id,
                    nome: row.policial_b_nome,
                    qso: row.policial_b_qso,
                    posto_graduacao_nome: row.policial_b_posto_nome,
                    forca_sigla: row.policial_b_forca_sigla,
                    unidade_atual: row.policial_b_unidade,
                    municipio_atual: row.policial_b_municipio,
                    estado_atual: row.policial_b_estado,
                    ocultar_no_mapa: row.policial_b_ocultar_no_mapa || false,
                };
                const policialC = {
                    id: row.policial_c_id,
                    nome: row.policial_c_nome,
                    qso: row.policial_c_qso,
                    posto_graduacao_nome: row.policial_c_posto_nome,
                    forca_sigla: row.policial_c_forca_sigla,
                    unidade_atual: row.policial_c_unidade,
                    municipio_atual: row.policial_c_municipio,
                    estado_atual: row.policial_c_estado,
                    ocultar_no_mapa: row.policial_c_ocultar_no_mapa || false,
                };
                return {
                    policialB: enriquecerMatch(policialB),
                    policialC: enriquecerMatch(policialC),
                    fluxo: {
                        a_para_b: row.descricao_a,
                        b_para_c: row.descricao_b,
                        c_para_a: row.descricao_c,
                    },
                    distancia_km: row.distancia_km ?? null,
                    por_aproximacao: row.por_aproximacao === 1 || row.por_aproximacao === true,
                };
            };

            const triangulares = triangularesRaw.map(mapTriangularRow);

            const chavesTriangularesExatas = new Set(
                triangularesRaw.map((r) => `${r.policial_b_id}-${r.policial_c_id}`)
            );

            const triangularesProximas = triangularesProximasRaw
                .filter((r) => !chavesTriangularesExatas.has(`${r.policial_b_id}-${r.policial_c_id}`))
                .map(mapTriangularRow);

            const idsExatos = new Set([
                ...interessados.map((m) => m.id),
                ...diretas.map((m) => m.id),
            ]);

            const proximasMap = new Map();
            for (const row of proximasMinhas) {
                if (idsExatos.has(row.id)) continue;
                if (row.tipo_proximidade && row.tipo_proximidade !== 'DIRETA') continue;
                const existing = proximasMap.get(row.id);
                if (!existing || parseFloat(row.distancia_km) < parseFloat(existing.distancia_km)) {
                    proximasMap.set(row.id, row);
                }
            }

            const proximas = Array.from(proximasMap.values())
                .sort((a, b) => parseFloat(a.distancia_km) - parseFloat(b.distancia_km))
                .map(enriquecerMatch);

            let regraPermuta =
                intencoes.length === 0
                    ? 'Adicione suas intenções de destino para encontrar combinações!'
                    : aceitaInterestadual
                      ? `Você pode permutar com qualquer ${profile.forca_tipo_permuta} de outros estados.`
                      : `Você só pode permutar dentro da ${profile.forca_sigla}.`;

            if (intencoesComRaio.length > 0) {
                regraPermuta +=
                    ' Permutas próximas exigem match mútuo (raio nos dois sentidos). Triangulares por aproximação usam o raio das intenções.';
            }

            const resultado = {
                configuracao: {
                    aceita_permuta_interestadual: aceitaInterestadual,
                    tipo_permuta: profile.forca_tipo_permuta,
                    forca_sigla: profile.forca_sigla,
                    regra_permuta: regraPermuta,
                    tem_raio_configurado: intencoesComRaio.length > 0,
                },
                interessados: interessados.map(enriquecerMatch),
                diretas: diretas.map(enriquecerMatch),
                triangulares,
                triangulares_proximas: triangularesProximas,
                proximas,
            };

            setImmediate(() => {
                matchAlertsService.processMatchesForUser(policialId, resultado).catch((err) => {
                    console.error('[match-alerts] Erro ao processar alertas:', err.message);
                });
            });

            return attachLegacyMetrics(resultado);
        } catch (error) {
            console.error('\n💥 ERRO CAPTURADO NO SERVICE:', error);
            throw error;
        }
    }
}

module.exports = new PermutasService();

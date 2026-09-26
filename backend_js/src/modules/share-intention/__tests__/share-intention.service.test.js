// Mock do pool mysql2/promise (src/config/db.js exporta o pool): execute() resolve [rows, fields].
jest.mock('../../../config/db', () => ({ execute: jest.fn() }));

const db = require('../../../config/db');
const service = require('../share-intention.service');

const FIELDS = [{ name: 'mock' }];
const INTENCAO_ROW = {
  id: 4579,
  tipo_intencao: 'MUNICIPIO',
  forca_sigla: 'PMRS',
  posto_nome: 'Soldado',
  origem_nome: 'Frederico Westphalen',
  origem_uf: 'RS',
  destino_estado_uf: 'RS',
  destino_municipio_nome: 'Porto Alegre',
  destino_municipio_uf: 'RS',
  destino_unidade_nome: null,
  destino_unidade_municipio: null,
  destino_unidade_uf: null,
};

/** Simula o banco de staging: referral_codes(id=90,user_id=303,'CONLEX52'), intencoes(4579 -> 303). */
function stagingDb({ codes = [{ id: 90, user_id: 303, code: 'CONLEX52' }], intencoes = { 4579: 303 } } = {}) {
  db.execute.mockImplementation(async (sql, params = []) => {
    if (params.some((p) => p === undefined)) throw new Error('Bind parameters must not contain undefined');
    if (/FROM referral_codes rc\s+JOIN policiais p/.test(sql) && /WHERE rc\.code = \?/.test(sql) && !/DATABASE\(\)/.test(sql)) {
      const row = codes.find((c) => c.code === params[0]);
      return [row ? [{ ...row, nome: 'Admin', qso: null, forca_sigla: 'PMRS' }] : [], FIELDS];
    }
    if (/DATABASE\(\)/.test(sql)) {
      const row = codes.find((c) => c.code === params[0]);
      return [[{ db: 'permutadevdb', total_codes: codes.length, raw_owner: row ? row.user_id : null }], FIELDS];
    }
    if (/FROM intencoes i/.test(sql)) {
      const [id, owner] = params;
      return [intencoes[id] === owner ? [{ ...INTENCAO_ROW, id }] : [], FIELDS];
    }
    if (/SELECT policial_id FROM intencoes/.test(sql)) {
      const owner = intencoes[params[0]];
      return [owner ? [{ policial_id: owner }] : [], FIELDS];
    }
    if (/COUNT\(\*\) AS total FROM policiais/.test(sql)) return [[{ total: 1234 }], FIELDS];
    return [[], FIELDS];
  });
}

const req = { get: () => 'dev.br.permutapolicial.com.br' };
const og = (html, prop) => (html.match(new RegExp(`property="${prop}" content="([^"]*)"`)) || [])[1];

describe('share-intention service', () => {
  let warn;
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.FLUTTER_WEB_ROOT = '/nonexistent-flutter-root';
    warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });
  afterEach(() => warn.mockRestore());

  it('encontra o dono do código com a mesma consulta de /api/referral/validate', async () => {
    stagingDb();
    await expect(service.findCodeOwner('CONLEX52')).resolves.toBe(303);
    const [sql, params] = db.execute.mock.calls[0];
    expect(sql).toMatch(/FROM referral_codes rc/);
    expect(params).toEqual(['CONLEX52']);
  });

  it('/r/CONLEX52?i=4579 gera OG da intenção (ocultar_no_mapa não exclui)', async () => {
    stagingDb();
    const { html } = await service.buildShareLandingHTML('CONLEX52', '4579', req);
    expect(og(html, 'og:url')).toBe('https://dev.br.permutapolicial.com.br/r/CONLEX52?i=4579');
    expect(og(html, 'og:image')).toBe('https://dev.br.permutapolicial.com.br/r/CONLEX52/preview.png?i=4579');
    expect(og(html, 'og:title')).toContain('Frederico Westphalen');
    expect(og(html, 'og:title')).toContain('Porto Alegre');
    expect(html).toContain('/auth/register?ref=CONLEX52');
    expect(warn).not.toHaveBeenCalled();
  });

  it('aceita código minúsculo e ?i com pontuação colada', async () => {
    stagingDb();
    const ctx = await service.resolveContext('conlex52', '4579.');
    expect(ctx).toMatchObject({ code: 'CONLEX52', codeValid: true, intencaoId: 4579 });
    expect(ctx.info.destino).toBe('Porto Alegre');
  });

  it('código inexistente: mantém ref, loga motivo com diagnóstico', async () => {
    stagingDb({ codes: [] });
    const ctx = await service.resolveContext('NOPE1234', '4579');
    expect(ctx).toMatchObject({ code: 'NOPE1234', codeValid: false, info: null });
    expect(warn.mock.calls[0][0]).toMatch(/codigo_nao_encontrado_em_referral_codes.*"db":"permutadevdb"/);
  });

  it('intenção de outro policial não é exibida', async () => {
    stagingDb({ intencoes: { 4579: 999 } });
    const ctx = await service.resolveContext('CONLEX52', '4579');
    expect(ctx.info).toBeNull();
    expect(warn.mock.calls[0][0]).toMatch(/pertence_a_policial_999/);
  });

  it('preview.png com intenção é PNG 1200x630', async () => {
    stagingDb();
    const buf = await service.generatePreviewImage('CONLEX52', '4579');
    expect(buf.slice(1, 4).toString()).toBe('PNG');
    expect(buf.readUInt32BE(16)).toBe(1200);
    expect(buf.readUInt32BE(20)).toBe(630);
  });
});

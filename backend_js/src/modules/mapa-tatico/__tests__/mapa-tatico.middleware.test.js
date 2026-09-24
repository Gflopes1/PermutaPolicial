const { requirePointAccess } = require('../middlewares/mapa-tatico.middleware');
const mapaTaticoRepository = require('../mapa-tatico.repository');
const ApiError = require('../../../core/utils/ApiError');

jest.mock('../mapa-tatico.repository');

describe('requirePointAccess — visibilidade PRIVATE', () => {
  let req;
  let next;

  beforeEach(() => {
    jest.clearAllMocks();
    req = { params: { id: '5' }, user: { id: 2 } };
    next = jest.fn();
  });

  it('retorna 404 para não-dono (não 403)', async () => {
    mapaTaticoRepository.findPointById = jest.fn().mockResolvedValue({
      id: 5,
      group_id: 1,
      creator_id: 1,
      visibility: 'PRIVATE',
    });
    mapaTaticoRepository.findMember = jest.fn().mockResolvedValue({ user_id: 2 });

    await requirePointAccess(req, {}, next);

    expect(next).toHaveBeenCalledWith(expect.any(ApiError));
    const err = next.mock.calls[0][0];
    expect(err.statusCode).toBe(404);
  });

  it('permite acesso ao criador do ponto PRIVATE', async () => {
    mapaTaticoRepository.findPointById = jest.fn().mockResolvedValue({
      id: 5,
      group_id: 1,
      creator_id: 2,
      visibility: 'PRIVATE',
    });
    mapaTaticoRepository.findMember = jest.fn().mockResolvedValue({ user_id: 2 });

    await requirePointAccess(req, {}, next);

    expect(next).toHaveBeenCalledWith();
    expect(req.point.creator_id).toBe(2);
  });
});

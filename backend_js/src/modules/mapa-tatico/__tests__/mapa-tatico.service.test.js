const mockEmit = jest.fn();
const mockTo = jest.fn(() => ({ emit: mockEmit }));

jest.mock('../../../config/socket', () => ({
  getIO: jest.fn(() => ({ to: mockTo })),
}));

const mapaTaticoService = require('../mapa-tatico.service');
const mapaTaticoRepository = require('../mapa-tatico.repository');
const mapaTaticoSocket = require('../mapa-tatico.socket');
const mapaTaticoNotifications = require('../mapa-tatico.notifications.service');
const mapaTaticoStorage = require('../mapa-tatico-storage.service');
const ApiError = require('../../../core/utils/ApiError');

jest.mock('../mapa-tatico.repository');
jest.mock('../mapa-tatico.notifications.service');
jest.mock('../mapa-tatico-storage.service');
jest.mock('../policiais/policiais.oauth.repository', () => ({}), { virtual: true });

describe('MapaTaticoService — visibilidade PRIVATE', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mapaTaticoStorage.isStorageConfigured = jest.fn().mockReturnValue(true);
    mapaTaticoStorage.uploadPhoto = jest.fn();
    mapaTaticoNotifications.notifyOperationalPointCreated = jest.fn().mockResolvedValue(undefined);
  });

  describe('getPoints', () => {
    it('repassa requestingUserId ao repositório para filtrar pontos PRIVATE', async () => {
      mapaTaticoRepository.findMember = jest.fn().mockResolvedValue({ user_id: 2 });
      mapaTaticoRepository.findPointsByGroup = jest.fn().mockResolvedValue([]);

      await mapaTaticoService.getPoints({
        user: { id: 2 },
        query: { group_id: '1', map_type: 'OPERATIONAL' },
      });

      expect(mapaTaticoRepository.findPointsByGroup).toHaveBeenCalledWith(1, 'OPERATIONAL', null, 2, null, 0);
    });
  });

  describe('createPoint', () => {
    const baseReq = {
      user: { id: 10 },
      body: {
        group_id: 1,
        title: 'Teste privado',
        lat: -23.5,
        lng: -46.6,
        type: 'local_interesse',
        map_type: 'OPERATIONAL',
        visibility: 'PRIVATE',
      },
    };

    beforeEach(() => {
      mapaTaticoRepository.findGroupById = jest.fn().mockResolvedValue({ id: 1, is_global: 0 });
      mapaTaticoRepository.findMember = jest.fn().mockResolvedValue({ user_id: 10, is_muted: false });
      mapaTaticoRepository.createPoint = jest.fn().mockResolvedValue({
        id: 99,
        group_id: 1,
        creator_id: 10,
        visibility: 'PRIVATE',
        map_type: 'OPERATIONAL',
        title: 'Teste privado',
      });
      mapaTaticoRepository.findPointById = jest.fn().mockResolvedValue({
        id: 99,
        group_id: 1,
        creator_id: 10,
        visibility: 'PRIVATE',
        map_type: 'OPERATIONAL',
        title: 'Teste privado',
        photos: [],
      });
      mapaTaticoRepository.createAuditLog = jest.fn().mockResolvedValue(undefined);
    });

    it('não notifica o grupo quando visibility é PRIVATE', async () => {
      await mapaTaticoService.createPoint(baseReq);

      expect(mapaTaticoNotifications.notifyOperationalPointCreated).not.toHaveBeenCalled();
    });

    it('rejeita suspeito no grupo global/nacional', async () => {
      mapaTaticoRepository.findGroupById = jest.fn().mockResolvedValue({ id: 1, is_global: 1 });

      await expect(
        mapaTaticoService.createPoint({
          ...baseReq,
          body: { ...baseReq.body, type: 'suspeito' },
        })
      ).rejects.toMatchObject({ statusCode: 400 });

      await expect(
        mapaTaticoService.createPoint({
          ...baseReq,
          body: { ...baseReq.body, type: 'ocorrencia_recente' },
        })
      ).rejects.toMatchObject({ statusCode: 400 });
    });
  });

  describe('createComment / createVisit / reportPoint', () => {
    const privatePoint = {
      id: 5,
      group_id: 1,
      creator_id: 1,
      visibility: 'PRIVATE',
      map_type: 'OPERATIONAL',
      title: 'Secreto',
    };

    it('bloqueia comentário de não-dono em ponto PRIVATE', async () => {
      await expect(
        mapaTaticoService.createComment({
          user: { id: 2 },
          point: privatePoint,
          body: { text: 'oi' },
        })
      ).rejects.toThrow(ApiError);
    });

    it('bloqueia visita de não-dono em ponto PRIVATE', async () => {
      await expect(
        mapaTaticoService.createVisit({
          user: { id: 2 },
          point: { ...privatePoint, map_type: 'LOGISTICS' },
        })
      ).rejects.toThrow(ApiError);
    });

    it('bloqueia denúncia de não-dono em ponto PRIVATE', async () => {
      await expect(
        mapaTaticoService.reportPoint({
          user: { id: 2 },
          point: privatePoint,
          body: {},
        })
      ).rejects.toThrow(ApiError);
    });
  });
});

describe('MapaTaticoSocket — pontos PRIVATE', () => {
  beforeEach(() => {
    mockTo.mockClear();
    mockEmit.mockClear();
  });

  it('emitPointCreated envia só para o criador quando PRIVATE', () => {
    mapaTaticoSocket.emitPointCreated(1, {
      id: 7,
      creator_id: 42,
      visibility: 'PRIVATE',
      title: 'Oculto',
    });

    expect(mockTo).toHaveBeenCalledWith('user_42');
    expect(mockTo).not.toHaveBeenCalledWith('mapa_tatico_group_1');
  });
});

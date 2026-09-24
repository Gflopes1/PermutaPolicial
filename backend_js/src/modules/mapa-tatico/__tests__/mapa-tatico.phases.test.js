process.env.ENCRYPTION_MASTER_KEY = Buffer.alloc(32, 9).toString('base64');

const mapaTaticoAdminService = require('../admin/mapa-tatico-admin.service');
const mapaTaticoAdminRepository = require('../admin/mapa-tatico-admin.repository');
const mapaTaticoRepository = require('../mapa-tatico.repository');
const mapaTaticoService = require('../mapa-tatico.service');
const ApiError = require('../../../core/utils/ApiError');

jest.mock('../admin/mapa-tatico-admin.repository');
jest.mock('../mapa-tatico.repository');
jest.mock('../../../config/db', () => ({}));
jest.mock('../mapa-tatico-storage.service', () => ({
  isStorageConfigured: jest.fn().mockReturnValue(true),
  uploadPhoto: jest.fn(),
  deletePhoto: jest.fn().mockResolvedValue(undefined),
}));
jest.mock('../mapa-tatico.socket', () => ({
  emitPointCreated: jest.fn(),
  emitPointUpdated: jest.fn(),
  emitPointDeleted: jest.fn(),
  emitCommentAdded: jest.fn(),
}));
jest.mock('../mapa-tatico.notifications.service', () => ({
  notifyOperationalPointCreated: jest.fn().mockResolvedValue(undefined),
}));

describe('MapaTaticoAdminService', () => {
  beforeEach(() => jest.clearAllMocks());

  it('removeMember exige motivo mínimo', async () => {
    await expect(
      mapaTaticoAdminService.removeMember({
        params: { id: '1', userId: '2' },
        body: { motivo: 'curto' },
        user: { id: 99 },
      })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('listGroups registra VIEW_GROUP_LIST', async () => {
    mapaTaticoAdminRepository.createAdminActionLog = jest.fn().mockResolvedValue(undefined);
    mapaTaticoAdminRepository.findGroupsForAdmin = jest.fn().mockResolvedValue([]);
    await mapaTaticoAdminService.listGroups({ user: { id: 1 }, query: {} });
    expect(mapaTaticoAdminRepository.createAdminActionLog).toHaveBeenCalledWith(1, 'VIEW_GROUP_LIST');
  });
});

describe('MapaTaticoService — fotos', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejeita mais de 10 fotos na criação', async () => {
    mapaTaticoRepository.findGroupById = jest.fn().mockResolvedValue({ id: 1, is_global: 0 });
    mapaTaticoRepository.findMember = jest.fn().mockResolvedValue({ user_id: 1, is_muted: false });

    const files = Array.from({ length: 11 }, (_, i) => ({
      buffer: Buffer.from([0xff, 0xd8, 0xff, i]),
      mimetype: 'image/jpeg',
    }));

    await expect(
      mapaTaticoService.createPoint({
        user: { id: 1 },
        files,
        body: {
          group_id: 1,
          title: 'Teste',
          lat: -23.5,
          lng: -46.6,
          type: 'local_interesse',
          map_type: 'OPERATIONAL',
        },
      })
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});

describe('MapaTaticoAdminRepository — mascaramento PRIVATE', () => {
  it('remove campos sensíveis de pontos PRIVATE', () => {
    jest.unmock('../admin/mapa-tatico-admin.repository');
    const repo = require('../admin/mapa-tatico-admin.repository');
    const masked = repo.maskPrivatePointForAdmin({
      id: 3,
      type: 'suspeito',
      map_type: 'OPERATIONAL',
      visibility: 'PRIVATE',
      creator_id: 7,
      title: 'Secreto',
      description: 'Não deve vazar',
      address: 'Rua X',
      lat: -23,
      lng: -46,
      photos: [{ id: 1, url: 'x' }],
    });
    expect(masked.title).toBeUndefined();
    expect(masked.description).toBeUndefined();
    expect(masked.address).toBeUndefined();
    expect(masked.lat).toBeUndefined();
    expect(masked.photos).toBeUndefined();
    expect(masked.visibility).toBe('PRIVATE');
  });
});

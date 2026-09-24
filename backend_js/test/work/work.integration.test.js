// /test/work/work.integration.test.js

const request = require('supertest');
const app = require('../../server');
const db = require('../../src/config/db');

describe('Work API Integration Tests', () => {
  let authToken;
  let testUserId;

  beforeAll(async () => {
    // Cria usuário de teste e obtém token
    // (implementar conforme necessário)
  });

  afterAll(async () => {
    // Limpa dados de teste
    await db.end();
  });

  describe('GET /api/work/month', () => {
    test('deve retornar dias do mês', async () => {
      const response = await request(app)
        .get('/api/work/month?month=4&year=2024')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('POST /api/work/day', () => {
    test('deve criar/atualizar dia de trabalho', async () => {
      const dayData = {
        data: '2024-04-15',
        tipo: 'normal',
        total_hours: 8.0,
        etapas: 1,
      };

      const response = await request(app)
        .post('/api/work/day')
        .set('Authorization', `Bearer ${authToken}`)
        .send(dayData)
        .expect(200);

      expect(response.body.status).toBe('success');
    });
  });
});



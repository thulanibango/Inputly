import request from 'supertest';
import app from '../src/app.js';

describe('API Endpoints', () => {
  describe('GET/', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/').set('User-Agent', 'jest-tests');
      expect(response.status).toBe(200);
      expect(response.text).toBe('Hello from Inputly!');
    });
  });
  describe('GET/api', () => {
    it('inputly is running', async () => {
      const response = await request(app).get('/api').set('User-Agent', 'jest-tests');
      expect(response.status).toBe(200);
      expect(response.type).toMatch(/json/);
      expect(response.body).toHaveProperty('status', 'OK');
      expect(response.body).toHaveProperty('message', 'Inputly is running');
    });
  });
  describe('GET/health', () => {
    it('inputly is running', async () => {
      const response = await request(app).get('/health').set('User-Agent', 'jest-tests');
      expect(response.status).toBe(200);
      expect(response.type).toMatch(/json/);
      expect(response.body).toHaveProperty('status', 'OK');
      expect(response.body).toHaveProperty('message', 'Inputly is running');
    });
  });
  describe('GET/noneexisting', () => {
    it('should return 404 Not Found', async () => {
      const response = await request(app).get('/noneexisting').set('User-Agent', 'jest-tests');
      expect(response.status).toBe(404);
      expect(response.type).toMatch(/json/);
      expect(response.body).toHaveProperty('status', 'fail');
      expect(response.body).toHaveProperty('message', 'route Not found');
    });
  });

});
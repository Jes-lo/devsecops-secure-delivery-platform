const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const { createApp } = require('../src/app');

test('GET /health returns application health', async () => {
  const response = await request(createApp())
    .get('/health')
    .expect(200);

  assert.deepEqual(response.body, {
    status: 'ok'
  });

  assert.equal(response.headers['x-powered-by'], undefined);
});

test('GET /version returns application metadata', async () => {
  const response = await request(createApp())
    .get('/version')
    .expect(200);

  assert.equal(response.body.name, 'devsecops-secure-delivery-platform');
  assert.equal(response.body.version, '0.1.0');
});

test('GET /api/status returns service status', async () => {
  const response = await request(createApp())
    .get('/api/status')
    .expect(200);

  assert.equal(response.body.service, 'secure-delivery-api');
  assert.equal(response.body.environment, 'development');
  assert.equal(response.body.status, 'operational');
});

test('unknown routes return 404', async () => {
  const response = await request(createApp())
    .get('/does-not-exist')
    .expect(404);

  assert.deepEqual(response.body, {
    error: 'not_found'
  });
});

test('GET /api/status uses the configured environment', async () => {
  const previousEnvironment = process.env.NODE_ENV;
  process.env.NODE_ENV = 'test';

  try {
    const response = await request(createApp())
      .get('/api/status')
      .expect(200);

    assert.equal(response.body.environment, 'test');
  } finally {
    if (previousEnvironment === undefined) {
      delete process.env.NODE_ENV;
    } else {
      process.env.NODE_ENV = previousEnvironment;
    }
  }
});

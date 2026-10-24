import 'reflect-metadata';
import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { loadConfig } from '../src/config';
import { Database } from '../src/database';
import { PropertiesController, PropertiesService } from '../src/properties';
import { DefaultDenyGuard } from '../src/security';
import { configure, openApi } from '../src/setup';
import { demoProperties } from '../src/fixtures';
const environment = { NODE_ENV: 'test', DEMO_MODE: 'true', MONGODB_URI: 'mongodb://localhost/test', POSTGRES_URL: 'postgresql://localhost/test', REDIS_URL: 'redis://localhost' };
Object.assign(process.env, environment);

test('configuration rejects missing, malformed and unsafe production settings', () => {
  assert.equal(loadConfig(environment).demo, true);
  for (const overrides of [{ DEMO_MODE: undefined }, { DEMO_MODE: 'yes' }, { NODE_ENV: 'production' }, { PORT: 'NaN' }, { PORT: '0' }, { MONGODB_URI: 'https://localhost' }, { POSTGRES_URL: '' }, { REDIS_URL: 'invalid' }]) {
    assert.throws(() => loadConfig({ ...environment, ...overrides }));
  }
  assert.equal(loadConfig({ ...environment, NODE_ENV: 'production', DEMO_MODE: 'false' }).demo, false);
});
@Controller('private-probe')
class PrivateProbe { @Get() get() { return { secret: true }; } }
async function makeApp(database: unknown): Promise<INestApplication> {
  const module = await Test.createTestingModule({ controllers: [PrivateProbe, PropertiesController], providers: [PropertiesService, { provide: Database, useValue: database }, { provide: APP_GUARD, useClass: DefaultDenyGuard }] }).compile();
  const app = module.createNestApplication();
  configure(app);
  await app.init();
  return app;
}

test('HTTP validation, default-deny authorization, contract and database failure', async () => {
  const queries: unknown[] = [];
  const database = { properties: {
    find: (filter: unknown) => { queries.push(filter); return { sort() { return this; }, skip() { return this; }, limit() { return this; }, async toArray() { return demoProperties; } }; },
    countDocuments: async () => 2,
    findOne: async ({ id }: { id: string }) => demoProperties.find(p => p.id === id) ?? null,
  } };
  const app = await makeApp(database);
  try {
    await request(app.getHttpServer()).get('/api/v1/private-probe').expect(401);
    await request(app.getHttpServer()).get('/api/v1/private-probe').set('Authorization', 'Bearer fabricated').expect(401);
    for (const query of ['limit=51', 'page=0', 'page=1.5', 'page=10001', 'q[x]=bad', 'unexpected=true']) {
      await request(app.getHttpServer()).get('/api/v1/properties?' + query).expect(400);
    }
    const page = await request(app.getHttpServer()).get('/api/v1/properties?q=.*').expect(200);
    assert.equal(page.body.mode, 'demo');
    assert.equal(page.body.items[0].synthetic, true);
    const filter = queries[0] as { synthetic: boolean; status: string; $or: Record<string, { $regex: string }>[] };
    assert.equal(filter.synthetic, true);
    assert.equal(filter.status, 'demo_only');
    const pattern = new RegExp(filter.$or[0].name.$regex);
    assert.ok(pattern.test('literal .* text'));
    assert.ok(!pattern.test('Magnolia House'));

  } finally { await app.close(); }
});

test('property details handle missing records and production demo restriction', async () => {
  const app = await makeApp({ properties: { findOne: async () => null } });
  try {
    await request(app.getHttpServer()).get('/api/v1/properties/missing').expect(404);
    await request(app.getHttpServer()).get('/api/v1/properties/bad%24id').expect(404);
    process.env.DEMO_MODE = 'false';
    await request(app.getHttpServer()).get('/api/v1/properties').expect(404);
    const schema = openApi(app);
    assert.ok(schema.paths['/api/v1/properties']);
    assert.ok(schema.components?.schemas?.PropertyResponse);
  } finally { process.env.DEMO_MODE = 'true'; await app.close(); }
});

test('database errors do not leak connection details', async () => {
  const app = await makeApp({ properties: { findOne: async () => { throw new Error('secret-connection-password'); } } });
  try {
    const result = await request(app.getHttpServer()).get('/api/v1/properties/demo-magnolia').expect(503);
    assert.equal(result.body.message, 'Property service unavailable');
    assert.ok(!result.text.includes('password'));
  } finally { await app.close(); }
});

import 'reflect-metadata';
import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { MongoClient } from 'mongodb';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configure } from '../src/setup';

const binary = { version: '8.0.15', ...(process.platform === 'darwin' && execFileSync('/usr/sbin/sysctl', ['-n', 'hw.optional.arm64']).toString().trim() === '1' ? { arch: 'arm64' } : {}) };

test('real MongoDB seed, search, restart persistence and dependency readiness failure', { timeout: 180000 }, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'mogul-integration-'));
  let mongo = await MongoMemoryServer.create({ binary, instance: { dbPath: directory, storageEngine: 'wiredTiger', launchTimeout: 60000 } });
  try {
    process.env.NODE_ENV = 'test';
    process.env.DEMO_MODE = 'true';
    process.env.MONGODB_URI = mongo.getUri('mogul_demo');
    process.env.POSTGRES_URL = 'postgresql://127.0.0.1:1/unavailable';
    process.env.REDIS_URL = 'redis://127.0.0.1:1';
    const seed = () => execFileSync(process.execPath, ['dist/src/seed.js'], { env: process.env });
    seed(); seed();
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = module.createNestApplication();
    configure(app); await app.init();
    try {
      const page = await request(app.getHttpServer()).get('/api/v1/properties').expect(200);
      assert.equal(page.body.total, 2, 'idempotent seed');
      assert.ok(page.body.items.every((p: { synthetic: boolean; _id?: unknown }) => p.synthetic && !p._id));
      const search = await request(app.getHttpServer()).get('/api/v1/properties?q=Dallas&limit=1').expect(200);
      assert.equal(search.body.items[0].id, 'demo-magnolia');
      const literal = await request(app.getHttpServer()).get('/api/v1/properties?q=.*').expect(200);
      assert.equal(literal.body.total, 0, 'search metacharacters are literal');
      await request(app.getHttpServer()).get('/api/v1/properties/demo-magnolia').expect(200);
      await request(app.getHttpServer()).get('/api/v1/properties/unknown').expect(404);
      await request(app.getHttpServer()).post('/api/v1/subscriptions').send({ amount: 100 }).expect(404);
      await request(app.getHttpServer()).get('/api/v1/live').expect(200);
      const readiness = await request(app.getHttpServer()).get('/api/v1/health').expect(503);
      assert.equal(readiness.body.dependencies.mongodb, 'up');
      assert.equal(readiness.body.dependencies.postgresql, 'down');
      assert.equal(readiness.body.dependencies.redis, 'down');
    } finally { await app.close(); }
    await mongo.stop({ doCleanup: false });
    mongo = await MongoMemoryServer.create({ binary, instance: { dbPath: directory, storageEngine: 'wiredTiger', launchTimeout: 60000 } });
    const client = new MongoClient(mongo.getUri('mogul_demo'));
    try {
      assert.equal(await client.db().collection('properties').countDocuments({ synthetic: true }), 2, 'records survive database restart');
      await assert.rejects(client.db().collection('properties').insertOne({ id: 'invalid-record', synthetic: false }));
    } finally { await client.close(); }
  } finally { await mongo.stop(); await rm(directory, { recursive: true, force: true }); }
});

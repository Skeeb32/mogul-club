import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { MongoClient } from 'mongodb';
import { Pool } from 'pg';
import { createClient } from 'redis';
import { loadConfig } from './config';
@Injectable()
export class Database implements OnModuleDestroy {
  private readonly config = loadConfig();
  readonly mongo = new MongoClient(this.config.mongoUri, { serverSelectionTimeoutMS: 1500, connectTimeoutMS: 1500 });
  readonly postgres = new Pool({ connectionString: this.config.postgresUrl, connectionTimeoutMillis: 1500, max: 3 });
  readonly redis = createClient({ url: this.config.redisUrl, socket: { connectTimeout: 1500, reconnectStrategy: false } });
  private redisConnecting?: Promise<unknown>;
  constructor() { this.redis.on('error', () => { /* readiness reports failure without logging credentials */ }); }
  get properties() { return this.mongo.db().collection<import('@mogul/contracts').Property>('properties'); }
  async check() {
    const names = ['mongodb', 'postgresql', 'redis'] as const;
    const results = await Promise.allSettled([
      this.mongo.db().command({ ping: 1 }),
      this.postgres.query('SELECT 1'),
      (async () => {
        if (!this.redis.isOpen) {
          this.redisConnecting ??= this.redis.connect().finally(() => { this.redisConnecting = undefined; });
          await this.redisConnecting;
        }
        return this.redis.ping();
      })(),
    ]);
    return Object.fromEntries(results.map((r, i) => [names[i], r.status === 'fulfilled' ? 'up' : 'down']));
  }
  async onModuleDestroy() {
    if (this.redis.isOpen) this.redis.destroy();
    await Promise.all([this.mongo.close(), this.postgres.end()]);
  }
}

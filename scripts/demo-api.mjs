import { spawn, execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url));
const requireAPI = createRequire(new URL('../apps/api/package.json', import.meta.url));
const { MongoMemoryServer } = requireAPI('mongodb-memory-server');
const binary = { version: '8.0.15', ...(process.platform === 'darwin' && execFileSync('/usr/sbin/sysctl', ['-n', 'hw.optional.arm64']).toString().trim() === '1' ? { arch: 'arm64' } : {}) };
await mkdir(root + '.local-demo/mongodb', { recursive: true });
const mongo = await MongoMemoryServer.create({ binary, instance: { dbPath: root + '.local-demo/mongodb', storageEngine: 'wiredTiger', launchTimeout: 60000 } });
const env = { ...process.env, NODE_ENV: 'development', DEMO_MODE: 'true', PORT: '3001', MONGODB_URI: mongo.getUri('mogul_demo'), POSTGRES_URL: 'postgresql://127.0.0.1:1/unavailable', REDIS_URL: 'redis://127.0.0.1:1' };
let api;
try {
  execFileSync(process.execPath, ['dist/src/seed.js'], { cwd: root + 'apps/api', env, stdio: 'inherit' });
  api = spawn(process.execPath, ['dist/src/main.js'], { cwd: root + 'apps/api', env, stdio: 'inherit' });
  for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => api.kill('SIGTERM'));
  await new Promise((resolve, reject) => { api.once('exit', code => code === 0 || code === null ? resolve() : reject(new Error('API exited with code ' + code))); api.once('error', reject); });
} finally {
  if (api && api.exitCode === null) api.kill('SIGTERM');
  await mongo.stop({ doCleanup: false });
}

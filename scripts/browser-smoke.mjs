import { strict as assert } from 'node:assert';
import { spawn, execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const root = fileURLToPath(new URL('../', import.meta.url));
const requireAPI = createRequire(new URL('../apps/api/package.json', import.meta.url));
const requireAdmin = createRequire(new URL('../apps/admin/package.json', import.meta.url));
const { MongoMemoryServer } = requireAPI('mongodb-memory-server');
const binary = { version: '8.0.15', ...(process.platform === 'darwin' && execFileSync('/usr/sbin/sysctl', ['-n', 'hw.optional.arm64']).toString().trim() === '1' ? { arch: 'arm64' } : {}) };
const apiPort = 43101;
const adminPort = 43100;
const children = [];
let logs = '';
function start(args, cwd, env) {
  const child = spawn(process.execPath, args, { cwd, env, stdio: ['ignore', 'pipe', 'pipe'] });
  children.push(child);
  child.stdout.on('data', data => { logs += data.toString(); });
  child.stderr.on('data', data => { logs += data.toString(); });
  return child;
}
async function ready(url) {
  const deadline = Date.now() + 45000;
  while (Date.now() < deadline) {
    try { const response = await fetch(url); if (response.ok) return; } catch { /* bounded startup retry */ }
    await new Promise(resolve => setTimeout(resolve, 300));
  }
  throw new Error('Service startup timed out');
}
let mongo;
let browser;
await mkdir(root + '.test-results', { recursive: true });
try {
  mongo = await MongoMemoryServer.create({ binary, instance: { launchTimeout: 60000 } });
  const env = { ...process.env, NODE_ENV: 'development', DEMO_MODE: 'true', PORT: String(apiPort), MONGODB_URI: mongo.getUri('mogul_demo'), POSTGRES_URL: 'postgresql://127.0.0.1:1/unavailable', REDIS_URL: 'redis://127.0.0.1:1' };
  execFileSync(process.execPath, ['dist/src/seed.js'], { cwd: root + 'apps/api', env });
  const api = start(['dist/src/main.js'], root + 'apps/api', env);
  await ready(`http://127.0.0.1:${apiPort}/api/v1/properties`);
  start([requireAdmin.resolve('next/dist/bin/next'), 'start', '--port', String(adminPort)], root + 'apps/admin', { ...process.env, NODE_ENV: 'production', API_BASE_URL: `http://127.0.0.1:${apiPort}` });
  await ready(`http://127.0.0.1:${adminPort}`);
  browser = await chromium.launch({ timeout: 20000, ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}) });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(`http://127.0.0.1:${adminPort}`);
  await page.getByRole('rowheader', { name: /Magnolia House/ }).waitFor();
  assert.equal(await page.getByRole('rowheader').count(), 2);
  for (const width of [320, 768, 1024, 1440]) {
    await page.setViewportSize({ width, height: 1000 });
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), `no page overflow at ${width}`);
    const scan = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa']).analyze();
    assert.deepEqual(scan.violations.map(v => ({ id: v.id, nodes: v.nodes.map(n => n.target) })), [], `accessibility at ${width}`);
  }
  await page.screenshot({ path: root + '.test-results/admin-desktop.png', fullPage: true });
  await page.getByLabel('Search by name or location').fill('Dallas');
  await page.getByRole('button', { name: 'Search', exact: true }).click();
  await page.waitForURL(/q=Dallas/);
  await page.getByRole('rowheader', { name: /Magnolia House/ }).waitFor();
  assert.equal(await page.getByRole('rowheader').count(), 1);
  await page.getByLabel('Search by name or location').fill('no-such-property');
  await page.getByRole('button', { name: 'Search', exact: true }).click();
  await page.getByRole('heading', { name: 'No properties found.' }).waitFor();
  await page.getByRole('link', { name: 'Clear search' }).click();
  await page.getByRole('rowheader', { name: /Magnolia House/ }).waitFor();
  await page.emulateMedia({ colorScheme: 'dark' });
  const dark = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa']).analyze();
  assert.deepEqual(dark.violations.map(v => v.id), [], 'dark mode accessibility');
  await page.setViewportSize({ width: 320, height: 900 });
  await page.screenshot({ path: root + '.test-results/admin-mobile.png', fullPage: true });
  api.kill('SIGTERM');
  await new Promise(resolve => api.once('exit', resolve));
  await page.reload();
  await page.getByRole('heading', { name: 'We couldn’t load the property library.' }).waitFor();
  await page.getByRole('link', { name: 'Retry connection' }).waitFor();
  assert.deepEqual(errors, []);
  console.log('PASS: MongoDB → API → admin; search, empty state, API outage, responsive widths 320/768/1024/1440, light/dark axe scans, no browser runtime errors.');
} finally {
  await browser?.close();
  for (const child of children) if (child.exitCode === null) child.kill('SIGTERM');
  if (mongo) await mongo.stop();
  await writeFile(root + '.test-results/browser-services.log', logs);
}

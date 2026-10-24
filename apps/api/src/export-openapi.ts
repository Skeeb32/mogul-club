import 'reflect-metadata';
import { writeFileSync } from 'node:fs';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configure, openApi } from './setup';
async function main() {
  const app = await NestFactory.create(AppModule, { logger: false });
  configure(app);
  writeFileSync('../../packages/api-contracts/openapi.json', JSON.stringify(openApi(app), null, 2) + '\n');
  await app.close();
}
void main();

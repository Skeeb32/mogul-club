import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { loadConfig } from './config';
import { configure, openApi } from './setup';
async function main() {
  const config = loadConfig();
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn', 'log'] });
  configure(app);
  if (config.environment !== 'production') SwaggerModule.setup('api/docs', app, openApi(app));
  await app.listen(config.port, '0.0.0.0');
}
void main().catch(() => { console.error('API startup failed. Validate configuration and dependencies.'); process.exitCode = 1; });

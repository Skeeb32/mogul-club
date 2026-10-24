import { INestApplication, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
export function configure(app: INestApplication) {
  app.setGlobalPrefix('api/v1');
  app.use(helmet());
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.enableShutdownHooks();
}
export function openApi(app: INestApplication) {
  return SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Mogul Club development API').setDescription('Synthetic read-only discovery. No financial execution or authentication implemented.').setVersion('0.1.0').build());
}

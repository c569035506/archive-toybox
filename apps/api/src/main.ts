import express from 'express';
import { join } from 'path';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { loadEnvFiles } from './common/utils/load-env';

async function bootstrap() {
  loadEnvFiles();
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  app.setGlobalPrefix('v1');
  app.use('/audio', express.static(join(process.cwd(), 'public/audio')));
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
}

void bootstrap();

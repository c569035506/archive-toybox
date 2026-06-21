import { Module } from '@nestjs/common';
import { MeritController } from './merit.controller';
import { MeritService } from './merit.service';

@Module({
  controllers: [MeritController],
  providers: [MeritService],
  exports: [MeritService],
})
export class MeritModule {}

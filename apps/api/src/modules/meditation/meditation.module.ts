import { Module } from '@nestjs/common';
import { MeditationController } from './meditation.controller';
import { MeditationService } from './meditation.service';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  controllers: [MeditationController],
  providers: [MeditationService, DevAuthGuard],
  exports: [MeditationService],
})
export class MeditationModule {}

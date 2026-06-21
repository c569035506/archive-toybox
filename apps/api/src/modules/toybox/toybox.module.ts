import { Module } from '@nestjs/common';
import { ToyboxController } from './toybox.controller';
import { ToyboxService } from './toybox.service';
import { MeditationModule } from '../meditation/meditation.module';
import { MeritModule } from '../merit/merit.module';
import { FortuneModule } from '../fortune/fortune.module';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  imports: [MeditationModule, MeritModule, FortuneModule],
  controllers: [ToyboxController],
  providers: [ToyboxService, DevAuthGuard],
})
export class ToyboxModule {}

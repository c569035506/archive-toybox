import { Module } from '@nestjs/common';
import { ArgumentController } from './argument.controller';
import { ArgumentService } from './argument.service';
import { AiModule } from '../../ai/ai.module';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  imports: [AiModule],
  controllers: [ArgumentController],
  providers: [ArgumentService, DevAuthGuard],
})
export class ArgumentModule {}

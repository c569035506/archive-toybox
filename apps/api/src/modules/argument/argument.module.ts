import { Module } from '@nestjs/common';
import { ArgumentController } from './argument.controller';
import { ArgumentService } from './argument.service';
import { ArgumentRateLimiter } from './argument-rate-limiter';
import { AiModule } from '../../ai/ai.module';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  imports: [AiModule],
  controllers: [ArgumentController],
  providers: [ArgumentService, ArgumentRateLimiter, DevAuthGuard],
})
export class ArgumentModule {}

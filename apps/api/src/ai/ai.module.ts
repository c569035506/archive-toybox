import { Module } from '@nestjs/common';
import { OpenAiCompatibleClient } from './openai-compatible.client';
import { AiCompletionService } from './ai-completion.service';

@Module({
  providers: [OpenAiCompatibleClient, AiCompletionService],
  exports: [OpenAiCompatibleClient, AiCompletionService],
})
export class AiModule {}

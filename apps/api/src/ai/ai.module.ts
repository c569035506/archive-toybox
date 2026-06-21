import { Module } from '@nestjs/common';
import { OpenAiCompatibleClient } from './openai-compatible.client';

@Module({
  providers: [OpenAiCompatibleClient],
  exports: [OpenAiCompatibleClient],
})
export class AiModule {}

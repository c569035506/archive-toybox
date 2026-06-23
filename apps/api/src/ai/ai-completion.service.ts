import { Injectable, Logger } from '@nestjs/common';
import { z } from 'zod';
import { OpenAiCompatibleClient } from './openai-compatible.client';
import {
  AiSafetyError,
  AiSchemaError,
  scanStringFields,
} from './output-filter';

type ChatMessage = { role: 'system' | 'user' | 'assistant'; content: string };

export type AiTask =
  | 'practice_opponent'
  | 'practice_review'
  | 'analysis_report'
  | 'character_memory';
export type CompletionOutcome = 'success' | 'repair' | 'fallback';

const TASK_TEMPERATURE: Record<AiTask, number> = {
  practice_opponent: 0.8,
  practice_review: 0.4,
  analysis_report: 0.4,
  character_memory: 0.3,
};

export type ReliableCompletionResult<T> = {
  data: T;
  outcome: CompletionOutcome;
  retryCount: number;
};

@Injectable()
export class AiCompletionService {
  private readonly logger = new Logger(AiCompletionService.name);

  constructor(private readonly llm: OpenAiCompatibleClient) {}

  async completeWithReliability<T>(options: {
    task: AiTask;
    schema: z.ZodType<T>;
    messages: ChatMessage[];
    fallback: () => T;
    context?: { sessionId?: string; userId?: string; characterId?: string };
    maxRetries?: number;
    timeoutMs?: number;
  }): Promise<ReliableCompletionResult<T>> {
    const maxRetries = options.maxRetries ?? 2;
    const timeoutMs = options.timeoutMs ?? 20_000;
    const startedAt = Date.now();
    let retryCount = 0;
    let messages = [...options.messages];
    let lastError = 'unknown';

    if (!this.llm.isConfigured) {
      const data = options.fallback();
      this.logCall({
        task: options.task,
        outcome: 'fallback',
        retryCount,
        latencyMs: Date.now() - startedAt,
        context: options.context,
        reason: 'llm_not_configured',
      });
      return { data, outcome: 'fallback', retryCount };
    }

    while (retryCount <= maxRetries) {
      try {
        const raw = await this.llm.completeJson<unknown>({
          messages,
          temperature: TASK_TEMPERATURE[options.task],
          timeoutMs,
        });
        const parsed = options.schema.safeParse(raw);
        if (!parsed.success) {
          throw new AiSchemaError(parsed.error.message);
        }
        scanStringFields(parsed.data);
        const outcome: CompletionOutcome = retryCount > 0 ? 'repair' : 'success';
        this.logCall({
          task: options.task,
          outcome,
          retryCount,
          latencyMs: Date.now() - startedAt,
          context: options.context,
        });
        return { data: parsed.data, outcome, retryCount };
      } catch (error) {
        lastError =
          error instanceof Error ? error.message : 'AI completion failed';
        if (retryCount >= maxRetries) {
          break;
        }
        retryCount += 1;
        messages = [
          ...messages,
          {
            role: 'user',
            content: `上次输出不合规：${lastError}。请严格按 schema 重新输出完整 JSON。`,
          },
        ];
      }
    }

    const data = options.fallback();
    this.logCall({
      task: options.task,
      outcome: 'fallback',
      retryCount,
      latencyMs: Date.now() - startedAt,
      context: options.context,
      reason: lastError,
    });
    return { data, outcome: 'fallback', retryCount };
  }

  private logCall(input: {
    task: AiTask;
    outcome: CompletionOutcome;
    retryCount: number;
    latencyMs: number;
    context?: { sessionId?: string; userId?: string; characterId?: string };
    reason?: string;
  }) {
    this.logger.log(
      JSON.stringify({
        event: 'ai_completion',
        task: input.task,
        outcome: input.outcome,
        retryCount: input.retryCount,
        latencyMs: input.latencyMs,
        sessionId: input.context?.sessionId,
        userId: input.context?.userId,
        reason: input.reason,
      }),
    );
  }
}

import test from 'node:test';
import assert from 'node:assert/strict';
import { AiCompletionService } from './ai-completion.service';
import { OpenAiCompatibleClient } from './openai-compatible.client';
import { practiceOpponentSchema } from './schemas/practice-opponent.schema';

const originalFetch = globalThis.fetch;

test('completeWithReliability falls back when llm is not configured', async () => {
  const llm = new OpenAiCompatibleClient();
  const service = new AiCompletionService(llm);
  const result = await service.completeWithReliability({
    task: 'practice_opponent',
    schema: practiceOpponentSchema,
    messages: [{ role: 'user', content: 'test' }],
    fallback: () => ({ reply: 'fallback reply' }),
  });

  assert.equal(result.data.reply, 'fallback reply');
  assert.equal(result.outcome, 'fallback');
});

test('completeWithReliability repairs invalid schema then succeeds', async () => {
  let calls = 0;
  globalThis.fetch = (async () => {
    calls += 1;
    const content =
      calls === 1 ? JSON.stringify({}) : JSON.stringify({ reply: '好的，我们谈谈。' });
    return new Response(
      JSON.stringify({
        choices: [{ message: { content } }],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  }) as typeof fetch;

  const previousKey = process.env.OPENAI_API_KEY;
  process.env.OPENAI_API_KEY = 'test-key';

  try {
    const llm = new OpenAiCompatibleClient();
    const service = new AiCompletionService(llm);
    const result = await service.completeWithReliability({
      task: 'practice_opponent',
      schema: practiceOpponentSchema,
      messages: [{ role: 'user', content: 'test' }],
      fallback: () => ({ reply: 'fallback reply' }),
      maxRetries: 1,
    });

    assert.equal(result.data.reply, '好的，我们谈谈。');
    assert.equal(result.outcome, 'repair');
    assert.equal(calls, 2);
  } finally {
    process.env.OPENAI_API_KEY = previousKey;
    globalThis.fetch = originalFetch;
  }
});

test('completeWithReliability falls back after retries exhausted', async () => {
  globalThis.fetch = (async () =>
    new Response(
      JSON.stringify({
        choices: [{ message: { content: JSON.stringify({}) } }],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )) as typeof fetch;

  const previousKey = process.env.OPENAI_API_KEY;
  process.env.OPENAI_API_KEY = 'test-key';

  try {
    const llm = new OpenAiCompatibleClient();
    const service = new AiCompletionService(llm);
    const result = await service.completeWithReliability({
      task: 'practice_opponent',
      schema: practiceOpponentSchema,
      messages: [{ role: 'user', content: 'test' }],
      fallback: () => ({ reply: 'fallback reply' }),
      maxRetries: 1,
    });

    assert.equal(result.data.reply, 'fallback reply');
    assert.equal(result.outcome, 'fallback');
  } finally {
    process.env.OPENAI_API_KEY = previousKey;
    globalThis.fetch = originalFetch;
  }
});

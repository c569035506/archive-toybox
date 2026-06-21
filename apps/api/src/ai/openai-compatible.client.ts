import { Injectable } from '@nestjs/common';
import { assertSafeText } from './output-filter';
import { fillTemplate, loadPrompt } from './prompt-utils';

type ChatMessage = { role: 'system' | 'user' | 'assistant'; content: string };

@Injectable()
export class OpenAiCompatibleClient {
  private get config() {
    return {
      apiKey: process.env.OPENAI_API_KEY ?? '',
      baseUrl: process.env.OPENAI_BASE_URL ?? 'https://api.openai.com/v1',
      model: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
    };
  }

  get isConfigured() {
    return Boolean(this.config.apiKey);
  }

  async completeJson<T>(messages: ChatMessage[]): Promise<T> {
    if (!this.isConfigured) {
      throw new Error('OPENAI_API_KEY is not configured.');
    }

    const response = await fetch(`${this.config.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.config.model,
        messages,
        response_format: { type: 'json_object' },
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`LLM request failed: ${text}`);
    }

    const payload = (await response.json()) as {
      choices: Array<{ message: { content: string } }>;
    };

    const content = payload.choices[0]?.message?.content ?? '{}';
    assertSafeText(content);
    return JSON.parse(content) as T;
  }

  buildSystemPrompt(extra: string) {
    return `${loadPrompt('base-system.prompt.md')}\n\n${extra}`;
  }

  buildPrompt(templateName: string, vars: Record<string, string>) {
    return fillTemplate(loadPrompt(templateName), vars);
  }
}

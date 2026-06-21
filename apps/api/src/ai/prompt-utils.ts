import { readFileSync } from 'fs';
import { join } from 'path';

const PROMPT_DIR = join(process.cwd(), 'src/ai/prompts');

export function loadPrompt(name: string): string {
  return readFileSync(join(PROMPT_DIR, name), 'utf8');
}

export function fillTemplate(template: string, vars: Record<string, string>): string {
  return Object.entries(vars).reduce(
    (result, [key, value]) => result.replaceAll(`{{${key}}}`, value),
    template,
  );
}

export function mapReviewTitle(scores: Record<string, number>): string {
  const avg =
    Object.values(scores).reduce((sum, value) => sum + value, 0) /
    Object.values(scores).length;

  if (avg >= 4.5) return '边界守夜人';
  if (avg >= 4) return '冷静对话者';
  if (avg >= 3.5) return '表达进阶中';
  if (avg >= 3) return '情绪觉察者';
  return '练手新手';
}

export const PRACTICE_MESSAGE_MAX_LENGTH = 500;
export const PRACTICE_PROFILE_DESC_MAX_LENGTH = 500;
export const ANALYSIS_CHAT_TEXT_MAX_LENGTH = 8000;
export const PRACTICE_HISTORY_LIMIT = 12;

export function profileDescForPrompt(value: string | undefined, emptyHint: string): string {
  const trimmed = (value ?? '').trim();
  return trimmed || emptyHint;
}

export function trimPracticeHistory<T>(history: T[], limit = PRACTICE_HISTORY_LIMIT): T[] {
  if (history.length <= limit) {
    return history;
  }
  return history.slice(history.length - limit);
}

export function formatConversation(
  history: Array<{ role: string; content: string }>,
): string {
  return history
    .map((item) => `${item.role === 'user' ? '用户' : '对方'}：${item.content}`)
    .join('\n');
}

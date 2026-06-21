const BLOCKED_PATTERNS = [
  /去死/,
  /弄死/,
  /报复/,
  /PUA/i,
  /改命/,
  /消灾/,
  /保证发财/,
];

export function assertSafeText(text: string) {
  for (const pattern of BLOCKED_PATTERNS) {
    if (pattern.test(text)) {
      throw new Error('Generated content failed safety filter.');
    }
  }
}

export function sanitizeReply(text: string): string {
  assertSafeText(text);
  return text.trim();
}

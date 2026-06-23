const BLOCKED_PATTERNS = [
  /去死/,
  /弄死/,
  /报复/,
  /PUA/i,
  /改命/,
  /消灾/,
  /保证发财/,
  /自杀/,
  /自残/,
  /废物/,
  /贱人/,
  /去跳楼/,
];

function extraPatterns(): RegExp[] {
  const raw = process.env.SAFETY_EXTRA_PATTERNS ?? '';
  if (!raw.trim()) {
    return [];
  }
  return raw
    .split('|')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => new RegExp(item, 'i'));
}

function allPatterns(): RegExp[] {
  return [...BLOCKED_PATTERNS, ...extraPatterns()];
}

export class AiSafetyError extends Error {
  readonly code = 'AI_SAFETY_BLOCKED' as const;

  constructor(message = 'Generated content failed safety filter.') {
    super(message);
    this.name = 'AiSafetyError';
  }
}

export class AiSchemaError extends Error {
  readonly code = 'AI_SCHEMA_INVALID' as const;

  constructor(message: string) {
    super(message);
    this.name = 'AiSchemaError';
  }
}

export function assertSafeText(text: string) {
  for (const pattern of allPatterns()) {
    if (pattern.test(text)) {
      throw new AiSafetyError();
    }
  }
}

export function sanitizeReply(text: string): string {
  assertSafeText(text);
  return text.trim();
}

export function scanStringFields(value: unknown, path = 'root'): void {
  if (typeof value === 'string') {
    try {
      assertSafeText(value);
    } catch {
      throw new AiSafetyError(`Unsafe content at ${path}`);
    }
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item, index) => scanStringFields(item, `${path}[${index}]`));
    return;
  }

  if (value && typeof value === 'object') {
    for (const [key, nested] of Object.entries(value)) {
      scanStringFields(nested, `${path}.${key}`);
    }
  }
}

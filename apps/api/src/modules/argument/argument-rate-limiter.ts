import { Injectable, HttpException, HttpStatus } from '@nestjs/common';

@Injectable()
export class ArgumentRateLimiter {
  private readonly buckets = new Map<string, number[]>();
  private readonly limit = 30;
  private readonly windowMs = 60_000;

  check(userId: string) {
    const now = Date.now();
    const recent = (this.buckets.get(userId) ?? []).filter(
      (timestamp) => now - timestamp < this.windowMs,
    );
    if (recent.length >= this.limit) {
      throw new HttpException(
        'Too many practice messages. Please wait a moment.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    recent.push(now);
    this.buckets.set(userId, recent);
  }
}

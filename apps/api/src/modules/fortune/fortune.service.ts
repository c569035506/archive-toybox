import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { getDateKey } from '../../common/utils/date-key';

@Injectable()
export class FortuneService {
  constructor(private readonly prisma: PrismaService) {}

  async tapLuckyCat(userId: string, clientRequestId: string) {
    const dateKey = getDateKey();
    const cacheKey = `fortune:${clientRequestId}`;

    const existingTxn = await this.prisma.meritTransaction.findFirst({
      where: {
        userId,
        clientRequestId: cacheKey,
      },
    });

    const statsBefore = await this.getOrCreateDailyStats(userId, dateKey);

    if (existingTxn) {
      return {
        today_fortune: statsBefore.todayFortune,
        duplicate: true,
      };
    }

    const stats = await this.prisma.userDailyStats.upsert({
      where: { userId_dateKey: { userId, dateKey } },
      update: { todayFortune: { increment: 1 } },
      create: { userId, dateKey, todayFortune: 1 },
    });

    await this.prisma.meritTransaction.create({
      data: {
        userId,
        type: 'WOODEN_FISH_TAP',
        amount: 0,
        balanceAfter: 0,
        clientRequestId: cacheKey,
        metadata: { kind: 'lucky_cat_tap' },
      },
    });

    return {
      today_fortune: stats.todayFortune,
      duplicate: false,
    };
  }

  async getSummary(userId: string) {
    const dateKey = getDateKey();
    const stats = await this.getOrCreateDailyStats(userId, dateKey);
    return { today_fortune: stats.todayFortune };
  }

  private async getOrCreateDailyStats(userId: string, dateKey: string) {
    return this.prisma.userDailyStats.upsert({
      where: { userId_dateKey: { userId, dateKey } },
      update: {},
      create: { userId, dateKey },
    });
  }
}

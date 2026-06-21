import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MeritTxnType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { getDateKey } from '../../common/utils/date-key';
import { normalizeFriendPair } from '../../common/utils/date-key';

@Injectable()
export class MeritService {
  constructor(private readonly prisma: PrismaService) {}

  async tapWoodenFish(userId: string, clientRequestId: string) {
    const dateKey = getDateKey();

    const existing = await this.prisma.meritTransaction.findUnique({
      where: { userId_clientRequestId: { userId, clientRequestId } },
    });

    if (existing) {
      const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
      const stats = await this.getOrCreateDailyStats(userId, dateKey);
      return {
        today_merit: stats.todayMerit,
        total_merit: user.totalMerit,
        duplicate: true,
      };
    }

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: { totalMerit: { increment: 1 } },
      });

      const stats = await tx.userDailyStats.upsert({
        where: { userId_dateKey: { userId, dateKey } },
        update: { todayMerit: { increment: 1 } },
        create: { userId, dateKey, todayMerit: 1 },
      });

      await tx.meritTransaction.create({
        data: {
          userId,
          type: MeritTxnType.WOODEN_FISH_TAP,
          amount: 1,
          balanceAfter: user.totalMerit,
          clientRequestId,
        },
      });

      return {
        today_merit: stats.todayMerit,
        total_merit: user.totalMerit,
        duplicate: false,
      };
    });
  }

  async getSummary(userId: string) {
    const dateKey = getDateKey();
    const [user, stats] = await Promise.all([
      this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      this.getOrCreateDailyStats(userId, dateKey),
    ]);

    return {
      today_merit: stats.todayMerit,
      total_merit: user.totalMerit,
    };
  }

  async transferMerit(
    fromUserId: string,
    toUserId: string,
    amount: number,
    clientRequestId: string,
    message?: string,
  ) {
    if (fromUserId === toUserId) {
      throw new BadRequestException('Cannot transfer merit to yourself.');
    }

    const pair = normalizeFriendPair(fromUserId, toUserId);
    const friendship = await this.prisma.friendship.findUnique({
      where: { userAId_userBId: pair },
    });

    if (!friendship) {
      throw new BadRequestException('You can only transfer merit to friends.');
    }

    const existing = await this.prisma.meritTransaction.findUnique({
      where: {
        userId_clientRequestId: { userId: fromUserId, clientRequestId },
      },
    });

    if (existing) {
      const sender = await this.prisma.user.findUniqueOrThrow({
        where: { id: fromUserId },
      });
      return {
        from_balance: sender.totalMerit,
        duplicate: true,
      };
    }

    return this.prisma.$transaction(async (tx) => {
      const sender = await tx.user.findUnique({ where: { id: fromUserId } });
      const receiver = await tx.user.findUnique({ where: { id: toUserId } });

      if (!sender || !receiver) {
        throw new NotFoundException('User not found.');
      }

      if (sender.totalMerit < amount) {
        throw new BadRequestException('Insufficient merit balance.');
      }

      const updatedSender = await tx.user.update({
        where: { id: fromUserId },
        data: { totalMerit: { decrement: amount } },
      });

      const updatedReceiver = await tx.user.update({
        where: { id: toUserId },
        data: { totalMerit: { increment: amount } },
      });

      await tx.meritTransaction.create({
        data: {
          userId: fromUserId,
          type: MeritTxnType.MERIT_TRANSFER_OUT,
          amount: -amount,
          balanceAfter: updatedSender.totalMerit,
          counterpartyId: toUserId,
          clientRequestId,
          metadata: message ? { message } : undefined,
        },
      });

      await tx.meritTransaction.create({
        data: {
          userId: toUserId,
          type: MeritTxnType.MERIT_TRANSFER_IN,
          amount,
          balanceAfter: updatedReceiver.totalMerit,
          counterpartyId: fromUserId,
          clientRequestId: `${clientRequestId}:in`,
          metadata: message ? { message } : undefined,
        },
      });

      return {
        from_balance: updatedSender.totalMerit,
        to_balance: updatedReceiver.totalMerit,
        duplicate: false,
      };
    });
  }

  private async getOrCreateDailyStats(userId: string, dateKey: string) {
    return this.prisma.userDailyStats.upsert({
      where: { userId_dateKey: { userId, dateKey } },
      update: {},
      create: { userId, dateKey },
    });
  }
}

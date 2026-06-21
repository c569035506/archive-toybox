import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { getDateKey } from '../../common/utils/date-key';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async register(email: string, nickname: string) {
    const shortId = `TOY${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
    const user = await this.prisma.user.create({
      data: { email, nickname, shortId },
    });
    return this.toAuthResponse(user);
  }

  async login(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new NotFoundException('User not found.');
    }
    return this.toAuthResponse(user);
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        shortId: true,
        email: true,
        nickname: true,
        avatarUrl: true,
        totalMerit: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    const stats = await this.prisma.userDailyStats.findUnique({
      where: {
        userId_dateKey: { userId, dateKey: getDateKey() },
      },
    });

    return {
      ...user,
      today_merit: stats?.todayMerit ?? 0,
      today_fortune: stats?.todayFortune ?? 0,
      meditation_minutes: Math.floor((stats?.meditationSec ?? 0) / 60),
    };
  }

  private toAuthResponse(user: {
    id: string;
    shortId: string;
    email: string;
    nickname: string;
  }) {
    return {
      user: {
        id: user.id,
        short_id: user.shortId,
        email: user.email,
        nickname: user.nickname,
      },
      token: `user:${user.id}`,
    };
  }
}

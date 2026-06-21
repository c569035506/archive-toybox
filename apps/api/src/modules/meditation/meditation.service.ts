import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

type FinishSessionInput = {
  durationSec: number;
  moodDelta: Record<string, number>;
};

@Injectable()
export class MeditationService {
  constructor(private readonly prisma: PrismaService) {}

  async getTracks() {
    const tracks = await this.prisma.meditationTrack.findMany({
      where: { isActive: true },
      orderBy: [{ category: 'asc' }, { createdAt: 'asc' }],
    });

    return {
      tracks: tracks.map((track) => ({
        id: track.id,
        title: track.title,
        category: track.category,
        audio_url: track.audioUrl,
        duration_sec: track.durationSec,
      })),
    };
  }

  async createSession(userId: string, trackId: string) {
    const track = await this.prisma.meditationTrack.findFirst({
      where: { id: trackId, isActive: true },
    });

    if (!track) {
      throw new NotFoundException('Meditation track not found.');
    }

    const session = await this.prisma.meditationSession.create({
      data: {
        userId,
        trackId,
      },
    });

    return {
      session_id: session.id,
      track: {
        id: track.id,
        title: track.title,
        category: track.category,
        audio_url: track.audioUrl,
        duration_sec: track.durationSec,
      },
    };
  }

  async updateProgress(userId: string, sessionId: string, durationSec: number) {
    await this.assertSessionOwner(userId, sessionId);

    const session = await this.prisma.meditationSession.update({
      where: { id: sessionId },
      data: {
        durationSec,
      },
    });

    return {
      session_id: session.id,
      duration_sec: session.durationSec,
    };
  }

  async finishSession(
    userId: string,
    sessionId: string,
    input: FinishSessionInput,
  ) {
    await this.assertSessionOwner(userId, sessionId);

    const session = await this.prisma.meditationSession.update({
      where: { id: sessionId },
      data: {
        durationSec: input.durationSec,
        moodDelta: input.moodDelta,
      },
      include: {
        track: true,
      },
    });

    return {
      session_id: session.id,
      duration_sec: session.durationSec,
      mood_delta: session.moodDelta,
      track: {
        id: session.track.id,
        title: session.track.title,
        category: session.track.category,
      },
    };
  }

  async getSummary(userId: string) {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const [today, totalCount, lastSession] = await Promise.all([
      this.prisma.meditationSession.aggregate({
        where: {
          userId,
          createdAt: {
            gte: startOfToday,
          },
        },
        _sum: {
          durationSec: true,
        },
      }),
      this.prisma.meditationSession.count({
        where: { userId },
      }),
      this.prisma.meditationSession.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        include: { track: true },
      }),
    ]);

    return {
      today_minutes: Math.floor((today._sum.durationSec ?? 0) / 60),
      total_sessions: totalCount,
      last_track: lastSession
        ? {
            id: lastSession.track.id,
            title: lastSession.track.title,
            category: lastSession.track.category,
          }
        : null,
    };
  }

  async getToyboxSummary(userId: string) {
    const summary = await this.getSummary(userId);
    return {
      card_title: '静心弹幕',
      description: '播放一段静心音乐，看情绪慢慢飘走。',
      action_label: '开始',
      status_text: `今日已静心 ${summary.today_minutes} 分钟`,
    };
  }

  private async assertSessionOwner(userId: string, sessionId: string) {
    const session = await this.prisma.meditationSession.findFirst({
      where: {
        id: sessionId,
        userId,
      },
      select: {
        id: true,
      },
    });

    if (!session) {
      throw new NotFoundException('Meditation session not found.');
    }
  }
}

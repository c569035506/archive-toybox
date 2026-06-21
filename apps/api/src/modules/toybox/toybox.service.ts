import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MeditationService } from '../meditation/meditation.service';
import { MeritService } from '../merit/merit.service';
import { FortuneService } from '../fortune/fortune.service';

@Injectable()
export class ToyboxService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly meditationService: MeditationService,
    private readonly meritService: MeritService,
    private readonly fortuneService: FortuneService,
  ) {}

  async getHome(userId: string) {
    const [merit, fortune, meditationCard, lastReview] = await Promise.all([
      this.meritService.getSummary(userId),
      this.fortuneService.getSummary(userId),
      this.meditationService.getToyboxSummary(userId),
      this.prisma.argumentPracticeReview.findFirst({
        where: { session: { userId } },
        orderBy: { createdAt: 'desc' },
        select: { title: true },
      }),
    ]);

    return {
      cards: [
        {
          key: 'wooden_fish',
          title: '电子木鱼',
          description: '轻轻敲一下，给今天一点确认感。',
          action_label: '敲一下',
          status_text: `今日功德 ${merit.today_merit}`,
          total_merit: merit.total_merit,
        },
        {
          key: 'lucky_cat',
          title: '招财猫',
          description: '摸摸猫爪，让心情轻一点。',
          action_label: '摸一下',
          status_text: `今日招财值 ${fortune.today_fortune}`,
        },
        {
          key: 'good_argument',
          title: '好好吵架',
          description: '模拟一场对话，或复盘一次真实争吵。',
          action_label: '开始',
          status_text: lastReview
            ? `最近复盘：${lastReview.title}`
            : '最近复盘：暂无',
        },
        {
          key: 'meditation',
          title: meditationCard.card_title,
          description: meditationCard.description,
          action_label: meditationCard.action_label,
          status_text: meditationCard.status_text,
        },
      ],
    };
  }
}

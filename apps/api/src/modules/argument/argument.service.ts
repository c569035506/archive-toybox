import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ArgumentSessionStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { OpenAiCompatibleClient } from '../../ai/openai-compatible.client';
import { mapReviewTitle, fillTemplate, loadPrompt } from '../../ai/prompt-utils';
import { sanitizeReply } from '../../ai/output-filter';

type PracticeSetup = {
  opponent_label: string;
  relationship: string;
  what_happened: string;
  practice_goal: string;
  opponent_style: string;
};

type ReviewPayload = {
  scores: {
    emotional_stability: number;
    boundary_expression: number;
    logic_clarity: number;
    anti_frame_control: number;
    relationship_preservation: number;
    effective_response: number;
  };
  title: string;
  summary: string;
  highlights: string[];
  suggestions: string[];
  best_quote: string;
};

type AnalysisReport = {
  one_liner: string;
  root_cause: string;
  escalation_points: string;
  expression_patterns: string;
  user_strengths: string;
  user_improvements: string;
  better_phrasing: string;
  next_reply: string;
  final_advice: string;
};

@Injectable()
export class ArgumentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ai: OpenAiCompatibleClient,
  ) {}

  async createPracticeSession(userId: string, setup: PracticeSetup) {
    const session = await this.prisma.argumentPracticeSession.create({
      data: {
        userId,
        opponentLabel: setup.opponent_label,
        relationship: setup.relationship,
        whatHappened: setup.what_happened,
        practiceGoal: setup.practice_goal,
        opponentStyle: setup.opponent_style,
      },
    });

    const opening = this.mockOpponentReply(setup);
    await this.prisma.argumentPracticeMessage.create({
      data: { sessionId: session.id, role: 'assistant', content: opening },
    });

    return { session_id: session.id, opening_message: opening };
  }

  async getPracticeSession(userId: string, sessionId: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    const messages = await this.prisma.argumentPracticeMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });

    return {
      session: this.toSessionPayload(session),
      messages: messages.map((item) => ({
        id: item.id,
        role: item.role,
        content: item.content,
        created_at: item.createdAt,
      })),
    };
  }

  async sendPracticeMessage(userId: string, sessionId: string, content: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (session.status !== ArgumentSessionStatus.ACTIVE) {
      throw new BadRequestException('Session is already finished.');
    }

    await this.prisma.argumentPracticeMessage.create({
      data: { sessionId, role: 'user', content },
    });

    const history = await this.prisma.argumentPracticeMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });

    const reply = await this.generateOpponentReply(session, history, content);
    const assistant = await this.prisma.argumentPracticeMessage.create({
      data: { sessionId, role: 'assistant', content: reply },
    });

    return {
      message: {
        id: assistant.id,
        role: assistant.role,
        content: assistant.content,
        created_at: assistant.createdAt,
      },
    };
  }

  async finishPracticeSession(userId: string, sessionId: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (session.review) {
      return this.formatReview(session.review);
    }

    const history = await this.prisma.argumentPracticeMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });

    const reviewData = await this.generateReview(session, history);

    const review = await this.prisma.$transaction(async (tx) => {
      await tx.argumentPracticeSession.update({
        where: { id: sessionId },
        data: { status: ArgumentSessionStatus.FINISHED, finishedAt: new Date() },
      });

      return tx.argumentPracticeReview.create({
        data: {
          sessionId,
          emotionalStability: reviewData.scores.emotional_stability,
          boundaryExpression: reviewData.scores.boundary_expression,
          logicClarity: reviewData.scores.logic_clarity,
          antiFrameControl: reviewData.scores.anti_frame_control,
          relationshipPreservation: reviewData.scores.relationship_preservation,
          effectiveResponse: reviewData.scores.effective_response,
          title: reviewData.title,
          summary: reviewData.summary,
          posterPayload: {
            title: reviewData.title,
            subtitle: reviewData.summary,
            best_quote: reviewData.best_quote,
            scores: reviewData.scores,
          },
        },
      });
    });

    return this.formatReview(review);
  }

  async getPracticeReview(userId: string, sessionId: string) {
    const session = await this.getOwnedSession(userId, sessionId);
    if (!session.review) {
      throw new NotFoundException('Review not found.');
    }
    return this.formatReview(session.review);
  }

  async createAnalysis(
    userId: string,
    input: {
      chat_text: string;
      self_side: string;
      relationship: string;
      analysis_goal: string;
    },
  ) {
    const report = await this.generateAnalysisReport(input);
    const record = await this.prisma.argumentAnalysisRecord.create({
      data: {
        userId,
        chatTextRedacted: input.chat_text.slice(0, 500),
        selfSide: input.self_side,
        relationship: input.relationship,
        analysisGoal: input.analysis_goal,
        report,
      },
    });

    return { id: record.id, report };
  }

  async listAnalysis(userId: string) {
    const records = await this.prisma.argumentAnalysisRecord.findMany({
      where: { userId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        relationship: true,
        analysisGoal: true,
        report: true,
        createdAt: true,
      },
    });

    return {
      items: records.map((item) => ({
        id: item.id,
        relationship: item.relationship,
        analysis_goal: item.analysisGoal,
        one_liner: (item.report as AnalysisReport).one_liner,
        created_at: item.createdAt,
      })),
    };
  }

  async getAnalysis(userId: string, id: string) {
    const record = await this.prisma.argumentAnalysisRecord.findFirst({
      where: { id, userId, deletedAt: null },
    });
    if (!record) {
      throw new NotFoundException('Analysis record not found.');
    }
    return {
      id: record.id,
      self_side: record.selfSide,
      relationship: record.relationship,
      analysis_goal: record.analysisGoal,
      report: record.report,
      created_at: record.createdAt,
    };
  }

  async deleteAnalysis(userId: string, id: string) {
    const record = await this.prisma.argumentAnalysisRecord.findFirst({
      where: { id, userId, deletedAt: null },
    });
    if (!record) {
      throw new NotFoundException('Analysis record not found.');
    }

    await this.prisma.argumentAnalysisRecord.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { deleted: true };
  }

  private async getOwnedSession(userId: string, sessionId: string) {
    const session = await this.prisma.argumentPracticeSession.findFirst({
      where: { id: sessionId, userId },
      include: { review: true },
    });
    if (!session) {
      throw new NotFoundException('Practice session not found.');
    }
    return session;
  }

  private toSessionPayload(session: {
    id: string;
    status: ArgumentSessionStatus;
    opponentLabel: string;
    relationship: string;
    whatHappened: string;
    practiceGoal: string;
    opponentStyle: string;
  }) {
    return {
      id: session.id,
      status: session.status,
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      opponent_style: session.opponentStyle,
    };
  }

  private formatReview(review: {
    emotionalStability: number;
    boundaryExpression: number;
    logicClarity: number;
    antiFrameControl: number;
    relationshipPreservation: number;
    effectiveResponse: number;
    title: string;
    summary: string;
    posterPayload: unknown;
  }) {
    return {
      scores: {
        emotional_stability: review.emotionalStability,
        boundary_expression: review.boundaryExpression,
        logic_clarity: review.logicClarity,
        anti_frame_control: review.antiFrameControl,
        relationship_preservation: review.relationshipPreservation,
        effective_response: review.effectiveResponse,
      },
      title: review.title,
      summary: review.summary,
      poster: review.posterPayload,
    };
  }

  private mockOpponentReply(setup: PracticeSetup) {
    return sanitizeReply(
      `我们先别绕弯子，关于「${setup.what_happened}」，你到底想让我怎么做？`,
    );
  }

  private async generateOpponentReply(
    session: {
      opponentLabel: string;
      relationship: string;
      whatHappened: string;
      practiceGoal: string;
      opponentStyle: string;
    },
    history: Array<{ role: string; content: string }>,
    latestUserMessage: string,
  ) {
    if (!this.ai.isConfigured) {
      return sanitizeReply(
        `（${session.opponentStyle}）我听到你说「${latestUserMessage.slice(0, 40)}」，但这件事没那么简单。`,
      );
    }

    const conversation = history
      .map((item) => `${item.role === 'user' ? '用户' : '对方'}：${item.content}`)
      .join('\n');

    const prompt = fillTemplate(loadPrompt('practice-opponent.prompt.md'), {
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      opponent_style: session.opponentStyle,
    });

    const result = await this.ai.completeJson<{ reply: string }>([
      { role: 'system', content: this.ai.buildSystemPrompt(prompt) },
      { role: 'user', content: conversation },
    ]);

    return sanitizeReply(result.reply);
  }

  private async generateReview(
    session: {
      opponentLabel: string;
      relationship: string;
      whatHappened: string;
      practiceGoal: string;
    },
    history: Array<{ role: string; content: string }>,
  ): Promise<ReviewPayload> {
    const conversation = history
      .map((item) => `${item.role === 'user' ? '用户' : '对方'}：${item.content}`)
      .join('\n');

    if (!this.ai.isConfigured) {
      const scores = {
        emotional_stability: 4,
        boundary_expression: 4,
        logic_clarity: 3,
        anti_frame_control: 3,
        relationship_preservation: 4,
        effective_response: 3,
      };
      return {
        scores,
        title: mapReviewTitle(scores),
        summary: '你多数时候保持了冷静，也开始尝试表达边界。',
        highlights: ['没有急于道歉', '尝试把问题说清楚'],
        suggestions: ['可以在表达边界时增加一句对对方需求的承接'],
        best_quote: history.find((item) => item.role === 'user')?.content ?? '我已经在努力了。',
      };
    }

    const prompt = fillTemplate(loadPrompt('practice-review.prompt.md'), {
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      conversation,
    });

    const result = await this.ai.completeJson<ReviewPayload>([
      { role: 'system', content: this.ai.buildSystemPrompt(prompt) },
      { role: 'user', content: '请生成复盘 JSON。' },
    ]);

    result.title = result.title || mapReviewTitle(result.scores);
    return result;
  }

  private async generateAnalysisReport(input: {
    chat_text: string;
    self_side: string;
    relationship: string;
    analysis_goal: string;
  }): Promise<AnalysisReport> {
    if (!this.ai.isConfigured) {
      return {
        one_liner: '这次争执表面在争态度，本质是需求和边界没有说清楚。',
        root_cause: '双方对同一件事的期待不同，但没有先对齐事实。',
        escalation_points: '第 3 轮开始出现泛化表达，让对方进入防御状态。',
        expression_patterns: '一方倾向指责，另一方倾向回避。',
        user_strengths: '你有尝试把话题拉回具体事件。',
        user_improvements: '可以减少「你总是」这类绝对化表达。',
        better_phrasing: '我刚才有点急，我想重新把这件事说清楚。',
        next_reply: '我愿意沟通，但我们先确认一下各自能做什么。',
        final_advice: '先对齐事实，再表达感受和请求，避免连续追问。',
      };
    }

    const prompt = fillTemplate(loadPrompt('analysis-report.prompt.md'), {
      chat_text: input.chat_text,
      self_side: input.self_side,
      relationship: input.relationship,
      analysis_goal: input.analysis_goal,
    });

    return this.ai.completeJson<AnalysisReport>([
      { role: 'system', content: this.ai.buildSystemPrompt(prompt) },
      { role: 'user', content: '请生成分析报告 JSON。' },
    ]);
  }
}

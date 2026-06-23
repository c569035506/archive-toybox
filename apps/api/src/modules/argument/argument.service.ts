import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ArgumentSessionStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { OpenAiCompatibleClient } from '../../ai/openai-compatible.client';
import { AiCompletionService } from '../../ai/ai-completion.service';
import { mapReviewTitle, fillTemplate, loadPrompt } from '../../ai/prompt-utils';
import { sanitizeReply } from '../../ai/output-filter';
import {
  fallbackAnalysisReport,
  fallbackCharacterMemory,
  fallbackOpponentOpening,
  fallbackOpponentReply,
  fallbackPracticeReview,
  type PracticeSetup,
  type PracticeSetupInput,
} from '../../ai/argument-fallbacks';
import { characterMemorySchema } from '../../ai/schemas/character-memory.schema';
import { practiceOpponentSchema } from '../../ai/schemas/practice-opponent.schema';
import { practiceReviewSchema } from '../../ai/schemas/practice-review.schema';
import { analysisReportSchema } from '../../ai/schemas/analysis-report.schema';
import type { AnalysisReportOutput } from '../../ai/schemas/analysis-report.schema';
import type { PracticeReviewOutput } from '../../ai/schemas/practice-review.schema';
import { ArgumentRateLimiter } from './argument-rate-limiter';
import {
  formatConversation,
  profileDescForPrompt,
  trimPracticeHistory,
} from './argument.utils';
import {
  voiceAgeLabel,
  voiceGenderLabel,
  type PracticeVoiceAge,
  type PracticeVoiceGender,
} from './argument-voice.utils';

type ReviewPosterPayload = {
  title: string;
  subtitle: string;
  best_quote: string;
  highlights: string[];
  suggestions: string[];
  scores: PracticeReviewOutput['scores'];
};

@Injectable()
export class ArgumentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly llm: OpenAiCompatibleClient,
    private readonly aiCompletion: AiCompletionService,
    private readonly rateLimiter: ArgumentRateLimiter,
  ) {}

  async listPracticeCharacters(userId: string) {
    const characters = await this.prisma.argumentPracticeCharacter.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      include: { _count: { select: { sessions: true } } },
    });

    return {
      characters: characters.map((item) => this.toCharacterPayload(item)),
    };
  }

  async createPracticeCharacter(
    userId: string,
    input: {
      name: string;
      relationship: string;
      opponent_style: string;
      identity_desc?: string;
      personality_desc?: string;
      voice_gender?: string;
      voice_age?: string;
    },
  ) {
    const voiceGender = (input.voice_gender ?? 'female') as PracticeVoiceGender;
    const voiceAge = (input.voice_age ?? 'middle') as PracticeVoiceAge;

    const character = await this.prisma.argumentPracticeCharacter.create({
      data: {
        userId,
        name: input.name.trim(),
        relationship: input.relationship.trim(),
        opponentStyle: input.opponent_style.trim(),
        identityDesc: input.identity_desc?.trim() ?? '',
        personalityDesc: input.personality_desc?.trim() ?? '',
        voiceGender,
        voiceAge,
      },
      include: { _count: { select: { sessions: true } } },
    });

    return this.toCharacterPayload(character);
  }

  async updatePracticeCharacter(
    userId: string,
    characterId: string,
    input: {
      name: string;
      relationship: string;
      opponent_style: string;
      identity_desc?: string;
      personality_desc?: string;
      voice_gender?: string;
      voice_age?: string;
    },
  ) {
    await this.getOwnedCharacter(userId, characterId);
    const voiceGender = (input.voice_gender ?? 'female') as PracticeVoiceGender;
    const voiceAge = (input.voice_age ?? 'middle') as PracticeVoiceAge;

    const character = await this.prisma.argumentPracticeCharacter.update({
      where: { id: characterId },
      data: {
        name: input.name.trim(),
        relationship: input.relationship.trim(),
        opponentStyle: input.opponent_style.trim(),
        identityDesc: input.identity_desc?.trim() ?? '',
        personalityDesc: input.personality_desc?.trim() ?? '',
        voiceGender,
        voiceAge,
      },
      include: { _count: { select: { sessions: true } } },
    });

    return this.toCharacterPayload(character);
  }

  async deletePracticeCharacter(userId: string, characterId: string) {
    await this.getOwnedCharacter(userId, characterId);
    await this.prisma.argumentPracticeCharacter.delete({
      where: { id: characterId },
    });
    return { deleted: true };
  }

  async getPracticeCharacter(userId: string, characterId: string) {
    const character = await this.getOwnedCharacter(userId, characterId);
    const withCount = await this.prisma.argumentPracticeCharacter.findUniqueOrThrow({
      where: { id: character.id },
      include: { _count: { select: { sessions: true } } },
    });
    return this.toCharacterPayload(withCount);
  }

  async createPracticeSession(userId: string, setup: PracticeSetupInput) {
    const resolved = await this.resolvePracticeSetup(userId, setup);
    const voiceGender = resolved.opponent_voice_gender as PracticeVoiceGender;
    const voiceAge = resolved.opponent_voice_age as PracticeVoiceAge;

    const session = await this.prisma.argumentPracticeSession.create({
      data: {
        userId,
        characterId: resolved.character_id,
        opponentLabel: resolved.opponent_label,
        relationship: resolved.relationship,
        whatHappened: resolved.what_happened,
        practiceGoal: resolved.practice_goal,
        opponentStyle: resolved.opponent_style,
        opponentIdentityDesc: resolved.opponent_identity_desc?.trim() ?? '',
        opponentPersonalityDesc: resolved.opponent_personality_desc?.trim() ?? '',
        opponentVoiceGender: voiceGender,
        opponentVoiceAge: voiceAge,
      },
    });

    const opening = await this.generateOpponentOpening(session.id, resolved);
    await this.prisma.argumentPracticeMessage.create({
      data: { sessionId: session.id, role: 'assistant', content: opening },
    });

    return {
      session_id: session.id,
      character_id: resolved.character_id ?? null,
      opening_message: opening,
      opponent_voice_gender: voiceGender,
      opponent_voice_age: voiceAge,
    };
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
    this.rateLimiter.check(userId);

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

    const reply = await this.generateOpponentReply(
      session,
      history,
      content,
      userId,
    );
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

    const reviewData = await this.generateReview(session, history, userId);

    const review = await this.prisma.$transaction(async (tx) => {
      await tx.argumentPracticeSession.update({
        where: { id: sessionId },
        data: { status: ArgumentSessionStatus.FINISHED, finishedAt: new Date() },
      });

      const posterPayload: ReviewPosterPayload = {
        title: reviewData.title,
        subtitle: reviewData.summary,
        best_quote: reviewData.best_quote,
        highlights: reviewData.highlights,
        suggestions: reviewData.suggestions,
        scores: reviewData.scores,
      };

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
          posterPayload,
        },
      });
    });

    if (session.characterId) {
      await this.refreshCharacterMemory(
        session.characterId,
        session.whatHappened,
        history,
        reviewData.summary,
      );
    }

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
    const report = await this.generateAnalysisReport(input, userId);
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
        one_liner: (item.report as AnalysisReportOutput).one_liner,
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
      include: { review: true, character: true },
    });
    if (!session) {
      throw new NotFoundException('Practice session not found.');
    }
    return session;
  }

  private async getOwnedCharacter(userId: string, characterId: string) {
    const character = await this.prisma.argumentPracticeCharacter.findFirst({
      where: { id: characterId, userId },
    });
    if (!character) {
      throw new NotFoundException('Practice character not found.');
    }
    return character;
  }

  private async resolvePracticeSetup(
    userId: string,
    setup: PracticeSetupInput,
  ): Promise<PracticeSetup> {
    if (setup.character_id) {
      const character = await this.getOwnedCharacter(userId, setup.character_id);
      return {
        character_id: character.id,
        opponent_label: character.name,
        relationship: setup.relationship?.trim() || character.relationship,
        what_happened: setup.what_happened,
        practice_goal: setup.practice_goal,
        opponent_style: character.opponentStyle,
        opponent_identity_desc: character.identityDesc,
        opponent_personality_desc: character.personalityDesc,
        opponent_voice_gender: character.voiceGender,
        opponent_voice_age: character.voiceAge,
        character_memory: character.memorySummary,
      };
    }

    if (!setup.opponent_label?.trim() || !setup.opponent_style?.trim()) {
      throw new BadRequestException(
        'opponent_label and opponent_style are required when character_id is not provided.',
      );
    }

    if (!setup.relationship?.trim()) {
      throw new BadRequestException('relationship is required when character_id is not provided.');
    }

    return {
      ...setup,
      opponent_label: setup.opponent_label!.trim(),
      opponent_style: setup.opponent_style!.trim(),
      relationship: setup.relationship!.trim(),
      opponent_voice_gender: setup.opponent_voice_gender ?? 'female',
      opponent_voice_age: setup.opponent_voice_age ?? 'middle',
      character_memory: '',
    };
  }

  private toCharacterPayload(character: {
    id: string;
    name: string;
    relationship: string;
    opponentStyle: string;
    identityDesc: string;
    personalityDesc: string;
    voiceGender: string;
    voiceAge: string;
    memorySummary: string;
    createdAt: Date;
    updatedAt: Date;
    _count?: { sessions: number };
  }) {
    return {
      id: character.id,
      name: character.name,
      relationship: character.relationship,
      opponent_style: character.opponentStyle,
      identity_desc: character.identityDesc,
      personality_desc: character.personalityDesc,
      voice_gender: character.voiceGender,
      voice_age: character.voiceAge,
      memory_summary: character.memorySummary,
      session_count: character._count?.sessions ?? 0,
      created_at: character.createdAt,
      updated_at: character.updatedAt,
    };
  }

  private toSessionPayload(session: {
    id: string;
    status: ArgumentSessionStatus;
    characterId: string | null;
    opponentLabel: string;
    relationship: string;
    whatHappened: string;
    practiceGoal: string;
    opponentStyle: string;
    opponentIdentityDesc: string;
    opponentPersonalityDesc: string;
    opponentVoiceGender: string;
    opponentVoiceAge: string;
  }) {
    return {
      id: session.id,
      status: session.status,
      character_id: session.characterId,
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      opponent_style: session.opponentStyle,
      opponent_identity_desc: session.opponentIdentityDesc,
      opponent_personality_desc: session.opponentPersonalityDesc,
      opponent_voice_gender: session.opponentVoiceGender,
      opponent_voice_age: session.opponentVoiceAge,
    };
  }

  private characterMemoryForPrompt(memory?: string) {
    return profileDescForPrompt(
      memory,
      '（这是第一次和该角色练习，暂无上一次记忆）',
    );
  }

  private opponentProfilePromptFields(source: {
    opponentIdentityDesc?: string;
    opponentPersonalityDesc?: string;
  }) {
    return {
      opponent_identity_desc: profileDescForPrompt(
        source.opponentIdentityDesc,
        '（未补充，请结合对方身份简称与关系合理推断）',
      ),
      opponent_personality_desc: profileDescForPrompt(
        source.opponentPersonalityDesc,
        '（未补充，请结合说话风格标签合理推断）',
      ),
    };
  }

  private opponentProfilePromptFieldsFromSetup(setup: PracticeSetup) {
    return this.opponentProfilePromptFields({
      opponentIdentityDesc: setup.opponent_identity_desc,
      opponentPersonalityDesc: setup.opponent_personality_desc,
    });
  }

  private opponentVoicePromptFields(session: {
    opponentVoiceGender: string;
    opponentVoiceAge: string;
  }) {
    return {
      opponent_voice_gender: voiceGenderLabel(session.opponentVoiceGender),
      opponent_voice_age: voiceAgeLabel(session.opponentVoiceAge),
    };
  }

  private setupVoicePromptFields(setup: PracticeSetup) {
    return {
      opponent_voice_gender: voiceGenderLabel(setup.opponent_voice_gender ?? 'female'),
      opponent_voice_age: voiceAgeLabel(setup.opponent_voice_age ?? 'middle'),
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
    const poster = review.posterPayload as Partial<ReviewPosterPayload>;
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
      highlights: poster.highlights ?? [],
      suggestions: poster.suggestions ?? [],
      best_quote: poster.best_quote ?? '',
      poster: review.posterPayload,
    };
  }

  private buildOpponentPrompt(
    session: {
      opponentLabel: string;
      relationship: string;
      whatHappened: string;
      practiceGoal: string;
      opponentStyle: string;
      opponentIdentityDesc: string;
      opponentPersonalityDesc: string;
      opponentVoiceGender: string;
      opponentVoiceAge: string;
    },
    characterMemory?: string,
  ) {
    return fillTemplate(loadPrompt('practice-opponent.prompt.md'), {
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      opponent_style: session.opponentStyle,
      ...this.opponentProfilePromptFields(session),
      character_memory: this.characterMemoryForPrompt(characterMemory),
      ...this.opponentVoicePromptFields(session),
    });
  }

  private async generateOpponentOpening(sessionId: string, setup: PracticeSetup) {
    const prompt = fillTemplate(loadPrompt('practice-opponent.prompt.md'), {
      opponent_label: setup.opponent_label,
      relationship: setup.relationship,
      what_happened: setup.what_happened,
      practice_goal: setup.practice_goal,
      opponent_style: setup.opponent_style,
      ...this.opponentProfilePromptFieldsFromSetup(setup),
      character_memory: this.characterMemoryForPrompt(setup.character_memory),
      ...this.setupVoicePromptFields(setup),
    });

    const { data } = await this.aiCompletion.completeWithReliability({
      task: 'practice_opponent',
      schema: practiceOpponentSchema,
      messages: [
        { role: 'system', content: this.llm.buildSystemPrompt(prompt) },
        {
          role: 'user',
          content: '练习刚开始，用户尚未发言。请以对方身份给出第一句开场白。',
        },
      ],
      fallback: () => ({ reply: fallbackOpponentOpening(setup) }),
      context: { sessionId },
    });

    return sanitizeReply(data.reply);
  }

  private async generateOpponentReply(
    session: {
      id: string;
      opponentLabel: string;
      relationship: string;
      whatHappened: string;
      practiceGoal: string;
      opponentStyle: string;
      opponentIdentityDesc: string;
      opponentPersonalityDesc: string;
      opponentVoiceGender: string;
      opponentVoiceAge: string;
      character?: { memorySummary: string } | null;
    },
    history: Array<{ role: string; content: string }>,
    latestUserMessage: string,
    userId: string,
  ) {
    const trimmed = trimPracticeHistory(history);
    const conversation = formatConversation(trimmed);
    const prompt = this.buildOpponentPrompt(
      session,
      session.character?.memorySummary,
    );

    const { data } = await this.aiCompletion.completeWithReliability({
      task: 'practice_opponent',
      schema: practiceOpponentSchema,
      messages: [
        { role: 'system', content: this.llm.buildSystemPrompt(prompt) },
        { role: 'user', content: conversation || `用户：${latestUserMessage}` },
      ],
      fallback: () => ({
        reply: fallbackOpponentReply(session.opponentStyle, latestUserMessage),
      }),
      context: { sessionId: session.id, userId },
    });

    return sanitizeReply(data.reply);
  }

  private async generateReview(
    session: {
      id: string;
      opponentLabel: string;
      relationship: string;
      whatHappened: string;
      practiceGoal: string;
    },
    history: Array<{ role: string; content: string }>,
    userId: string,
  ): Promise<PracticeReviewOutput> {
    const conversation = formatConversation(trimPracticeHistory(history));

    const prompt = fillTemplate(loadPrompt('practice-review.prompt.md'), {
      opponent_label: session.opponentLabel,
      relationship: session.relationship,
      what_happened: session.whatHappened,
      practice_goal: session.practiceGoal,
      conversation,
    });

    const { data } = await this.aiCompletion.completeWithReliability({
      task: 'practice_review',
      schema: practiceReviewSchema,
      messages: [
        { role: 'system', content: this.llm.buildSystemPrompt(prompt) },
        { role: 'user', content: '请生成复盘 JSON。' },
      ],
      fallback: () => fallbackPracticeReview(history),
      context: { sessionId: session.id, userId },
    });

    return {
      ...data,
      title: data.title || mapReviewTitle(data.scores),
    };
  }

  private async generateAnalysisReport(
    input: {
      chat_text: string;
      self_side: string;
      relationship: string;
      analysis_goal: string;
    },
    userId: string,
  ): Promise<AnalysisReportOutput> {
    const prompt = fillTemplate(loadPrompt('analysis-report.prompt.md'), {
      chat_text: input.chat_text,
      self_side: input.self_side,
      relationship: input.relationship,
      analysis_goal: input.analysis_goal,
    });

    const { data } = await this.aiCompletion.completeWithReliability({
      task: 'analysis_report',
      schema: analysisReportSchema,
      messages: [
        { role: 'system', content: this.llm.buildSystemPrompt(prompt) },
        { role: 'user', content: '请生成分析报告 JSON。' },
      ],
      fallback: () => fallbackAnalysisReport(),
      context: { userId },
    });

    return data;
  }

  private async refreshCharacterMemory(
    characterId: string,
    whatHappened: string,
    history: Array<{ role: string; content: string }>,
    reviewSummary: string,
  ) {
    const character = await this.prisma.argumentPracticeCharacter.findUnique({
      where: { id: characterId },
    });
    if (!character) {
      return;
    }

    const conversation = formatConversation(trimPracticeHistory(history));
    const prompt = fillTemplate(loadPrompt('character-memory.prompt.md'), {
      character_name: character.name,
      relationship: character.relationship,
      opponent_style: character.opponentStyle,
      opponent_identity_desc: profileDescForPrompt(
        character.identityDesc,
        '（未补充）',
      ),
      opponent_personality_desc: profileDescForPrompt(
        character.personalityDesc,
        '（未补充）',
      ),
      existing_memory: character.memorySummary.trim() || '（暂无）',
      conversation: `场景：${whatHappened}\n${conversation}`,
    });

    const { data } = await this.aiCompletion.completeWithReliability({
      task: 'character_memory',
      schema: characterMemorySchema,
      messages: [
        { role: 'system', content: this.llm.buildSystemPrompt(prompt) },
        { role: 'user', content: '请更新角色记忆 JSON。' },
      ],
      fallback: () => ({
        memory_summary: fallbackCharacterMemory(character.memorySummary, reviewSummary),
      }),
      context: { characterId },
    });

    await this.prisma.argumentPracticeCharacter.update({
      where: { id: characterId },
      data: { memorySummary: data.memory_summary.trim() },
    });
  }
}

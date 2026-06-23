import { mapReviewTitle } from './prompt-utils';
import { sanitizeReply } from './output-filter';
import type { AnalysisReportOutput } from './schemas/analysis-report.schema';
import type { PracticeReviewOutput } from './schemas/practice-review.schema';

export type PracticeSetupInput = {
  character_id?: string;
  opponent_label?: string;
  relationship?: string;
  what_happened: string;
  practice_goal: string;
  opponent_style?: string;
  opponent_identity_desc?: string;
  opponent_personality_desc?: string;
  opponent_voice_gender?: string;
  opponent_voice_age?: string;
  character_memory?: string;
};

export type PracticeSetup = PracticeSetupInput & {
  opponent_label: string;
  relationship: string;
  opponent_style: string;
};

export function fallbackOpponentOpening(setup: PracticeSetup): string {
  return sanitizeReply(
    `我们先别绕弯子，关于「${setup.what_happened}」，你到底想让我怎么做？`,
  );
}

export function fallbackOpponentReply(
  opponentStyle: string,
  latestUserMessage: string,
): string {
  return sanitizeReply(
    `（${opponentStyle}）我听到你说「${latestUserMessage.slice(0, 40)}」，但这件事没那么简单。`,
  );
}

export function fallbackPracticeReview(
  history: Array<{ role: string; content: string }>,
): PracticeReviewOutput {
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
    best_quote:
      history.find((item) => item.role === 'user')?.content ?? '我已经在努力了。',
  };
}

export function fallbackCharacterMemory(
  existingMemory: string,
  latestSessionSummary: string,
): string {
  const base = existingMemory.trim();
  const addition = latestSessionSummary.trim();
  if (!base) {
    return addition || '该角色在过往练习中表现出与设定一致的性格与说话方式。';
  }
  if (!addition) {
    return base;
  }
  return `${base}\n- ${addition}`.slice(0, 1500);
}

export function fallbackAnalysisReport(): AnalysisReportOutput {
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

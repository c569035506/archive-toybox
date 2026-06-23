import test from 'node:test';
import assert from 'node:assert/strict';
import { practiceOpponentSchema } from './practice-opponent.schema';
import { practiceReviewSchema } from './practice-review.schema';
import { analysisReportSchema } from './analysis-report.schema';

test('practiceOpponentSchema accepts valid reply', () => {
  const parsed = practiceOpponentSchema.parse({ reply: '你这话什么意思？' });
  assert.equal(parsed.reply, '你这话什么意思？');
});

test('practiceOpponentSchema rejects empty reply', () => {
  assert.throws(() => practiceOpponentSchema.parse({ reply: '' }));
});

test('practiceReviewSchema validates score bounds', () => {
  assert.throws(() =>
    practiceReviewSchema.parse({
      scores: {
        emotional_stability: 6,
        boundary_expression: 4,
        logic_clarity: 4,
        anti_frame_control: 4,
        relationship_preservation: 4,
        effective_response: 4,
      },
      title: '测试称号',
      summary: '摘要',
      highlights: ['亮点'],
      suggestions: ['建议'],
      best_quote: '金句',
    }),
  );
});

test('analysisReportSchema requires all report fields', () => {
  assert.throws(() =>
    analysisReportSchema.parse({
      one_liner: '一句话',
    }),
  );
});

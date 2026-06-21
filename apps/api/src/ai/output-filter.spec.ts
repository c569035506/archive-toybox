import test from 'node:test';
import assert from 'node:assert/strict';
import { assertSafeText } from '../ai/output-filter';
import { mapReviewTitle } from '../ai/prompt-utils';

test('assertSafeText blocks violent content', () => {
  assert.throws(() => assertSafeText('我们去报复他'));
});

test('mapReviewTitle returns tiered titles', () => {
  assert.equal(
    mapReviewTitle({
      emotional_stability: 5,
      boundary_expression: 5,
      logic_clarity: 5,
      anti_frame_control: 5,
      relationship_preservation: 5,
      effective_response: 5,
    }),
    '边界守夜人',
  );
});

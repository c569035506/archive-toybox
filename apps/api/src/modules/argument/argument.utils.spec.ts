import test from 'node:test';
import assert from 'node:assert/strict';
import { trimPracticeHistory } from './argument.utils';

test('trimPracticeHistory keeps the latest items only', () => {
  const history = Array.from({ length: 15 }, (_, index) => index + 1);
  assert.deepEqual(trimPracticeHistory(history, 12), [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
});

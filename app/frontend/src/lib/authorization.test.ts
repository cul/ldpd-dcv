import { test, it, expect } from 'vitest';
import { sum } from './authorization';

test('add 1 + 2 to 3', () => {
  expect(sum(1, 2)).toBe(3)
})
import { z } from 'zod';

const scoreField = z.number().int().min(1).max(5);

export const practiceReviewSchema = z.object({
  scores: z.object({
    emotional_stability: scoreField,
    boundary_expression: scoreField,
    logic_clarity: scoreField,
    anti_frame_control: scoreField,
    relationship_preservation: scoreField,
    effective_response: scoreField,
  }),
  title: z.string().trim().min(1).max(16),
  summary: z.string().trim().min(1).max(500),
  highlights: z.array(z.string().trim().min(1).max(200)).min(1).max(3),
  suggestions: z.array(z.string().trim().min(1).max(200)).min(1).max(3),
  best_quote: z.string().trim().min(1).max(300),
});

export type PracticeReviewOutput = z.infer<typeof practiceReviewSchema>;

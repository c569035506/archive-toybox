import { z } from 'zod';

export const practiceOpponentSchema = z.object({
  reply: z.string().trim().min(1).max(300),
});

export type PracticeOpponentOutput = z.infer<typeof practiceOpponentSchema>;

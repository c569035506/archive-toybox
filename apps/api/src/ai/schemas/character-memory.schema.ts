import { z } from 'zod';

export const characterMemorySchema = z.object({
  memory_summary: z.string().min(1).max(1500),
});

export type CharacterMemoryOutput = z.infer<typeof characterMemorySchema>;

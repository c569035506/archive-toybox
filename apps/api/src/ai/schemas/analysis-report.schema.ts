import { z } from 'zod';

const reportField = z.string().trim().min(1).max(500);

export const analysisReportSchema = z.object({
  one_liner: reportField,
  root_cause: reportField,
  escalation_points: reportField,
  expression_patterns: reportField,
  user_strengths: reportField,
  user_improvements: reportField,
  better_phrasing: reportField,
  next_reply: reportField,
  final_advice: reportField,
});

export type AnalysisReportOutput = z.infer<typeof analysisReportSchema>;

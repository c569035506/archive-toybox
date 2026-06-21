export type MeritTapResponse = {
  today_merit: number;
  total_merit: number;
  duplicate: boolean;
};

export type AnalysisReport = {
  one_liner: string;
  root_cause: string;
  escalation_points: string;
  expression_patterns: string;
  user_strengths: string;
  user_improvements: string;
  better_phrasing: string;
  next_reply: string;
  final_advice: string;
};

/** API 契约类型（snake_case，与 NestJS 响应一致） */

export type MeritTapResponse = {
  today_merit: number;
  total_merit: number;
  duplicate: boolean;
};

export type FortuneTapResponse = {
  today_fortune: number;
  duplicate: boolean;
};

export type MeritSummary = {
  today_merit: number;
  total_merit: number;
};

export type FortuneSummary = {
  today_fortune: number;
};

export type MeritTransferResponse = {
  from_balance: number;
  to_balance?: number;
  duplicate: boolean;
};

export type UserProfile = {
  id: string;
  short_id: string;
  email: string;
  nickname: string;
  avatar_url: string | null;
  total_merit: number;
  today_merit: number;
  today_fortune: number;
  meditation_minutes: number;
};

export type ToyboxCard = {
  key: string;
  title: string;
  description: string;
  action_label: string;
  status_text: string;
  total_merit?: number;
};

export type ToyboxHomeResponse = {
  cards: ToyboxCard[];
};

export type MeditationTrack = {
  id: string;
  title: string;
  category: string;
  audio_url: string;
  duration_sec: number;
};

export type MeditationSessionCreated = {
  session_id: string;
  track: MeditationTrack;
};

export type MeditationProgressResponse = {
  session_id: string;
  duration_sec: number;
};

export type MeditationFinishResponse = {
  session_id: string;
  duration_sec: number;
  mood_delta: Record<string, number>;
  track: {
    id: string;
    title: string;
    category: string;
  };
};

export type PracticeScores = {
  emotional_stability: number;
  boundary_expression: number;
  logic_clarity: number;
  anti_frame_control: number;
  relationship_preservation: number;
  effective_response: number;
};

export type PracticeReview = {
  scores: PracticeScores;
  title: string;
  summary: string;
  highlights: string[];
  suggestions: string[];
  best_quote: string;
  poster: unknown;
};

export type PracticeMessage = {
  id: string;
  role: string;
  content: string;
  created_at?: string;
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

export type AnalysisListItem = {
  id: string;
  relationship: string;
  analysis_goal: string;
  one_liner: string;
  created_at?: string;
};

export type FriendUser = {
  id: string;
  short_id: string;
  nickname: string;
  avatar_url?: string | null;
  total_merit?: number;
};

export type FriendRequestItem = {
  id: string;
  from_user?: FriendUser;
  to_user?: FriendUser;
  created_at?: string;
};

export type FriendRequestsResponse = {
  incoming: FriendRequestItem[];
  outgoing: FriendRequestItem[];
};

export type LegalDocument = {
  version: string;
  title: string;
  content: string;
};

export type PrivacyAckResponse = {
  id: string;
  doc_type: string;
  version: string;
};

export type IdempotentTapRequest = {
  client_request_id: string;
  tapped_at: string;
};

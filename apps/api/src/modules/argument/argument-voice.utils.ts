export const PRACTICE_VOICE_GENDERS = ['male', 'female'] as const;
export const PRACTICE_VOICE_AGES = ['child', 'youth', 'middle', 'elderly'] as const;

export type PracticeVoiceGender = (typeof PRACTICE_VOICE_GENDERS)[number];
export type PracticeVoiceAge = (typeof PRACTICE_VOICE_AGES)[number];

const VOICE_GENDER_LABELS: Record<PracticeVoiceGender, string> = {
  male: '男声',
  female: '女声',
};

const VOICE_AGE_LABELS: Record<PracticeVoiceAge, string> = {
  child: '幼年',
  youth: '青年',
  middle: '中年',
  elderly: '老年',
};

export function voiceGenderLabel(gender: string): string {
  return VOICE_GENDER_LABELS[gender as PracticeVoiceGender] ?? gender;
}

export function voiceAgeLabel(age: string): string {
  return VOICE_AGE_LABELS[age as PracticeVoiceAge] ?? age;
}

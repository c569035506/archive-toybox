import { IsInt, IsObject, Min } from 'class-validator';

export class FinishMeditationSessionDto {
  @IsInt()
  @Min(0)
  duration_sec!: number;

  @IsObject()
  mood_delta!: Record<string, number>;
}

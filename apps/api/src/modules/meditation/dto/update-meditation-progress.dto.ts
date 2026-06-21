import { IsInt, Min } from 'class-validator';

export class UpdateMeditationProgressDto {
  @IsInt()
  @Min(0)
  duration_sec!: number;
}

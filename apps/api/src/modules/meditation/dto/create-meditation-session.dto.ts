import { IsString } from 'class-validator';

export class CreateMeditationSessionDto {
  @IsString()
  track_id!: string;
}

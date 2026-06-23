import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { ArgumentService } from './argument.service';
import {
  ANALYSIS_CHAT_TEXT_MAX_LENGTH,
  PRACTICE_MESSAGE_MAX_LENGTH,
  PRACTICE_PROFILE_DESC_MAX_LENGTH,
} from './argument.utils';
import {
  PRACTICE_VOICE_AGES,
  PRACTICE_VOICE_GENDERS,
} from './argument-voice.utils';

class CreatePracticeCharacterDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsString()
  @MinLength(1)
  relationship!: string;

  @IsString()
  @MinLength(1)
  opponent_style!: string;

  @IsOptional()
  @IsString()
  @MaxLength(PRACTICE_PROFILE_DESC_MAX_LENGTH)
  identity_desc?: string;

  @IsOptional()
  @IsString()
  @MaxLength(PRACTICE_PROFILE_DESC_MAX_LENGTH)
  personality_desc?: string;

  @IsOptional()
  @IsIn([...PRACTICE_VOICE_GENDERS])
  voice_gender?: string;

  @IsOptional()
  @IsIn([...PRACTICE_VOICE_AGES])
  voice_age?: string;
}

class UpdatePracticeCharacterDto extends CreatePracticeCharacterDto {}

class CreatePracticeSessionDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  character_id?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  opponent_label?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  relationship?: string;

  @IsString()
  @MinLength(1)
  what_happened!: string;

  @IsString()
  @MinLength(1)
  practice_goal!: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  opponent_style?: string;

  @IsOptional()
  @IsString()
  @MaxLength(PRACTICE_PROFILE_DESC_MAX_LENGTH)
  opponent_identity_desc?: string;

  @IsOptional()
  @IsString()
  @MaxLength(PRACTICE_PROFILE_DESC_MAX_LENGTH)
  opponent_personality_desc?: string;

  @IsOptional()
  @IsIn([...PRACTICE_VOICE_GENDERS])
  opponent_voice_gender?: string;

  @IsOptional()
  @IsIn([...PRACTICE_VOICE_AGES])
  opponent_voice_age?: string;
}

class SendPracticeMessageDto {
  @IsString()
  @MinLength(1)
  @MaxLength(PRACTICE_MESSAGE_MAX_LENGTH)
  content!: string;
}

class CreateAnalysisDto {
  @IsString()
  @MinLength(10)
  @MaxLength(ANALYSIS_CHAT_TEXT_MAX_LENGTH)
  chat_text!: string;

  @IsString()
  self_side!: string;

  @IsString()
  relationship!: string;

  @IsString()
  analysis_goal!: string;

  @IsBoolean()
  privacy_acknowledged!: boolean;
}

@Controller('argument')
@UseGuards(DevAuthGuard)
export class ArgumentController {
  constructor(private readonly argumentService: ArgumentService) {}

  @Get('practice/characters')
  listCharacters(@CurrentUser() user: CurrentUserPayload) {
    return this.argumentService.listPracticeCharacters(user.id);
  }

  @Post('practice/characters')
  createCharacter(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreatePracticeCharacterDto,
  ) {
    return this.argumentService.createPracticeCharacter(user.id, dto);
  }

  @Get('practice/characters/:id')
  getCharacter(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.argumentService.getPracticeCharacter(user.id, id);
  }

  @Patch('practice/characters/:id')
  updateCharacter(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
    @Body() dto: UpdatePracticeCharacterDto,
  ) {
    return this.argumentService.updatePracticeCharacter(user.id, id, dto);
  }

  @Delete('practice/characters/:id')
  deleteCharacter(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.argumentService.deletePracticeCharacter(user.id, id);
  }

  @Post('practice/sessions')
  createPractice(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreatePracticeSessionDto,
  ) {
    return this.argumentService.createPracticeSession(user.id, dto);
  }

  @Get('practice/sessions/:id')
  getPractice(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.argumentService.getPracticeSession(user.id, id);
  }

  @Post('practice/sessions/:id/messages')
  sendPracticeMessage(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
    @Body() dto: SendPracticeMessageDto,
  ) {
    return this.argumentService.sendPracticeMessage(user.id, id, dto.content);
  }

  @Post('practice/sessions/:id/finish')
  finishPractice(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.argumentService.finishPracticeSession(user.id, id);
  }

  @Get('practice/sessions/:id/review')
  getReview(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.argumentService.getPracticeReview(user.id, id);
  }

  @Post('analysis')
  createAnalysis(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateAnalysisDto,
  ) {
    if (!dto.privacy_acknowledged) {
      throw new BadRequestException('Privacy acknowledgement is required.');
    }
    return this.argumentService.createAnalysis(user.id, dto);
  }

  @Get('analysis')
  listAnalysis(@CurrentUser() user: CurrentUserPayload) {
    return this.argumentService.listAnalysis(user.id);
  }

  @Get('analysis/:id')
  getAnalysis(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.argumentService.getAnalysis(user.id, id);
  }

  @Delete('analysis/:id')
  deleteAnalysis(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.argumentService.deleteAnalysis(user.id, id);
  }
}

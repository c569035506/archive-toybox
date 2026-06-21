import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsString, MinLength } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { ArgumentService } from './argument.service';

class CreatePracticeSessionDto {
  @IsString()
  @MinLength(1)
  opponent_label!: string;

  @IsString()
  @MinLength(1)
  relationship!: string;

  @IsString()
  @MinLength(1)
  what_happened!: string;

  @IsString()
  @MinLength(1)
  practice_goal!: string;

  @IsString()
  @MinLength(1)
  opponent_style!: string;
}

class SendPracticeMessageDto {
  @IsString()
  @MinLength(1)
  content!: string;
}

class CreateAnalysisDto {
  @IsString()
  @MinLength(10)
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

import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { CreateMeditationSessionDto } from './dto/create-meditation-session.dto';
import { FinishMeditationSessionDto } from './dto/finish-meditation-session.dto';
import { UpdateMeditationProgressDto } from './dto/update-meditation-progress.dto';
import { MeditationService } from './meditation.service';

@Controller('meditation')
@UseGuards(DevAuthGuard)
export class MeditationController {
  constructor(private readonly meditationService: MeditationService) {}

  @Get('tracks')
  getTracks() {
    return this.meditationService.getTracks();
  }

  @Post('sessions')
  createSession(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: CreateMeditationSessionDto,
  ) {
    return this.meditationService.createSession(user.id, dto.track_id);
  }

  @Patch('sessions/:id/progress')
  updateProgress(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') sessionId: string,
    @Body() dto: UpdateMeditationProgressDto,
  ) {
    return this.meditationService.updateProgress(
      user.id,
      sessionId,
      dto.duration_sec,
    );
  }

  @Post('sessions/:id/finish')
  finishSession(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') sessionId: string,
    @Body() dto: FinishMeditationSessionDto,
  ) {
    return this.meditationService.finishSession(user.id, sessionId, {
      durationSec: dto.duration_sec,
      moodDelta: dto.mood_delta,
    });
  }

  @Get('summary')
  getSummary(@CurrentUser() user: CurrentUserPayload) {
    return this.meditationService.getSummary(user.id);
  }
}

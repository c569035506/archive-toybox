import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsISO8601, IsUUID } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { FortuneService } from './fortune.service';

class LuckyCatTapDto {
  @IsUUID()
  client_request_id!: string;

  @IsISO8601()
  tapped_at!: string;
}

@Controller('fortune')
@UseGuards(DevAuthGuard)
export class FortuneController {
  constructor(private readonly fortuneService: FortuneService) {}

  @Post('lucky-cat/tap')
  tap(@CurrentUser() user: CurrentUserPayload, @Body() dto: LuckyCatTapDto) {
    return this.fortuneService.tapLuckyCat(user.id, dto.client_request_id);
  }

  @Get('summary')
  summary(@CurrentUser() user: CurrentUserPayload) {
    return this.fortuneService.getSummary(user.id);
  }
}

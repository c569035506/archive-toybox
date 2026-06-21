import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { ToyboxService } from './toybox.service';

@Controller('toybox')
@UseGuards(DevAuthGuard)
export class ToyboxController {
  constructor(private readonly toyboxService: ToyboxService) {}

  @Get('home')
  getHome(@CurrentUser() user: CurrentUserPayload) {
    return this.toyboxService.getHome(user.id);
  }
}

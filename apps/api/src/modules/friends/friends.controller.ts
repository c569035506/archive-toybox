import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsString, IsUUID, MinLength } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { FriendsService } from './friends.service';

class SendFriendRequestDto {
  @IsString()
  @MinLength(1)
  to_user_id!: string;
}

@Controller('friends')
@UseGuards(DevAuthGuard)
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get('search')
  search(@Query('short_id') shortId: string) {
    if (!shortId?.trim()) {
      throw new BadRequestException('short_id is required.');
    }
    return this.friendsService.searchByShortId(shortId.trim());
  }

  @Post('requests')
  sendRequest(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: SendFriendRequestDto,
  ) {
    return this.friendsService.sendRequest(user.id, dto.to_user_id);
  }

  @Get('requests')
  listRequests(@CurrentUser() user: CurrentUserPayload) {
    return this.friendsService.listRequests(user.id);
  }

  @Post('requests/:id/accept')
  accept(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.friendsService.acceptRequest(user.id, id);
  }

  @Post('requests/:id/reject')
  reject(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.friendsService.rejectRequest(user.id, id);
  }

  @Get()
  listFriends(@CurrentUser() user: CurrentUserPayload) {
    return this.friendsService.listFriends(user.id);
  }
}

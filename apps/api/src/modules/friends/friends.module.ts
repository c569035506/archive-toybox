import { Module } from '@nestjs/common';
import { FriendsController } from './friends.controller';
import { FriendsService } from './friends.service';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  controllers: [FriendsController],
  providers: [FriendsService, DevAuthGuard],
  exports: [FriendsService],
})
export class FriendsModule {}

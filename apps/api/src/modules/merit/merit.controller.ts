import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsInt, IsISO8601, IsOptional, IsString, IsUUID, Min, MinLength } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { MeritService } from './merit.service';

class WoodenFishTapDto {
  @IsUUID()
  client_request_id!: string;

  @IsISO8601()
  tapped_at!: string;
}

class TransferMeritDto {
  @IsString()
  @MinLength(1)
  to_user_id!: string;

  @IsInt()
  @Min(1)
  amount!: number;

  @IsUUID()
  client_request_id!: string;

  @IsOptional()
  @IsString()
  message?: string;
}

@Controller('merit')
@UseGuards(DevAuthGuard)
export class MeritController {
  constructor(private readonly meritService: MeritService) {}

  @Post('wooden-fish/tap')
  tapWoodenFish(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: WoodenFishTapDto,
  ) {
    return this.meritService.tapWoodenFish(user.id, dto.client_request_id);
  }

  @Get('summary')
  summary(@CurrentUser() user: CurrentUserPayload) {
    return this.meritService.getSummary(user.id);
  }

  @Post('transfer')
  transfer(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: TransferMeritDto,
  ) {
    return this.meritService.transferMerit(
      user.id,
      dto.to_user_id,
      dto.amount,
      dto.client_request_id,
      dto.message,
    );
  }
}

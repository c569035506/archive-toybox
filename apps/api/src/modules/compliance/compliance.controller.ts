import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';
import { ComplianceService } from './compliance.service';

class PrivacyAckDto {
  @IsString()
  doc_type!: string;

  @IsString()
  version!: string;
}

@Controller()
export class ComplianceController {
  constructor(private readonly complianceService: ComplianceService) {}

  @Get('legal/privacy-policy')
  privacyPolicy() {
    return this.complianceService.getPrivacyPolicy();
  }

  @Get('legal/terms')
  terms() {
    return this.complianceService.getTerms();
  }

  @Post('compliance/privacy-ack')
  @UseGuards(DevAuthGuard)
  ack(@CurrentUser() user: CurrentUserPayload, @Body() dto: PrivacyAckDto) {
    return this.complianceService.recordAck(user.id, dto.doc_type, dto.version);
  }
}

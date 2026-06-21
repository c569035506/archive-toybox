import { Module } from '@nestjs/common';
import { ComplianceController } from './compliance.controller';
import { ComplianceService } from './compliance.service';
import { DevAuthGuard } from '../../common/guards/dev-auth.guard';

@Module({
  controllers: [ComplianceController],
  providers: [ComplianceService, DevAuthGuard],
})
export class ComplianceModule {}

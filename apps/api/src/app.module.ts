import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './modules/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { ToyboxModule } from './modules/toybox/toybox.module';
import { MeditationModule } from './modules/meditation/meditation.module';
import { MeritModule } from './modules/merit/merit.module';
import { FortuneModule } from './modules/fortune/fortune.module';
import { ArgumentModule } from './modules/argument/argument.module';
import { FriendsModule } from './modules/friends/friends.module';
import { ComplianceModule } from './modules/compliance/compliance.module';

@Module({
  imports: [
    PrismaModule,
    HealthModule,
    AuthModule,
    ToyboxModule,
    MeditationModule,
    MeritModule,
    FortuneModule,
    ArgumentModule,
    FriendsModule,
    ComplianceModule,
  ],
})
export class AppModule {}

import { Module } from '@nestjs/common';
import { ModerationController } from './moderation.controller';
import { TenantDbService } from '../../site/tenant-db.service';

@Module({
  controllers: [ModerationController],
  providers: [TenantDbService],
})
export class ModerationModule {}

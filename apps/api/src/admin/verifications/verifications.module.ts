import { Module } from '@nestjs/common';
import { VerificationsController } from './verifications.controller';
import { TenantDbService } from '../../site/tenant-db.service';

@Module({
  controllers: [VerificationsController],
  providers: [TenantDbService],
})
export class VerificationsModule {}

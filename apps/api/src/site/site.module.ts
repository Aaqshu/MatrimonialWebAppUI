import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { SiteController } from './site.controller';
import { SiteProfileController } from './profile.controller';
import { SitePhotosController } from './photos.controller';
import { SiteVerificationController } from './verification.controller';
import { SitePrivacyController } from './privacy.controller';
import { SiteSearchController } from './search.controller';
import { SiteDiscoveryController } from './discovery.controller';
import { TenantDbService } from './tenant-db.service';
import { OtpDeliveryService } from './otp-delivery.service';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET', 'admin-secret-dev'),
        signOptions: { expiresIn: '24h' },
      }),
    }),
  ],
  controllers: [SiteController, SiteProfileController, SitePhotosController, SiteVerificationController, SitePrivacyController, SiteSearchController, SiteDiscoveryController],
  providers: [TenantDbService, OtpDeliveryService],
  exports: [TenantDbService],
})
export class SiteModule {}

import { Module } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { AppConfigModule } from './config/config.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { TenantsModule } from './admin/tenants/tenants.module';
import { ThemeConfigsModule } from './admin/theme-configs/theme-configs.module';
import { FeatureFlagsModule } from './admin/feature-flags/feature-flags.module';
import { PlansModule } from './admin/plans/plans.module';
import { TemplatesModule } from './admin/templates/templates.module';
import { SettingsModule } from './admin/settings/settings.module';
import { ProvisioningModule } from './admin/provisioning/provisioning.module';
import { DashboardModule } from './admin/dashboard/dashboard.module';
import { AdminUsersModule } from './admin/admin-users/admin-users.module';
import { SubscriptionsModule } from './admin/subscriptions/subscriptions.module';
import { PaymentsModule } from './admin/payments/payments.module';
import { VerificationsModule } from './admin/verifications/verifications.module';
import { BackupsModule } from './admin/backups/backups.module';
import { ModerationModule } from './admin/moderation/moderation.module';
import { SiteModule } from './site/site.module';
import { JwtAuthGuard } from './auth/jwt-auth.guard';

@Module({
  imports: [
    AppConfigModule,
    PrismaModule,
    AuthModule,
    TenantsModule,
    ThemeConfigsModule,
    FeatureFlagsModule,
    PlansModule,
    TemplatesModule,
    SettingsModule,
    ProvisioningModule,
    DashboardModule,
    AdminUsersModule,
    SubscriptionsModule,
    PaymentsModule,
    VerificationsModule,
    BackupsModule,
    ModerationModule,
    SiteModule,
  ],
  providers: [
    Reflector,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}

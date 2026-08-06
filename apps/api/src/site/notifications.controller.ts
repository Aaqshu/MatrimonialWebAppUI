import { Body, Controller, Get, Headers, Param, Patch, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

@Public()
@Controller('site/notifications')
export class SiteNotificationsController {
  constructor(
    private tenantDb: TenantDbService,
    private jwt: JwtService,
  ) {}

  private auth(headers: any): { sub: string } {
    const authz: string = headers['authorization'] || '';
    if (!authz.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    try {
      return this.jwt.verify(authz.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  @Get(':tenantDbName')
  async list(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query(
      `SELECT * FROM "Notifications" WHERE "UserId" = $1 ORDER BY "CreatedOn" DESC LIMIT 50`,
      [sub],
    );
    const unread = (await db.query(
      `SELECT COUNT(*)::int AS c FROM "Notifications" WHERE "UserId" = $1 AND "IsRead" = FALSE`,
      [sub],
    )).rows[0].c;
    return { notifications: rows, unreadCount: unread };
  }

  @Patch(':tenantDbName/read')
  async markAllRead(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    await db.query(
      `UPDATE "Notifications" SET "IsRead" = TRUE WHERE "UserId" = $1 AND "IsRead" = FALSE`,
      [sub],
    );
    return { read: true };
  }
}

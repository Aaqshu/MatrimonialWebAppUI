import { Controller, Get, Headers, Param, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

@Public()
@Controller('site/viewers')
export class SiteViewersController {
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
  async viewers(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const { rows } = await db.query(
      `SELECT pv."ViewerUserId", pv."ViewedOn", u."FirstName", u."LastName",
              l."City",
              (SELECT ph."PhotoUrl" FROM "UserPhotos" ph WHERE ph."UserId" = u."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "PhotoUrl",
              CASE WHEN p."DateOfBirth" IS NOT NULL THEN DATE_PART('year', AGE(p."DateOfBirth"))::int END AS "Age"
       FROM "ProfileViews" pv
       JOIN "Users" u ON u."UserId" = pv."ViewerUserId"
       LEFT JOIN "UserProfiles" p ON p."UserId" = u."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       WHERE pv."ViewedUserId" = $1
       ORDER BY pv."ViewedOn" DESC
       LIMIT 50`,
      [sub],
    );

    return { viewers: rows };
  }
}

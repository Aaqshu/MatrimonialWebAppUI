import { BadRequestException, Body, Controller, Get, Headers, Param, Patch, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const VISIBILITY = ['everyone', 'matches_only', 'premium_only', 'nobody'];
const PROFILE_VISIBLE_TO = ['everyone', 'same_community', 'premium_only'];

const DEFAULTS = {
  PhotoVisibility: 'everyone',
  ContactVisibility: 'matches_only',
  ProfileVisibleTo: 'everyone',
  ShowOnlineStatus: true,
};

@Public()
@Controller('site/privacy')
export class SitePrivacyController {
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
  async get(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query('SELECT * FROM "PrivacySettings" WHERE "UserId" = $1', [sub]);
    return rows[0] ? { ...DEFAULTS, ...rows[0] } : DEFAULTS;
  }

  @Patch(':tenantDbName')
  async update(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;

    if (body.PhotoVisibility !== undefined) {
      if (!VISIBILITY.includes(body.PhotoVisibility)) throw new BadRequestException('Invalid PhotoVisibility');
      sets.push('"PhotoVisibility" = $' + i++); vals.push(body.PhotoVisibility);
    }
    if (body.ContactVisibility !== undefined) {
      if (!VISIBILITY.includes(body.ContactVisibility)) throw new BadRequestException('Invalid ContactVisibility');
      sets.push('"ContactVisibility" = $' + i++); vals.push(body.ContactVisibility);
    }
    if (body.ProfileVisibleTo !== undefined) {
      if (!PROFILE_VISIBLE_TO.includes(body.ProfileVisibleTo)) throw new BadRequestException('Invalid ProfileVisibleTo');
      sets.push('"ProfileVisibleTo" = $' + i++); vals.push(body.ProfileVisibleTo);
    }
    if (body.ShowOnlineStatus !== undefined) {
      if (typeof body.ShowOnlineStatus !== 'boolean') throw new BadRequestException('ShowOnlineStatus must be boolean');
      sets.push('"ShowOnlineStatus" = $' + i++); vals.push(body.ShowOnlineStatus);
    }
    if (!sets.length) throw new BadRequestException('No valid fields');

    await db.query(
      `INSERT INTO "PrivacySettings" ("UserId") VALUES ($1) ON CONFLICT ("UserId") DO NOTHING`,
      [sub],
    );
    vals.push(sub);
    const { rows } = await db.query(
      `UPDATE "PrivacySettings" SET ${sets.join(',')} WHERE "UserId" = $${i} RETURNING *`,
      vals,
    );
    return { ...DEFAULTS, ...rows[0] };
  }
}

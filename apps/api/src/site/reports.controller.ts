import { BadRequestException, Body, Controller, Get, Headers, Param, Post, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const REASONS = ['fake_profile', 'harassment', 'inappropriate_content', 'other'];

@Public()
@Controller('site/reports')
export class SiteReportsController {
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

  @Post(':tenantDbName')
  async create(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const { reportedUserId, reason, description } = body || {};
    if (!reportedUserId) throw new BadRequestException('reportedUserId required');
    if (reportedUserId === sub) throw new BadRequestException('Cannot report yourself');
    if (!reason || !REASONS.includes(reason)) throw new BadRequestException('Valid reason required');
    if (description && String(description).length > 2000) throw new BadRequestException('Description too long');

    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query(
      `INSERT INTO "Reports" ("ReportId","ReporterUserId","ReportedUserId","Reason","Description","Status")
       VALUES ($1,$2,$3,$4,$5,'open') RETURNING *`,
      [uuid(), sub, reportedUserId, reason, description ?? null],
    );
    return { report: rows[0] };
  }
}

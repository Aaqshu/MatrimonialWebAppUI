import { BadRequestException, Body, Controller, Get, Headers, Param, Post, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const DOC_TYPES = ['aadhaar', 'pan', 'passport', 'driving_license', 'work_email'];

@Public()
@Controller('site/verification')
export class SiteVerificationController {
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
  async request(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const { docType, docReference } = body || {};
    if (!docType || !DOC_TYPES.includes(docType)) throw new BadRequestException('Valid docType required');
    if (!docReference) throw new BadRequestException('docReference required');

    const db = this.tenantDb.getDb(tenantDbName);
    const pending = (await db.query(
      `SELECT 1 FROM "VerificationRequests" WHERE "UserId" = $1 AND "Status" = 'pending'`,
      [sub],
    )).rows[0];
    if (pending) throw new BadRequestException('Already have a pending verification request');

    const { rows } = await db.query(
      `INSERT INTO "VerificationRequests" ("VerificationId","UserId","DocType","DocReference","Status")
       VALUES ($1,$2,$3,$4,'pending') RETURNING *`,
      [uuid(), sub, docType, docReference],
    );
    return { request: rows[0] };
  }

  @Get(':tenantDbName')
  async list(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query(
      'SELECT * FROM "VerificationRequests" WHERE "UserId" = $1 ORDER BY "CreatedOn" DESC',
      [sub],
    );
    return { requests: rows };
  }
}

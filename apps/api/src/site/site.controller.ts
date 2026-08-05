import { BadRequestException, Body, Controller, Get, Headers, Post, Req, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { randomUUID as uuid, randomBytes, createHash } from 'crypto';
import * as bcrypt from 'bcrypt';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';
import { OtpDeliveryService } from './otp-delivery.service';

const SAFE_USER_COLUMNS =
  '"UserId","UserName","FirstName","LastName","Email","Phone","Role","Status","IsActive","LastLogin","CreatedOn","UpdatedOn"';

const isDevMode = () => process.env.SITE_OTP_DEV_MODE !== 'false';

@Public()
@Controller('site')
export class SiteController {
  constructor(
    private tenantDb: TenantDbService,
    private otpDelivery: OtpDeliveryService,
    private jwt: JwtService,
  ) {}

  @Post('otp/request')
  async requestOtp(@Body() body: any) {
    const { tenantDbName, phone, email } = body || {};
    if (!tenantDbName) throw new BadRequestException('tenantDbName is required');
    if (!phone && !email) throw new BadRequestException('phone or email is required');

    const db = this.tenantDb.getDb(tenantDbName);

    let user = (
      await db.query(`SELECT ${SAFE_USER_COLUMNS} FROM "Users" WHERE "Phone" = $1 OR "Email" = $2`, [
        phone ?? null,
        email ?? null,
      ])
    ).rows[0];

    if (!user) {
      user = (
        await db.query(
          `INSERT INTO "Users" ("UserId","FirstName","Phone","Email","Status")
           VALUES ($1,$2,$3,$4,$5) RETURNING ${SAFE_USER_COLUMNS}`,
          [uuid(), 'User', phone ?? null, email ?? null, 'pending_verification'],
        )
      ).rows[0];
    }

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = await bcrypt.hash(otp, 10);
    const requestId = uuid();
    // OTPRequests only has a "Phone" column (no Email); it doubles as the generic
    // contact identifier for whichever channel (phone or email) the OTP was sent to.
    const contact = phone ?? email;

    await db.query(
      `INSERT INTO "OTPRequests" ("OTPRequestId","UserId","Phone","OTPHash","ExpiresOn")
       VALUES ($1,$2,$3,$4, NOW() + INTERVAL '5 minutes')`,
      [requestId, user.UserId, contact, otpHash],
    );

    const deliveryChannels: string[] = [];
    if (phone) {
      deliveryChannels.push('whatsapp');
      await this.otpDelivery.sendWhatsApp(phone, otp);
    }
    if (email) {
      deliveryChannels.push('email');
      await this.otpDelivery.sendEmail(email, otp);
    }

    const response: any = { requestId, deliveryChannels };
    if (isDevMode()) response.otp = otp;
    return response;
  }

  @Post('otp/verify')
  async verifyOtp(@Body() body: any, @Req() req: Request) {
    const { tenantDbName, phone, email, otp } = body || {};
    if (!tenantDbName) throw new BadRequestException('tenantDbName is required');
    if (!phone && !email) throw new BadRequestException('phone or email is required');
    if (!otp) throw new BadRequestException('otp is required');

    const db = this.tenantDb.getDb(tenantDbName);
    const contact = phone ?? email;

    const otpRow = (
      await db.query(
        `SELECT * FROM "OTPRequests"
         WHERE "Phone" = $1 AND "IsVerified" = FALSE AND "ExpiresOn" > NOW()
         ORDER BY "CreatedOn" DESC LIMIT 1`,
        [contact],
      )
    ).rows[0];

    if (!otpRow) throw new UnauthorizedException('OTP not found or expired');

    const matches = await bcrypt.compare(otp, otpRow.OTPHash);
    if (!matches) throw new UnauthorizedException('Invalid OTP');

    await db.query(`UPDATE "OTPRequests" SET "IsVerified" = TRUE WHERE "OTPRequestId" = $1`, [otpRow.OTPRequestId]);

    const user = (
      await db.query(
        `UPDATE "Users" SET "Status" = 'active', "LastLogin" = NOW() WHERE "UserId" = $1 RETURNING ${SAFE_USER_COLUMNS}`,
        [otpRow.UserId],
      )
    ).rows[0];

    const refreshToken = randomBytes(32).toString('hex');
    const refreshTokenHash = createHash('sha256').update(refreshToken).digest('hex');

    await db.query(
      `INSERT INTO "UserSessions" ("SessionId","UserId","RefreshToken","Browser","IPAddress")
       VALUES ($1,$2,$3,$4,$5)`,
      [uuid(), user.UserId, refreshTokenHash, req.headers['user-agent'] ?? null, req.ip ?? null],
    );

    const access_token = this.jwt.sign({ sub: user.UserId, tenantDbName, role: 'end_user' });

    return { access_token, user };
  }

  @Get('me')
  async me(@Headers('authorization') authorization: string) {
    if (!authorization?.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    const token = authorization.slice('Bearer '.length);

    let payload: any;
    try {
      payload = this.jwt.verify(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }

    const db = this.tenantDb.getDb(payload.tenantDbName);
    const user = (
      await db.query(`SELECT ${SAFE_USER_COLUMNS} FROM "Users" WHERE "UserId" = $1`, [payload.sub])
    ).rows[0];

    if (!user) throw new UnauthorizedException('User not found');
    return user;
  }
}

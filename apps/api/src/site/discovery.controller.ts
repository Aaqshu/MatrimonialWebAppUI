import { BadRequestException, Body, Controller, Delete, Get, Headers, Param, Patch, Post, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

@Public()
@Controller('site')
export class SiteDiscoveryController {
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

  // ── PUBLIC PROFILE VIEW ──
  @Get('profile/:tenantDbName/:userId')
  async publicProfile(@Param('tenantDbName') tenantDbName: string, @Param('userId') userId: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    if (userId === sub) throw new BadRequestException('This is your own profile');
    const db = this.tenantDb.getDb(tenantDbName);

    const profile = (await db.query(
      `SELECT u."UserId", u."FirstName", u."LastName", p."Gender", p."DateOfBirth",
              p."Height", p."Weight", p."MaritalStatus", p."Religion", p."Caste",
              p."SubCaste", p."Sect", p."MotherTongue", p."AboutMe", p."VerificationStatus",
              e."Qualification", e."College", o."Occupation", o."CompanyName", o."Designation",
              o."AnnualIncome", l."City", l."State", ls."Diet", ls."Hobbies", ls."LanguagesKnown",
              f."FamilyType", f."FamilyStatus", f."FatherName", f."FatherOccupation",
              f."MotherName", f."MotherOccupation", f."Brothers", f."Sisters",
              CASE WHEN p."DateOfBirth" IS NOT NULL THEN DATE_PART('year', AGE(p."DateOfBirth"))::int END AS "Age"
       FROM "Users" u
       JOIN "UserProfiles" p ON p."UserId" = u."UserId"
       LEFT JOIN "UserEducation" e ON e."UserId" = u."UserId"
       LEFT JOIN "UserOccupation" o ON o."UserId" = u."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       LEFT JOIN "UserLifestyle" ls ON ls."UserId" = u."UserId"
       LEFT JOIN "UserFamilyDetails" f ON f."UserId" = u."UserId"
       WHERE u."UserId" = $1 AND u."Status" = 'active'`,
      [userId],
    )).rows[0];
    if (!profile) throw new BadRequestException('Profile not found');

    const photos = (await db.query(
      `SELECT "PhotoUrl" FROM "UserPhotos" WHERE "UserId" = $1 AND "IsApproved" = TRUE ORDER BY "IsPrimary" DESC, "DisplayOrder"`,
      [userId],
    )).rows.map(r => r.PhotoUrl);

    const fav = (await db.query(
      `SELECT 1 FROM "Favorites" WHERE "UserId" = $1 AND "FavoriteUserId" = $2`,
      [sub, userId],
    )).rows[0];
    const blocked = (await db.query(
      `SELECT 1 FROM "BlockedUsers" WHERE "UserId" = $1 AND "BlockedUserId" = $2`,
      [sub, userId],
    )).rows[0];

    const myPrefs = (await db.query(`SELECT * FROM "UserPreferences" WHERE "UserId" = $1`, [sub])).rows[0];
    const matchPct = myPrefs ? this.computeMatch(myPrefs, profile) : null;

    await db.query(
      `INSERT INTO "ProfileViews" ("ViewId","ViewerUserId","ViewedUserId") VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
      [uuid(), sub, userId],
    );

    return { ...profile, Photos: photos, MatchPercent: matchPct, IsFavorite: !!fav, IsBlocked: !!blocked };
  }

  // ── INTERESTS ──
  @Post('interests/:tenantDbName')
  async sendInterest(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const toUserId = body?.toUserId;
    if (!toUserId) throw new BadRequestException('toUserId required');
    if (toUserId === sub) throw new BadRequestException('Cannot send interest to yourself');
    const db = this.tenantDb.getDb(tenantDbName);

    const dup = (await db.query(
      `SELECT 1 FROM "InterestRequests" WHERE "SenderUserId" = $1 AND "ReceiverUserId" = $2 AND "Status" IN ('pending','accepted')`,
      [sub, toUserId],
    )).rows[0];
    if (dup) throw new BadRequestException('Interest already sent');

    const { rows } = await db.query(
      `INSERT INTO "InterestRequests" ("InterestId","SenderUserId","ReceiverUserId","Status")
       VALUES ($1,$2,$3,'pending') RETURNING *`,
      [uuid(), sub, toUserId],
    );
    return { interest: rows[0] };
  }

  @Patch('interests/:tenantDbName/:id')
  async respondInterest(@Param('tenantDbName') tenantDbName: string, @Param('id') id: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    if (!['accepted', 'declined'].includes(body?.status)) throw new BadRequestException('status must be accepted|declined');
    const db = this.tenantDb.getDb(tenantDbName);

    const owned = (await db.query(
      `SELECT 1 FROM "InterestRequests" WHERE "InterestId" = $1 AND "ReceiverUserId" = $2 AND "Status" = 'pending'`,
      [id, sub],
    )).rows[0];
    if (!owned) throw new BadRequestException('Interest not found or already responded');

    const { rows } = await db.query(
      `UPDATE "InterestRequests" SET "Status" = $1, "RespondedOn" = NOW() WHERE "InterestId" = $2 RETURNING *`,
      [body.status, id],
    );
    return { interest: rows[0] };
  }

  // ── MATCHES (received/sent interests) ──
  @Get('matches/:tenantDbName')
  async matches(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const received = (await db.query(
      `SELECT ir."InterestId" AS "InterestRequestId", ir."SenderUserId" AS "FromUserId",
              ir."Status", ir."SentOn" AS "CreatedOn",
              u."FirstName", u."LastName", l."City",
              (SELECT ph."PhotoUrl" FROM "UserPhotos" ph WHERE ph."UserId" = u."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "FromPhotoUrl",
              CASE WHEN p."DateOfBirth" IS NOT NULL THEN DATE_PART('year', AGE(p."DateOfBirth"))::int END AS "FromAge"
       FROM "InterestRequests" ir
       JOIN "Users" u ON u."UserId" = ir."SenderUserId"
       LEFT JOIN "UserProfiles" p ON p."UserId" = u."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       WHERE ir."ReceiverUserId" = $1 ORDER BY ir."SentOn" DESC`,
      [sub],
    )).rows;

    const sent = (await db.query(
      `SELECT ir."InterestId" AS "InterestRequestId", ir."ReceiverUserId" AS "ToUserId",
              ir."Status", ir."SentOn" AS "CreatedOn",
              u."FirstName", u."LastName", l."City",
              (SELECT ph."PhotoUrl" FROM "UserPhotos" ph WHERE ph."UserId" = u."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "ToPhotoUrl",
              CASE WHEN p."DateOfBirth" IS NOT NULL THEN DATE_PART('year', AGE(p."DateOfBirth"))::int END AS "ToAge"
       FROM "InterestRequests" ir
       JOIN "Users" u ON u."UserId" = ir."ReceiverUserId"
       LEFT JOIN "UserProfiles" p ON p."UserId" = u."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       WHERE ir."SenderUserId" = $1 ORDER BY ir."SentOn" DESC`,
      [sub],
    )).rows;

    return { received, sent };
  }

  // ── FAVORITES ──
  @Post('favorites/:tenantDbName/:userId')
  async addFavorite(@Param('tenantDbName') tenantDbName: string, @Param('userId') userId: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    if (userId === sub) throw new BadRequestException('Cannot favorite yourself');
    const db = this.tenantDb.getDb(tenantDbName);
    await db.query(
      `INSERT INTO "Favorites" ("FavoriteId","UserId","FavoriteUserId") VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
      [uuid(), sub, userId],
    );
    return { favorited: true };
  }

  @Delete('favorites/:tenantDbName/:userId')
  async removeFavorite(@Param('tenantDbName') tenantDbName: string, @Param('userId') userId: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    await db.query(`DELETE FROM "Favorites" WHERE "UserId" = $1 AND "FavoriteUserId" = $2`, [sub, userId]);
    return { favorited: false };
  }

  // ── BLOCK ──
  @Post('block/:tenantDbName/:userId')
  async blockUser(@Param('tenantDbName') tenantDbName: string, @Param('userId') userId: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    if (userId === sub) throw new BadRequestException('Cannot block yourself');
    const db = this.tenantDb.getDb(tenantDbName);
    await db.query(
      `INSERT INTO "BlockedUsers" ("BlockId","UserId","BlockedUserId") VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
      [uuid(), sub, userId],
    );
    return { blocked: true };
  }

  private computeMatch(prefs: any, prof: any): number {
    let score = 0;
    const total = 6;
    score += 1;
    if (prefs.MinAge && prof.Age) {
      if (prof.Age >= prefs.MinAge && (!prefs.MaxAge || prof.Age <= prefs.MaxAge)) score += 1;
    } else score += 1;
    if (prefs.MinHeight && prof.Height) {
      if (prof.Height >= prefs.MinHeight && (!prefs.MaxHeight || prof.Height <= prefs.MaxHeight)) score += 1;
    } else score += 1;
    if (Array.isArray(prefs.Religion) && prefs.Religion.length) {
      if (prefs.Religion.includes(prof.Religion)) score += 1;
    } else score += 1;
    if (Array.isArray(prefs.Caste) && prefs.Caste.length) {
      if (prefs.Caste.includes(prof.Caste)) score += 1;
    } else score += 1;
    if (prefs.City && prof.City) {
      if (prefs.City.toLowerCase() === prof.City.toLowerCase()) score += 1;
    } else score += 1;
    return Math.round((score / total) * 100);
  }
}

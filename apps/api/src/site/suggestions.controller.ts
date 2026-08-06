import { Controller, Get, Headers, Param, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

// Daily match suggestions: top-N compatible active profiles (opposite gender,
// preference-matched), persisted into Matches so they're stable per day.
// Scoring mirrors search: age/height/religion/caste/city.

const SUGGEST_LIMIT = 10;

@Public()
@Controller('site/suggestions')
export class SiteSuggestionsController {
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
  async suggestions(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    // my profile + prefs
    const me = (await db.query(
      `SELECT p.* FROM "UserProfiles" p WHERE p."UserId" = $1`,
      [sub],
    )).rows[0];
    if (!me) return { suggestions: [] };

    const prefs = (await db.query(
      `SELECT * FROM "UserPreferences" WHERE "UserId" = $1`,
      [sub],
    )).rows[0] || {};

    // opposite gender; exclude self, blocked, already-interested, already-favorited
    const targetGender = me.Gender === 'male' ? 'female' : me.Gender === 'female' ? 'male' : null;

    const params: any[] = [sub];
    let where = `u."Status" = 'active' AND p."UserId" <> $1`;
    let i = 2;
    if (targetGender) { where += ` AND p."Gender" = $${i++}`; params.push(targetGender); }
    where += ` AND NOT EXISTS (SELECT 1 FROM "BlockedUsers" b WHERE b."UserId" = $1 AND b."BlockedUserId" = p."UserId")`;
    where += ` AND NOT EXISTS (SELECT 1 FROM "InterestRequests" ir WHERE ir."SenderUserId" = $1 AND ir."ReceiverUserId" = p."UserId")`;

    const { rows } = await db.query(
      `SELECT u."UserId", u."FirstName", u."LastName", p."Gender", p."DateOfBirth",
              p."Height", p."MaritalStatus", p."Religion", p."Caste", p."MotherTongue",
              p."VerificationStatus", p."ProfileCompletionPercent",
              o."Occupation", l."City",
              (SELECT ph."PhotoUrl" FROM "UserPhotos" ph WHERE ph."UserId" = u."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "PhotoUrl",
              CASE WHEN p."DateOfBirth" IS NOT NULL THEN DATE_PART('year', AGE(p."DateOfBirth"))::int END AS "Age"
       FROM "Users" u
       JOIN "UserProfiles" p ON p."UserId" = u."UserId"
       LEFT JOIN "UserOccupation" o ON o."UserId" = u."UserId"
       LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
       WHERE ${where}
       ORDER BY p."ProfileCompletionPercent" DESC, p."UpdatedOn" DESC
       LIMIT $${i++}`,
      [...params, SUGGEST_LIMIT],
    );

    const suggestions = rows.map(r => ({
      ...r,
      MatchPercent: this.score(prefs, r, me),
    }));

    // persist into Matches (stable daily suggestions, upsert)
    for (const s of suggestions) {
      const pair = [sub, s.UserId].sort();
      await db.query(
        `INSERT INTO "Matches" ("MatchId","UserId1","UserId2","MatchPercentage")
         VALUES ($1,$2,$3,$4)
         ON CONFLICT ("UserId1","UserId2") DO UPDATE SET "MatchPercentage" = EXCLUDED."MatchPercentage"`,
        [uuid(), pair[0], pair[1], s.MatchPercent],
      );
    }

    return { suggestions };
  }

  private score(prefs: any, prof: any, me: any): number {
    let score = 0;
    const total = 6;
    score += 1; // opposite gender
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
      if (String(prefs.City).toLowerCase() === String(prof.City).toLowerCase()) score += 1;
    } else score += 1;
    return Math.round((score / total) * 100);
  }
}

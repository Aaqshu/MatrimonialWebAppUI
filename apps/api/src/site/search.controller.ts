import { Controller, Get, Query, Headers, UnauthorizedException, Param } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const PAGE_SIZE_DEFAULT = 12;
const PAGE_SIZE_MAX = 50;

// Simple profile → search-card projection used by /site/search
const CARD_SQL = `
  SELECT
    u."UserId", u."FirstName", u."LastName", p."Gender", p."DateOfBirth",
    p."Height", p."MaritalStatus", p."Religion", p."Caste", p."SubCaste",
    p."MotherTongue", p."AboutMe", p."VerificationStatus",
    e."Qualification", o."Occupation", o."CompanyName", o."AnnualIncome",
    l."City", l."State", ls."Diet",
    (SELECT ph."PhotoUrl" FROM "UserPhotos" ph
      WHERE ph."UserId" = u."UserId" AND ph."IsPrimary" = TRUE LIMIT 1) AS "PhotoUrl",
    CASE WHEN p."DateOfBirth" IS NOT NULL
      THEN DATE_PART('year', AGE(p."DateOfBirth"))::int ELSE NULL END AS "Age"
  FROM "Users" u
  JOIN "UserProfiles" p ON p."UserId" = u."UserId"
  LEFT JOIN "UserEducation" e ON e."UserId" = u."UserId"
  LEFT JOIN "UserOccupation" o ON o."UserId" = u."UserId"
  LEFT JOIN "UserLocation" l ON l."UserId" = u."UserId"
  LEFT JOIN "UserLifestyle" ls ON ls."UserId" = u."UserId"
  WHERE u."Status" = 'active'
`;

@Public()
@Controller('site/search')
export class SiteSearchController {
  constructor(
    private tenantDb: TenantDbService,
    private jwt: JwtService,
  ) {}

  private auth(headers: any): { sub: string; tenantDbName: string } {
    const authz: string = headers['authorization'] || '';
    if (!authz.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    try {
      return this.jwt.verify(authz.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  @Get(':tenantDbName')
  async search(
    @Param('tenantDbName') tenantDbName: string,
    @Query() q: any,
    @Headers() headers: any,
  ) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const where: string[] = [`u."UserId" <> $1`];
    const params: any[] = [sub];
    let i = 2;

    if (q.gender) { where.push(`p."Gender" = $${i++}`); params.push(q.gender); }
    if (q.minAge) { where.push(`DATE_PART('year', AGE(p."DateOfBirth")) >= $${i++}`); params.push(Number(q.minAge)); }
    if (q.maxAge) { where.push(`DATE_PART('year', AGE(p."DateOfBirth")) <= $${i++}`); params.push(Number(q.maxAge)); }
    if (q.religion) { where.push(`p."Religion" ILIKE $${i++}`); params.push(`%${q.religion}%`); }
    if (q.caste) { where.push(`p."Caste" ILIKE $${i++}`); params.push(`%${q.caste}%`); }
    if (q.city) { where.push(`l."City" ILIKE $${i++}`); params.push(`%${q.city}%`); }
    if (q.education) { where.push(`e."Qualification" ILIKE $${i++}`); params.push(`%${q.education}%`); }
    if (q.occupation) { where.push(`o."Occupation" ILIKE $${i++}`); params.push(`%${q.occupation}%`); }
    if (q.diet) { where.push(`ls."Diet" = $${i++}`); params.push(q.diet); }

    // blocked users excluded
    where.push(`NOT EXISTS (SELECT 1 FROM "BlockedUsers" b WHERE b."UserId" = $1 AND b."BlockedUserId" = u."UserId")`);

    const page = Math.max(1, Number(q.page) || 1);
    const pageSize = Math.min(PAGE_SIZE_MAX, Number(q.pageSize) || PAGE_SIZE_DEFAULT);
    const offset = (page - 1) * pageSize;

    const countRes = await db.query(
      `SELECT COUNT(*)::int AS total FROM (${CARD_SQL} AND ${where.join(' AND ')}) t`,
      params,
    );
    const total = countRes.rows[0].total;

    const { rows } = await db.query(
      `${CARD_SQL} AND ${where.join(' AND ')}
       ORDER BY p."ProfileCompletionPercent" DESC, p."UpdatedOn" DESC
       LIMIT $${i++} OFFSET $${i++}`,
      [...params, pageSize, offset],
    );

    // favorite + match% decoration
    const favs = (await db.query(
      `SELECT "FavoriteUserId" FROM "Favorites" WHERE "UserId" = $1`,
      [sub],
    )).rows.map(r => r.FavoriteUserId);
    const favSet = new Set(favs);
    const myPrefs = (await db.query(
      `SELECT * FROM "UserPreferences" WHERE "UserId" = $1`,
      [sub],
    )).rows[0];

    const users = rows.map(r => {
      const u: any = { ...r };
      u.IsFavorite = favSet.has(r.UserId);
      u.MatchPercent = myPrefs ? this.computeMatch(myPrefs, r) : null;
      return u;
    });

    return { users, total, page, pageSize };
  }

  private computeMatch(prefs: any, prof: any): number {
    let score = 0;
    const total = 6;
    // gender: opposite of mine is assumed by UI; if both present just add 1
    score += 1; // gender compatibility (basic)
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

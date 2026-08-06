import { BadRequestException, Body, Controller, Get, Param, Post, Patch, UnauthorizedException, Headers, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Each sub-table has: table name, id column, updatable columns
const PROFILE_PARTS: Record<string, { table: string; idCol: string; cols: string[] }> = {
  education: { table: 'UserEducation', idCol: 'EducationId', cols: ['Qualification', 'College', 'University', 'PassingYear', 'EducationType'] },
  occupation: { table: 'UserOccupation', idCol: 'OccupationId', cols: ['Occupation', 'CompanyName', 'Designation', 'AnnualIncome', 'WorkLocation'] },
  family: { table: 'UserFamilyDetails', idCol: 'FamilyId', cols: ['FamilyType', 'FamilyStatus', 'FatherName', 'FatherOccupation', 'MotherName', 'MotherOccupation', 'Brothers', 'Sisters'] },
  lifestyle: { table: 'UserLifestyle', idCol: 'LifestyleId', cols: ['Diet', 'Smoking', 'Drinking', 'Hobbies', 'LanguagesKnown'] },
  location: { table: 'UserLocation', idCol: 'LocationId', cols: ['Country', 'State', 'City', 'Address', 'Pincode'] },
};

const PREFERENCE_COLS = ['MinAge', 'MaxAge', 'MinHeight', 'MaxHeight', 'Religion', 'Caste', 'Education', 'Occupation', 'Country', 'State', 'City'];
const PROFILE_COLS = ['Gender', 'DateOfBirth', 'Height', 'Weight', 'MaritalStatus', 'Religion', 'Caste', 'SubCaste', 'Sect', 'MotherTongue', 'BloodGroup', 'AboutMe'];

@Public()
@Controller('site/profile')
export class SiteProfileController {
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
  async get(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const profile = (await db.query('SELECT * FROM "UserProfiles" WHERE "UserId" = $1', [sub])).rows[0];
    if (!profile) throw new NotFoundException('Profile not found');

    const out: any = { profile };
    for (const [key, part] of Object.entries(PROFILE_PARTS)) {
      const row = (await db.query(`SELECT * FROM "${part.table}" WHERE "UserId" = $1`, [sub])).rows[0];
      out[key] = row || null;
    }
    out.preferences = (await db.query('SELECT * FROM "UserPreferences" WHERE "UserId" = $1', [sub])).rows[0] || null;
    return out;
  }

  @Post(':tenantDbName')
  async create(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const p = body.profile || body;

    if (!p.Gender || !p.DateOfBirth) throw new BadRequestException('Gender and DateOfBirth are required');

    await db.query(
      `INSERT INTO "UserProfiles" ("ProfileId","UserId","Gender","DateOfBirth","Height","Weight","MaritalStatus","Religion","Caste","SubCaste","Sect","MotherTongue","BloodGroup","AboutMe")
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) ON CONFLICT ("UserId") DO NOTHING`,
      [uuid(), sub, p.Gender, p.DateOfBirth, p.Height ?? null, p.Weight ?? null, p.MaritalStatus ?? 'never_married', p.Religion ?? null, p.Caste ?? null, p.SubCaste ?? null, p.Sect ?? null, p.MotherTongue ?? null, p.BloodGroup ?? null, p.AboutMe ?? null],
    );

    // sync name onto Users (create path) so dashboards never show the "User" placeholder
    if (p.FirstName || p.LastName) {
      await db.query(
        `UPDATE "Users" SET "FirstName" = $1, "LastName" = $2 WHERE "UserId" = $3`,
        [p.FirstName ?? null, p.LastName ?? null, sub],
      );
    }

    for (const [key, part] of Object.entries(PROFILE_PARTS)) {
      const data = body[key];
      if (!data || typeof data !== 'object') continue;
      const cols = part.cols;
      const placeholders = cols.map((_, i) => `$${i + 3}`).join(',');
      const vals = [uuid(), sub, ...cols.map(c => data[c] ?? null)];
      await db.query(
        `INSERT INTO "${part.table}" ("${part.idCol}","UserId",${cols.map(c => `"${c}"`).join(',')})
         VALUES ($1,$2,${placeholders}) ON CONFLICT DO NOTHING`,
        vals,
      );
    }

    if (body.preferences) await this.upsertPreferences(db, sub, body.preferences);
    await this.updateCompletion(db, sub);
    return { created: true };
  }

  @Patch(':tenantDbName')
  async update(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const profile = (await db.query('SELECT 1 FROM "UserProfiles" WHERE "UserId" = $1', [sub])).rows[0];
    if (!profile) throw new NotFoundException('Profile not found — POST first');

    if (body.profile) {
      const sets: string[] = [];
      const vals: any[] = [];
      let i = 1;
      for (const [k, v] of Object.entries(body.profile)) {
        if (PROFILE_COLS.includes(k)) { sets.push(`"${k}" = $${i++}`); vals.push(v); }
      }
      if (sets.length) {
        vals.push(sub);
        await db.query(`UPDATE "UserProfiles" SET ${sets.join(',')} WHERE "UserId" = $${i}`, vals);
      }
      // sync FirstName/LastName onto Users so dashboards don't show the "User" placeholder
      const fullName = [body.profile.FirstName, body.profile.LastName].filter(Boolean);
      if (fullName.length) {
        await db.query(
          `UPDATE "Users" SET "FirstName" = $1, "LastName" = $2 WHERE "UserId" = $3`,
          [body.profile.FirstName ?? null, body.profile.LastName ?? null, sub],
        );
      }
    }

    for (const [key, part] of Object.entries(PROFILE_PARTS)) {
      const data = body[key];
      if (!data || typeof data !== 'object') continue;
      const existing = (await db.query(`SELECT "${part.idCol}" FROM "${part.table}" WHERE "UserId" = $1`, [sub])).rows[0];
      const sets: string[] = [];
      const vals: any[] = [];
      let i = 1;
      for (const c of part.cols) {
        if (data[c] !== undefined) { sets.push(`"${c}" = $${i++}`); vals.push(data[c]); }
      }
      if (!sets.length) continue;
      if (existing) {
        vals.push(existing[part.idCol]);
        await db.query(`UPDATE "${part.table}" SET ${sets.join(',')} WHERE "${part.idCol}" = $${i}`, vals);
      } else {
        vals.unshift(uuid(), sub);
        await db.query(
          `INSERT INTO "${part.table}" ("${part.idCol}","UserId",${sets.map(s => s.split(' ')[0]).join(',')}) VALUES ($1,$2,${sets.map((_, idx) => `$${idx + 3}`).join(',')})`,
          [uuid(), sub, ...sets.map((_, i2) => body[key][part.cols[i2]])],
        );
      }
    }

    if (body.preferences) await this.upsertPreferences(db, sub, body.preferences);
    await this.updateCompletion(db, sub);
    return { updated: true };
  }

  @Get(':tenantDbName/preferences')
  async getPreferences(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    return (await db.query('SELECT * FROM "UserPreferences" WHERE "UserId" = $1', [sub])).rows[0] || null;
  }

  private async upsertPreferences(db: any, userId: string, prefs: any) {
    const existing = (await db.query('SELECT "PreferenceId" FROM "UserPreferences" WHERE "UserId" = $1', [userId])).rows[0];
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const c of PREFERENCE_COLS) {
      if (prefs[c] !== undefined) {
        sets.push(`"${c}" = $${i++}`);
        vals.push(typeof prefs[c] === 'object' ? JSON.stringify(prefs[c]) : prefs[c]);
      }
    }
    if (!sets.length) return;
    if (existing) {
      vals.push(existing.PreferenceId);
      await db.query(`UPDATE "UserPreferences" SET ${sets.join(',')} WHERE "PreferenceId" = $${i}`, vals);
    } else {
      vals.unshift(uuid(), userId);
      await db.query(
        `INSERT INTO "UserPreferences" ("PreferenceId","UserId",${sets.map(s => s.split(' ')[0]).join(',')}) VALUES ($1,$2,${sets.map((_, idx) => `$${idx + 3}`).join(',')})`,
        [uuid(), userId, ...Object.keys(prefs).filter(k => PREFERENCE_COLS.includes(k)).map(k => typeof prefs[k] === 'object' ? JSON.stringify(prefs[k]) : prefs[k])],
      );
    }
  }

  // Completion %: Gender+DOB+MaritalStatus = 40, Religion/Caste/MotherTongue = 20, Education/Occupation = 20, Location = 10, AboutMe = 10
  private async updateCompletion(db: any, userId: string) {
    const prof = (await db.query('SELECT * FROM "UserProfiles" WHERE "UserId" = $1', [userId])).rows[0];
    if (!prof) return;
    let pct = 0;
    if (prof.Gender && prof.DateOfBirth && prof.MaritalStatus) pct += 40;
    if (prof.Religion && prof.Caste && prof.MotherTongue) pct += 20;
    const edu = (await db.query('SELECT 1 FROM "UserEducation" WHERE "UserId" = $1', [userId])).rows[0];
    const occ = (await db.query('SELECT 1 FROM "UserOccupation" WHERE "UserId" = $1', [userId])).rows[0];
    if (edu && occ) pct += 20;
    const loc = (await db.query('SELECT 1 FROM "UserLocation" WHERE "UserId" = $1', [userId])).rows[0];
    if (loc) pct += 10;
    if (prof.AboutMe) pct += 10;
    await db.query('UPDATE "UserProfiles" SET "ProfileCompletionPercent" = $1 WHERE "UserId" = $2', [pct, userId]);
  }
}

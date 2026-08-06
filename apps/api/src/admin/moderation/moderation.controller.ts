import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TenantDbService } from '../../site/tenant-db.service';

// Admin moderation queue: reports + success stories (both live in tenant DBs).
@Controller('admin/moderation')
export class ModerationController {
  constructor(
    private db: PrismaService,
    private tenantDb: TenantDbService,
  ) {}

  private async tenantDbName(): Promise<string | null> {
    const { rows } = await this.db.query(
      `SELECT "DatabaseName" FROM "Tenants" WHERE "DatabaseName" IS NOT NULL ORDER BY "CreatedOn"`,
    );
    for (const row of rows) {
      try {
        const pool = this.tenantDb.getDb(row.DatabaseName);
        await pool.query('SELECT 1');
        return row.DatabaseName;
      } catch {
        continue;
      }
    }
    return null;
  }

  @Get()
  async list(@Query('tenantDbName') tenantDbName?: string) {
    const dbName = tenantDbName || (await this.tenantDbName());
    if (!dbName) return { reports: [], stories: [] };
    const pool = this.tenantDb.getDb(dbName);

    let reports: any[] = [];
    let stories: any[] = [];
    try {
      reports = (await pool.query(
        `SELECT r."ReportId", r."Reason", r."Description", r."Status", r."CreatedOn",
                rep."Phone" AS "ReporterPhone", rep2."Phone" AS "ReportedPhone",
                rep2."FirstName" AS "ReportedFirstName"
         FROM "Reports" r
         JOIN "Users" rep ON rep."UserId" = r."ReporterUserId"
         JOIN "Users" rep2 ON rep2."UserId" = r."ReportedUserId"
         ORDER BY r."CreatedOn" DESC`,
      )).rows;
    } catch { reports = []; }

    try {
      stories = (await pool.query(
        `SELECT s."StoryId", s."Testimonial", s."IsPublished", s."CreatedOn",
                u1."FirstName" AS "FirstName1", u2."FirstName" AS "FirstName2"
         FROM "SuccessStories" s
         JOIN "Users" u1 ON u1."UserId" = s."UserId1"
         JOIN "Users" u2 ON u2."UserId" = s."UserId2"
         ORDER BY s."CreatedOn" DESC`,
      )).rows;
    } catch { stories = []; }

    return { reports, stories };
  }

  @Patch('reports/:id')
  async reviewReport(@Param('id') id: string, @Body() body: any, @Query('tenantDbName') tenantDbName?: string) {
    if (!['resolved', 'dismissed'].includes(body?.Status)) throw new NotFoundException('Invalid status');
    const dbName = tenantDbName || (await this.tenantDbName());
    if (!dbName) throw new NotFoundException('No tenant DB');
    const pool = this.tenantDb.getDb(dbName);
    const { rows } = await pool.query(
      `UPDATE "Reports" SET "Status" = $1, "ReviewedOn" = NOW() WHERE "ReportId" = $2 RETURNING *`,
      [body.Status, id],
    );
    if (!rows[0]) throw new NotFoundException('Report not found');
    return rows[0];
  }

  @Patch('stories/:id')
  async publishStory(@Param('id') id: string, @Body() body: any, @Query('tenantDbName') tenantDbName?: string) {
    if (typeof body?.IsPublished !== 'boolean') throw new NotFoundException('IsPublished must be boolean');
    const dbName = tenantDbName || (await this.tenantDbName());
    if (!dbName) throw new NotFoundException('No tenant DB');
    const pool = this.tenantDb.getDb(dbName);
    const { rows } = await pool.query(
      `UPDATE "SuccessStories" SET "IsPublished" = $1 WHERE "StoryId" = $2 RETURNING *`,
      [body.IsPublished, id],
    );
    if (!rows[0]) throw new NotFoundException('Story not found');
    return rows[0];
  }
}

import { Controller, Get, Headers, Param } from '@nestjs/common';
import { TenantDbService } from './tenant-db.service';

// Public success stories — published only, no auth required.
@Controller('site/stories')
export class SiteStoriesController {
  constructor(private tenantDb: TenantDbService) {}

  @Get(':tenantDbName')
  async stories(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query(
      `SELECT s."StoryId", s."Testimonial", s."PhotoUrl", s."MarriageDate",
              u1."FirstName" AS "FirstName1", u2."FirstName" AS "FirstName2"
       FROM "SuccessStories" s
       JOIN "Users" u1 ON u1."UserId" = s."UserId1"
       JOIN "Users" u2 ON u2."UserId" = s."UserId2"
       WHERE s."IsPublished" = TRUE
       ORDER BY s."CreatedOn" DESC`,
    );
    return { stories: rows };
  }
}

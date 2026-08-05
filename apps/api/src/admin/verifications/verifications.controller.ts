import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TenantDbService } from '../../site/tenant-db.service';

// Admin review queue for tenant verification requests.
// VerificationRequests live in TENANT databases; the admin DB's Tenants
// table holds each tenant's DatabaseName, so we resolve and query through
// TenantDbService. Query param ?tenantDbName=... overrides (used when the
// tenant row is missing its DatabaseName).
@Controller('admin/verifications')
export class VerificationsController {
  constructor(
    private db: PrismaService,
    private tenantDb: TenantDbService,
  ) {}

  @Get()
  async list(@Query('tenantDbName') tenantDbName?: string) {
    const dbName = tenantDbName || (await this.firstExistingTenantDb());
    if (!dbName) return [];
    const pool = this.tenantDb.getDb(dbName);
    try {
      const { rows } = await pool.query(
        `SELECT vr."VerificationId", vr."UserId", vr."DocType", vr."DocReference",
                vr."Status", vr."CreatedOn", u."FirstName", u."Phone"
         FROM "VerificationRequests" vr
         JOIN "Users" u ON u."UserId" = vr."UserId"
         ORDER BY vr."CreatedOn" DESC`,
      );
      return rows;
    } catch {
      return [];
    }
  }

  @Patch(':id')
  async review(@Param('id') id: string, @Body() body: any, @Query('tenantDbName') tenantDbName?: string) {
    if (!['approved', 'rejected'].includes(body.Status)) throw new NotFoundException('Invalid status');
    const dbName = tenantDbName || (await this.firstExistingTenantDb());
    if (!dbName) throw new NotFoundException('No tenant DB');
    const pool = this.tenantDb.getDb(dbName);
    const { rows } = await pool.query(
      `UPDATE "VerificationRequests" SET "Status" = $1, "ReviewedOn" = NOW()
       WHERE "VerificationId" = $2 RETURNING *`,
      [body.Status, id],
    );
    if (!rows[0]) throw new NotFoundException('Verification not found');
    return rows[0];
  }

  // First tenant whose DB actually exists — skip seeds that were never provisioned.
  private async firstExistingTenantDb(): Promise<string | null> {
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
}

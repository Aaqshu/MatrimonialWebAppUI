import { Controller, Get, Post, Param, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';
import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

const REPO_ROOT = path.resolve(__dirname, '../../../../..');
const MAINTENANCE_DB_URL = 'postgresql://postgres:postgres@localhost:5432/postgres';

@Controller('admin/provisioning')
export class ProvisioningController {
  constructor(private db: PrismaService) {}

  @Get(':tenantId')
  async getByTenant(@Param('tenantId') id: string) {
    const { rows } = await this.db.query('SELECT * FROM "TenantProvisioningLog" WHERE "TenantId" = $1 ORDER BY "CreatedOn" DESC', [id]);
    return rows;
  }

  @Post(':tenantId/run')
  async run(@Param('tenantId') tenantId: string) {
    const { rows } = await this.db.query('SELECT * FROM "Tenants" WHERE "TenantId" = $1', [tenantId]);
    const tenant = rows[0];
    if (!tenant) throw new NotFoundException('Tenant not found');

    const dbName = tenant.DatabaseName;
    const results: { step: string; status: 'success' | 'failed'; error?: string }[] = [];

    const dbCreated = await this.step(tenantId, 'create_database', async () => {
      const maintClient = new Client({ connectionString: MAINTENANCE_DB_URL });
      await maintClient.connect();
      try {
        await maintClient.query(`CREATE DATABASE "${dbName}"`);
      } catch (err: any) {
        if (err.code !== '42P04') throw err;
      } finally {
        await maintClient.end();
      }
    });
    results.push(dbCreated);

    if (dbCreated.status === 'success') {
      results.push(await this.step(tenantId, 'run_migrations', async () => {
        const tenantClient = new Client({ connectionString: `postgresql://postgres:postgres@localhost:5432/${dbName}` });
        await tenantClient.connect();
        try {
          const sql1 = fs.readFileSync(path.join(REPO_ROOT, 'packages/database/prisma/migrations/002_tenant_schema.sql'), 'utf-8');
          const sql2 = fs.readFileSync(path.join(REPO_ROOT, 'packages/database/prisma/migrations/003_feature_additions.sql'), 'utf-8');
          await tenantClient.query(sql1);
          await tenantClient.query(sql2);
        } finally {
          await tenantClient.end();
        }
      }));
    } else {
      await this.logStep(tenantId, 'run_migrations', 'failed', 'Skipped: database was not created');
      results.push({ step: 'run_migrations', status: 'failed', error: 'Skipped: database was not created' });
    }

    results.push(await this.step(tenantId, 'seed_theme', async () => {
      await this.db.query(
        `INSERT INTO "ThemeConfigs" ("TenantId","BusinessName","PrimaryColor","SecondaryColor","FontFamily")
         VALUES ($1,$2,$3,$4,$5) ON CONFLICT ("TenantId") DO NOTHING`,
        [tenantId, tenant.CompanyName, '#1D9E75', '#0F6E56', 'Inter']
      );
      await this.db.query(
        `INSERT INTO "FeatureFlags" ("TenantId","MatchingEnabled","VideoCallEnabled","KundliMatchingEnabled","MaxPhotosPerProfile")
         VALUES ($1,$2,$3,$4,$5) ON CONFLICT ("TenantId") DO NOTHING`,
        [tenantId, true, false, false, 6]
      );
    }));

    results.push(await this.step(tenantId, 'activate_tenant', async () => {
      await this.db.query('UPDATE "Tenants" SET "Status" = $1 WHERE "TenantId" = $2', ['active', tenantId]);
    }));

    return { tenantId, databaseName: dbName, results };
  }

  private async step(tenantId: string, name: string, fn: () => Promise<void>): Promise<{ step: string; status: 'success' | 'failed'; error?: string }> {
    try {
      await fn();
      await this.logStep(tenantId, name, 'success');
      return { step: name, status: 'success' };
    } catch (err: any) {
      await this.logStep(tenantId, name, 'failed', err.message);
      return { step: name, status: 'failed', error: err.message };
    }
  }

  private async logStep(tenantId: string, stepName: string, status: 'success' | 'failed', errorMessage?: string) {
    await this.db.query(
      `INSERT INTO "TenantProvisioningLog" ("ProvisioningLogId","TenantId","Step","Status","ErrorMessage") VALUES ($1,$2,$3,$4,$5)`,
      [uuid(), tenantId, stepName, status, errorMessage || null]
    );
  }
}

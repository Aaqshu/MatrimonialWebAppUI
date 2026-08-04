import { Controller, Get, Post, Patch, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';

@Controller('admin/subscriptions')
export class SubscriptionsController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query(
      `SELECT ts.*, t."CompanyName", t."TenantCode", sp."PlanName"
       FROM "TenantSubscriptions" ts
       JOIN "Tenants" t ON t."TenantId" = ts."TenantId"
       JOIN "SubscriptionPlans" sp ON sp."PlanId" = ts."PlanId"
       ORDER BY ts."CreatedOn" DESC`
    );
    return rows;
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const { rows } = await this.db.query(
      `INSERT INTO "TenantSubscriptions" ("TenantSubscriptionId","TenantId","PlanId","StartDate","EndDate","NextBillingDate","Amount","PaymentStatus","SubscriptionStatus")
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [id, body.TenantId, body.PlanId, body.StartDate, body.EndDate || null, body.NextBillingDate || null, body.Amount, body.PaymentStatus || 'pending', body.SubscriptionStatus || 'active']
    );
    return rows[0];
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined) {
        sets.push(`"${k}" = $${i++}`);
        vals.push(v);
      }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "TenantSubscriptions" SET ${sets.join(',')} WHERE "TenantSubscriptionId" = $${i} RETURNING *`, vals);
    return rows[0];
  }
}

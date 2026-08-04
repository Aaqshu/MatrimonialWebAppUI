import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';

@Controller('admin/plans')
export class PlansController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query('SELECT * FROM "SubscriptionPlans" ORDER BY "CreatedOn" DESC');
    return rows;
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const { rows } = await this.db.query(
      'INSERT INTO "SubscriptionPlans" ("PlanId","PlanName","Description","Price","BillingCycle") VALUES ($1,$2,$3,$4,$5) RETURNING *',
      [id, body.planName, body.description, body.price, body.billingCycle || 'monthly']
    );
    return rows[0];
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined) { sets.push(`"${k}" = $${i++}`); vals.push(v); }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "SubscriptionPlans" SET ${sets.join(',')} WHERE "PlanId" = $${i} RETURNING *`, vals);
    return rows[0];
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.db.query('DELETE FROM "SubscriptionPlans" WHERE "PlanId" = $1', [id]);
    return { deleted: true };
  }
}

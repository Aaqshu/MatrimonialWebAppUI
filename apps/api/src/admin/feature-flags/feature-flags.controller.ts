import { Controller, Get, Patch, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/feature-flags')
export class FeatureFlagsController {
  constructor(private db: PrismaService) {}

  @Get(':tenantId')
  async get(@Param('tenantId') id: string) {
    const { rows } = await this.db.query('SELECT * FROM "FeatureFlags" WHERE "TenantId" = $1', [id]);
    return rows[0] || null;
  }

  @Patch(':tenantId')
  async update(@Param('tenantId') id: string, @Body() body: any) {
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined) { sets.push(`"${k}" = $${i++}`); vals.push(v); }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "FeatureFlags" SET ${sets.join(',')} WHERE "TenantId" = $${i} RETURNING *`, vals);
    return rows[0];
  }
}

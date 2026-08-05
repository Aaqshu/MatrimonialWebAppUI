import { Controller, Get, Patch, Param, Body, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Controller('admin/theme-configs')
export class ThemeConfigsController {
  constructor(private db: PrismaService) {}

  @Get(':tenantId')
  async get(@Param('tenantId') id: string) {
    if (!UUID_RE.test(id)) throw new NotFoundException('Tenant not found');
    const { rows } = await this.db.query('SELECT * FROM "ThemeConfigs" WHERE "TenantId" = $1', [id]);
    return rows[0] || null;
  }

  @Patch(':tenantId')
  async update(@Param('tenantId') id: string, @Body() body: any) {
    if (!UUID_RE.test(id)) throw new NotFoundException('Tenant not found');
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined) { sets.push(`"${k}" = $${i++}`); vals.push(v); }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "ThemeConfigs" SET ${sets.join(',')} WHERE "TenantId" = $${i} RETURNING *`, vals);
    return rows[0];
  }
}

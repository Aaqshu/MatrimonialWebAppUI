import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';

@Controller('admin/tenants')
export class TenantsController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query('SELECT * FROM "Tenants" ORDER BY "CreatedOn" DESC');
    return rows;
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    const { rows } = await this.db.query('SELECT * FROM "Tenants" WHERE "TenantId" = $1', [id]);
    return rows[0] || null;
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const dbName = body.databaseName || `${body.tenantCode}_${(body.companyName || 'tenant').replace(/[^a-zA-Z0-9]/g, '').toLowerCase()}`;
    const { rows } = await this.db.query(
      `INSERT INTO "Tenants" ("TenantId","TenantCode","CompanyName","OwnerName","Email","Phone","City","State","Country","DatabaseName","DatabaseServer","ConnectionSecretRef","Status")
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
      [id, body.tenantCode, body.companyName, body.ownerName, body.email, body.phone, body.city, body.state, body.country || 'India', dbName, body.databaseServer || null, body.connectionSecretRef || null, 'active']
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
    const { rows } = await this.db.query(`UPDATE "Tenants" SET ${sets.join(',')} WHERE "TenantId" = $${i} RETURNING *`, vals);
    return rows[0];
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.db.query('DELETE FROM "Tenants" WHERE "TenantId" = $1', [id]);
    return { deleted: true };
  }
}

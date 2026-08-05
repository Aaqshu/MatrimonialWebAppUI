import { Controller, Get, Post, Patch, Delete, Param, Body, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Whitelist of updatable columns — body keys are used directly as SQL column names, so never trust them
const TENANT_COLUMNS = new Set([
  'TenantCode', 'CompanyName', 'OwnerName', 'Email', 'Phone', 'Address', 'City', 'State', 'Country',
  'ZipCode', 'CustomDomain', 'LogoUrl', 'DatabaseName', 'DatabaseServer', 'ConnectionSecretRef',
  'Status', 'IsActive',
]);

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
    if (!UUID_RE.test(id)) throw new NotFoundException('Tenant not found');
    const { rows } = await this.db.query('SELECT * FROM "Tenants" WHERE "TenantId" = $1', [id]);
    if (!rows.length) throw new NotFoundException('Tenant not found');
    return rows[0];
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const dbName = body.databaseName || `${body.tenantCode}_${(body.companyName || 'tenant').replace(/[^a-zA-Z0-9]/g, '').toLowerCase()}`;
    try {
      const { rows } = await this.db.query(
        `INSERT INTO "Tenants" ("TenantId","TenantCode","CompanyName","OwnerName","Email","Phone","City","State","Country","DatabaseName","DatabaseServer","ConnectionSecretRef","Status")
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
        [id, body.tenantCode, body.companyName, body.ownerName, body.email, body.phone, body.city, body.state, body.country || 'India', dbName, body.databaseServer || null, body.connectionSecretRef || null, 'active']
      );
      return rows[0];
    } catch (err: any) {
      if (err.code === '23505') throw new ConflictException('Tenant code already exists');
      throw err;
    }
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    if (!UUID_RE.test(id)) throw new NotFoundException('Tenant not found');
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined && TENANT_COLUMNS.has(k)) {
        sets.push(`"${k}" = $${i++}`);
        vals.push(v);
      }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "Tenants" SET ${sets.join(',')} WHERE "TenantId" = $${i} RETURNING *`, vals);
    if (!rows.length) throw new NotFoundException('Tenant not found');
    return rows[0];
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    if (!UUID_RE.test(id)) throw new NotFoundException('Tenant not found');
    const { rowCount } = await this.db.query('DELETE FROM "Tenants" WHERE "TenantId" = $1', [id]);
    if (!rowCount) throw new NotFoundException('Tenant not found');
    return { deleted: true };
  }
}

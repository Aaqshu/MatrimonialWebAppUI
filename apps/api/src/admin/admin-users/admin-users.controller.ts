import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';
import * as bcrypt from 'bcrypt';

const SAFE_COLUMNS = '"AdminId","AdminUserName","FirstName","LastName","Email","Phone","Role","IsActive","LastLogin","CreatedOn","UpdatedOn"';

@Controller('admin/admin-users')
export class AdminUsersController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query(`SELECT ${SAFE_COLUMNS} FROM "AdminUsers" ORDER BY "CreatedOn" DESC`);
    return rows;
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const hashed = await bcrypt.hash(body.Password, 10);
    const { rows } = await this.db.query(
      `INSERT INTO "AdminUsers" ("AdminId","AdminUserName","Password","FirstName","LastName","Email","Phone","Role","IsActive")
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING ${SAFE_COLUMNS}`,
      [id, body.AdminUserName, hashed, body.FirstName, body.LastName, body.Email, body.Phone, body.Role || 'support', body.IsActive ?? true]
    );
    return rows[0];
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const data = { ...body };
    if (data.Password) {
      data.Password = await bcrypt.hash(data.Password, 10);
    }
    const sets: string[] = [];
    const vals: any[] = [];
    let i = 1;
    for (const [k, v] of Object.entries(data)) {
      if (v !== undefined) {
        sets.push(`"${k}" = $${i++}`);
        vals.push(v);
      }
    }
    if (!sets.length) return null;
    vals.push(id);
    const { rows } = await this.db.query(`UPDATE "AdminUsers" SET ${sets.join(',')} WHERE "AdminId" = $${i} RETURNING ${SAFE_COLUMNS}`, vals);
    return rows[0];
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.db.query('DELETE FROM "AdminUsers" WHERE "AdminId" = $1', [id]);
    return { deleted: true };
  }
}

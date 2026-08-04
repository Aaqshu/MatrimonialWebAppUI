import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { randomUUID as uuid } from 'crypto';

@Controller('admin/email-templates')
export class TemplatesController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query('SELECT * FROM "EmailTemplates" ORDER BY "TemplateName"');
    return rows;
  }

  @Post()
  async create(@Body() body: any) {
    const id = uuid();
    const { rows } = await this.db.query(
      'INSERT INTO "EmailTemplates" ("TemplateId","TemplateName","Subject","Body") VALUES ($1,$2,$3,$4) RETURNING *',
      [id, body.templateName, body.subject, body.body]
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
    const { rows } = await this.db.query(`UPDATE "EmailTemplates" SET ${sets.join(',')} WHERE "TemplateId" = $${i} RETURNING *`, vals);
    return rows[0];
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.db.query('DELETE FROM "EmailTemplates" WHERE "TemplateId" = $1', [id]);
    return { deleted: true };
  }
}

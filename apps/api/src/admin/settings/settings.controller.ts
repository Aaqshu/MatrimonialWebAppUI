import { Controller, Get, Patch, Param, Body } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/settings')
export class SettingsController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query('SELECT * FROM "SystemSettings" ORDER BY "SettingKey"');
    return rows;
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const { rows } = await this.db.query(
      'UPDATE "SystemSettings" SET "SettingValue" = $1 WHERE "SettingId" = $2 RETURNING *',
      [body.settingValue, id]
    );
    return rows[0];
  }
}

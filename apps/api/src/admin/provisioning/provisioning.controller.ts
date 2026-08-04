import { Controller, Get, Param } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/provisioning')
export class ProvisioningController {
  constructor(private db: PrismaService) {}

  @Get(':tenantId')
  async getByTenant(@Param('tenantId') id: string) {
    const { rows } = await this.db.query('SELECT * FROM "TenantProvisioningLog" WHERE "TenantId" = $1 ORDER BY "CreatedOn" DESC', [id]);
    return rows;
  }
}

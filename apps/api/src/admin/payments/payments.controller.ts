import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/payments')
export class PaymentsController {
  constructor(private db: PrismaService) {}

  @Get()
  async getAll() {
    const { rows } = await this.db.query(
      `SELECT p.*, t."CompanyName", t."TenantCode"
       FROM "Payments" p
       JOIN "Tenants" t ON t."TenantId" = p."TenantId"
       ORDER BY p."PaidOn" DESC NULLS LAST`
    );
    return rows;
  }
}

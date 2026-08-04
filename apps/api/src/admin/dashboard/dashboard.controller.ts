import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/dashboard')
export class DashboardController {
  constructor(private db: PrismaService) {}

  @Get()
  async getStats() {
    const [t, p, pay] = await Promise.all([
      this.db.query('SELECT COUNT(*)::int as count FROM "Tenants"'),
      this.db.query('SELECT COUNT(*)::int as count FROM "SubscriptionPlans" WHERE "IsActive" = true'),
      this.db.query("SELECT COUNT(*)::int as count FROM \"Payments\" WHERE \"Status\" = 'success' AND \"PaidOn\" > NOW() - INTERVAL '7 days'"),
    ]);
    return {
      tenants: t.rows[0].count,
      activePlans: p.rows[0].count,
      recentPayments: pay.rows[0].count,
    };
  }
}

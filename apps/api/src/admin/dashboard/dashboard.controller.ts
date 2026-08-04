import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('admin/dashboard')
export class DashboardController {
  constructor(private db: PrismaService) {}

  @Get()
  async getStats() {
    const [t, p, pay, activeSubs, revenue, recentTenants, monthlySignups] = await Promise.all([
      this.db.query('SELECT COUNT(*)::int as count FROM "Tenants"'),
      this.db.query('SELECT COUNT(*)::int as count FROM "SubscriptionPlans" WHERE "IsActive" = true'),
      this.db.query("SELECT COUNT(*)::int as count FROM \"Payments\" WHERE \"Status\" = 'success' AND \"PaidOn\" > NOW() - INTERVAL '7 days'"),
      this.db.query("SELECT COUNT(*)::int as count FROM \"TenantSubscriptions\" WHERE \"SubscriptionStatus\" = 'active'"),
      this.db.query("SELECT COALESCE(SUM(\"Amount\"), 0)::float as total FROM \"TenantSubscriptions\" WHERE \"PaymentStatus\" = 'paid'"),
      this.db.query('SELECT * FROM "Tenants" ORDER BY "CreatedOn" DESC LIMIT 5'),
      this.db.query(`
        SELECT to_char(date_trunc('month', "CreatedOn"), 'YYYY-MM') as month, COUNT(*)::int as count
        FROM "Tenants"
        WHERE "CreatedOn" > NOW() - INTERVAL '6 months'
        GROUP BY 1
        ORDER BY 1
      `),
    ]);
    return {
      tenants: t.rows[0].count,
      activePlans: p.rows[0].count,
      recentPayments: pay.rows[0].count,
      activeSubscriptions: activeSubs.rows[0].count,
      totalRevenue: revenue.rows[0].total,
      recentTenants: recentTenants.rows,
      monthlySignups: monthlySignups.rows,
    };
  }
}

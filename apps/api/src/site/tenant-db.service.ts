import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

const TENANT_DB_HOST = process.env.TENANT_DATABASE_URL || 'postgresql://postgres:postgres@178.212.35.171:5432';

@Injectable()
export class TenantDbService implements OnModuleDestroy {
  private pools = new Map<string, Pool>();

  getDb(tenantDbName: string): Pool {
    let pool = this.pools.get(tenantDbName);
    if (!pool) {
      pool = new Pool({
        connectionString: `${TENANT_DB_HOST}/${tenantDbName}`,
      });
      this.pools.set(tenantDbName, pool);
    }
    return pool;
  }

  query(tenantDbName: string, text: string, params?: any[]) {
    return this.getDb(tenantDbName).query(text, params);
  }

  async onModuleDestroy() {
    await Promise.all([...this.pools.values()].map((pool) => pool.end()));
  }
}

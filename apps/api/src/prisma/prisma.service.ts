import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  pool: Pool;

  constructor() {
    this.pool = new Pool({
      connectionString: process.env.ADMIN_DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/matrimonial_admin',
    });
  }

  async onModuleInit() { await this.pool.connect().then(c => c.release()); }
  async onModuleDestroy() { await this.pool.end(); }

  query(text: string, params?: any[]) { return this.pool.query(text, params); }
}

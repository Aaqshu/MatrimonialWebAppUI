import { Controller, Get } from '@nestjs/common';
import { Public } from '../auth/public.decorator';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @Public()
  async check() {
    const db = await this.prisma.query('SELECT 1 as ok');
    return { status: 'ok', database: db.rows[0].ok === 1 };
  }
}

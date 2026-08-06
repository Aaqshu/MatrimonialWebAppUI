import { Controller, Get, Param, Post, Query, Res } from '@nestjs/common';
import { execFile } from 'child_process';
import { promisify } from 'util';
import { existsSync, mkdirSync, readdirSync, statSync, unlinkSync, createReadStream, writeFileSync } from 'fs';
import { join } from 'path';
import type { Response } from 'express';
import { PrismaService } from '../../prisma/prisma.service';

const execFileP = promisify(execFile);

const BACKUP_DIR = join(process.cwd(), 'backups');
const KEEP_MAX = 10;

if (!existsSync(BACKUP_DIR)) mkdirSync(BACKUP_DIR, { recursive: true });

// Admin DB backup + per-tenant DB backups via pg_dump inside the postgres container.
// Dumps are SQL (schema + data) so they restore with psql.
@Controller('admin/backups')
export class BackupsController {
  constructor(private db: PrismaService) {}

  private containerName = 'matrimonial_postgres';

  // When the API runs on the VPS, docker exec is local. When running from a
  // dev machine (tests), wrap via SSH so the dump still works.
  private async runDocker(args: string[]): Promise<{ stdout: string }> {
    const sshPrefix = process.env.BACKUP_SSH_PREFIX;
    if (sshPrefix) {
      const { stdout } = await execFileP('sh', ['-c', `${sshPrefix} docker ${args.map(a => `'${a.replace(/'/g, "'\\''")}'`).join(' ')}`], { maxBuffer: 512 * 1024 * 1024 });
      return { stdout };
    }
    return execFileP('docker', args, { maxBuffer: 512 * 1024 * 1024 });
  }

  private async dump(dbName: string): Promise<string> {
    const file = join(BACKUP_DIR, `${dbName}_${new Date().toISOString().replace(/[:.]/g, '-')}.sql`);
    // run pg_dump inside the container, write to a mounted path via stdout
    const { stdout } = await this.runDocker([
      'exec', this.containerName,
      'pg_dump', '-U', 'postgres', '--no-owner', '--no-privileges', dbName,
    ]);
    writeFileSync(file, stdout);
    return file;
  }

  @Post()
  async create(): Promise<{ backups: string[] }> {
    const created: string[] = [];

    // 1. admin DB
    try {
      const f = await this.dump('matrimonial_admin');
      created.push(join(BACKUP_DIR, f).split('/').pop()!);
    } catch (e: any) {
      console.error('admin dump failed:', e.message);
    }

    // 2. every tenant DB from the Tenants table
    const { rows } = await this.db.query(
      `SELECT "DatabaseName" FROM "Tenants" WHERE "DatabaseName" IS NOT NULL`,
    );
    for (const row of rows) {
      const dbName = row.DatabaseName;
      const exists = await this.db.query(
        `SELECT 1 FROM pg_database WHERE datname = $1`, [dbName],
      );
      if (!exists.rows[0]) continue; // tenant DB never provisioned
      try {
        const f = await this.dump(dbName);
        created.push(join(BACKUP_DIR, f).split('/').pop()!);
      } catch (e: any) {
        console.error(`dump ${dbName} failed:`, e.message);
      }
    }

    // prune old backups
    this.prune();

    return { backups: created };
  }

  @Get()
  list(): { backups: { name: string; size: number; modified: string }[] } {
    const backups = readdirSync(BACKUP_DIR)
      .filter(f => f.endsWith('.sql'))
      .map(f => {
        const st = statSync(join(BACKUP_DIR, f));
        return { name: f, size: st.size, modified: st.mtime.toISOString() };
      })
      .sort((a, b) => b.modified.localeCompare(a.modified));
    return { backups };
  }

  @Get(':file')
  download(@Param('file') file: string, @Res() res: Response) {
    const safe = join(BACKUP_DIR, file);
    if (!safe.startsWith(BACKUP_DIR) || !existsSync(safe)) {
      res.status(404).json({ message: 'Backup not found' });
      return;
    }
    res.setHeader('Content-Type', 'application/sql');
    res.setHeader('Content-Disposition', `attachment; filename="${file}"`);
    createReadStream(safe).pipe(res);
  }

  @Post(':file/delete')
  remove(@Param('file') file: string) {
    const safe = join(BACKUP_DIR, file);
    if (safe.startsWith(BACKUP_DIR) && existsSync(safe)) {
      unlinkSync(safe);
      return { deleted: true };
    }
    return { deleted: false };
  }

  private prune() {
    const files = readdirSync(BACKUP_DIR)
      .filter(f => f.endsWith('.sql'))
      .map(f => join(BACKUP_DIR, f))
      .sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
    for (const f of files.slice(KEEP_MAX)) unlinkSync(f);
  }
}

import { BadRequestException, Body, Controller, Delete, Get, Headers, Param, Patch, Post, UnauthorizedException, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid } from 'crypto';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { join, extname } from 'path';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const UPLOAD_DIR = join(process.cwd(), 'uploads');
if (!existsSync(UPLOAD_DIR)) mkdirSync(UPLOAD_DIR, { recursive: true });

const ALLOWED_EXT = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
const MAX_PHOTOS = 6;

@Public()
@Controller('site/photos')
export class SitePhotosController {
  constructor(
    private tenantDb: TenantDbService,
    private jwt: JwtService,
  ) {}

  private auth(headers: any): { sub: string; tenantDbName: string } {
    const authz: string = headers['authorization'] || '';
    if (!authz.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    try {
      return this.jwt.verify(authz.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  @Post(':tenantDbName')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: UPLOAD_DIR,
      filename: (_req, file, cb) => cb(null, `${uuid()}${extname(file.originalname)}`),
    }),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (_req, file, cb) => {
      if (!ALLOWED_EXT.includes(extname(file.originalname).toLowerCase())) {
        return cb(new BadRequestException('Only jpg/png/webp/gif allowed'), false);
      }
      cb(null, true);
    },
  }))
  async upload(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any, @UploadedFile() file: Express.Multer.File) {
    const { sub } = this.auth(headers);
    if (!file) throw new BadRequestException('file is required (multipart field "file")');
    const db = this.tenantDb.getDb(tenantDbName);

    const { rows: [{ count }] } = await db.query('SELECT COUNT(*)::int AS count FROM "UserPhotos" WHERE "UserId" = $1', [sub]);
    if (count >= MAX_PHOTOS) throw new BadRequestException(`Max ${MAX_PHOTOS} photos allowed`);

    const url = `${process.env.PUBLIC_BASE_URL || 'http://178.212.35.171:3001'}/uploads/${file.filename}`;
    const { rows } = await db.query(
      `INSERT INTO "UserPhotos" ("PhotoId","UserId","PhotoUrl","IsPrimary","DisplayOrder")
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [uuid(), sub, url, count === 0, count],
    );
    return { photo: rows[0] };
  }

  @Get(':tenantDbName')
  async list(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query('SELECT * FROM "UserPhotos" WHERE "UserId" = $1 ORDER BY "DisplayOrder"', [sub]);
    return { photos: rows };
  }

  @Patch(':tenantDbName/:photoId')
  async setPrimary(@Param('tenantDbName') tenantDbName: string, @Param('photoId') photoId: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const owned = (await db.query('SELECT 1 FROM "UserPhotos" WHERE "PhotoId" = $1 AND "UserId" = $2', [photoId, sub])).rows[0];
    if (!owned) throw new BadRequestException('Photo not found');

    if (body.isPrimary) {
      await db.query('UPDATE "UserPhotos" SET "IsPrimary" = FALSE WHERE "UserId" = $1', [sub]);
      await db.query('UPDATE "UserPhotos" SET "IsPrimary" = TRUE WHERE "PhotoId" = $1', [photoId]);
    }
    const { rows } = await db.query('SELECT * FROM "UserPhotos" WHERE "UserId" = $1 ORDER BY "DisplayOrder"', [sub]);
    return { photos: rows };
  }

  @Delete(':tenantDbName/:photoId')
  async remove(@Param('tenantDbName') tenantDbName: string, @Param('photoId') photoId: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);
    const owned = (await db.query('SELECT * FROM "UserPhotos" WHERE "PhotoId" = $1 AND "UserId" = $2', [photoId, sub])).rows[0];
    if (!owned) throw new BadRequestException('Photo not found');

    await db.query('DELETE FROM "UserPhotos" WHERE "PhotoId" = $1', [photoId]);
    // if primary deleted, promote next
    if (owned.IsPrimary) {
      const { rows } = await db.query('SELECT "PhotoId" FROM "UserPhotos" WHERE "UserId" = $1 ORDER BY "DisplayOrder" LIMIT 1', [sub]);
      if (rows[0]) await db.query('UPDATE "UserPhotos" SET "IsPrimary" = TRUE WHERE "PhotoId" = $1', [rows[0].PhotoId]);
    }
    return { deleted: true };
  }
}

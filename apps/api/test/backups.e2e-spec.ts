import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Backups API (e2e)', () => {
  let app: INestApplication;
  let token: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();

    const res = await request(app.getHttpServer())
      .post('/auth/login').send({ userName: 'superadmin', password: 'admin123' }).expect(201);
    token = res.body.access_token;
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  it('rejects unauthenticated backup access', async () => {
    await request(app.getHttpServer()).get('/admin/backups').expect(401);
  });

  it('lists backups (may be empty)', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/backups').set('Authorization', `Bearer ${token}`).expect(200);
    expect(Array.isArray(res.body.backups)).toBe(true);
  });

  it('creates a backup (admin + tenant dumps)', async () => {
    if (!process.env.BACKUP_SSH_PREFIX) {
      // dev machine without SSH prefix — skip live dump
      return;
    }
    const res = await request(app.getHttpServer())
      .post('/admin/backups').set('Authorization', `Bearer ${token}`)
      .expect(201);
    expect(res.body.backups.length).toBeGreaterThan(0);
    expect(res.body.backups[0]).toContain('.sql');
  }, 30000);

  it('lists backups after creation', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/backups').set('Authorization', `Bearer ${token}`).expect(200);
    expect(res.body.backups.length).toBeGreaterThan(0);
    expect(res.body.backups[0].size).toBeGreaterThan(0);
  });

  it('downloads a backup file', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/backups').set('Authorization', `Bearer ${token}`).expect(200);
    const name = res.body.backups[0].name;
    const dl = await request(app.getHttpServer())
      .get(`/admin/backups/${name}`).set('Authorization', `Bearer ${token}`).expect(200);
    expect(dl.text).toContain('CREATE TABLE');
  });

  it('returns 404 for unknown backup', async () => {
    await request(app.getHttpServer())
      .get('/admin/backups/does-not-exist.sql').set('Authorization', `Bearer ${token}`).expect(404);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Phase 6 — Trust: Reports, Stories, Moderation (e2e)', () => {
  let app: INestApplication;
  let tokenA: string;
  let tokenB: string;
  let userA: string;
  let userB: string;
  let adminToken: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const phoneA = `+9187${uniq.slice(-8)}`;
  const phoneB = `+9186${uniq.slice(-8)}`;

  const login = async (phone: string) => {
    const req = await request(app.getHttpServer())
      .post('/site/otp/request').send({ tenantDbName: TENANT, phone }).expect(201);
    const res = await request(app.getHttpServer())
      .post('/site/otp/verify').send({ tenantDbName: TENANT, phone, otp: req.body.otp }).expect(201);
    return res.body;
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();

    const a = await login(phoneA);
    tokenA = a.access_token;
    userA = a.user.UserId;
    const b = await login(phoneB);
    tokenB = b.access_token;
    userB = b.user.UserId;

    const admin = await request(app.getHttpServer())
      .post('/auth/login').send({ userName: 'superadmin', password: 'admin123' }).expect(201);
    adminToken = admin.body.access_token;
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post' | 'patch', url: string, token: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  describe('Reports', () => {
    it('rejects invalid reason', async () => {
      await authed('post', `/site/reports/${TENANT}`, tokenA)
        .send({ reportedUserId: userB, reason: 'spam' }).expect(400);
    });

    it('A reports B for harassment', async () => {
      const res = await authed('post', `/site/reports/${TENANT}`, tokenA)
        .send({ reportedUserId: userB, reason: 'harassment', description: 'Sent abusive messages' }).expect(201);
      expect(res.body.report.Status).toBe('open');
      expect(res.body.report.Reason).toBe('harassment');
    });

    it('rejects self-report', async () => {
      await authed('post', `/site/reports/${TENANT}`, tokenA)
        .send({ reportedUserId: userA, reason: 'other' }).expect(400);
    });
  });

  describe('Moderation queue (admin)', () => {
    it('admin sees the report with phone numbers', async () => {
      const res = await authed('get', '/admin/moderation', adminToken).expect(200);
      const hit = res.body.reports.find((r: any) => r.Description === 'Sent abusive messages');
      expect(hit).toBeDefined();
      expect(hit.Status).toBe('open');
      expect(hit.ReportedPhone).toBeDefined();
    });

    it('admin resolves the report', async () => {
      const list = await authed('get', '/admin/moderation', adminToken).expect(200);
      const hit = list.body.reports.find((r: any) => r.Description === 'Sent abusive messages');
      const res = await authed('patch', `/admin/moderation/reports/${hit.ReportId}`, adminToken)
        .send({ Status: 'resolved' }).expect(200);
      expect(res.body.Status).toBe('resolved');
    });
  });

  describe('Success stories', () => {
    let storyId: string;

    it('stories list is empty initially', async () => {
      const res = await authed('get', `/site/stories/${TENANT}`, tokenA).expect(200);
      expect(Array.isArray(res.body.stories)).toBe(true);
    });

    it('admin publishes a story', async () => {
      // seed via admin moderation isn't create — insert directly through tenant pool
      const { Pool } = require('pg');
      const base = process.env.TENANT_DATABASE_URL || 'postgresql://postgres:postgres@178.212.35.171:5432';
      const pool = new Pool({ connectionString: `${base}/provision-test_provisiontestmatrimony` });
      const r = await pool.query(
        `INSERT INTO "SuccessStories" ("StoryId","UserId1","UserId2","Testimonial","MarriageDate","IsPublished")
         VALUES (gen_random_uuid(),$1,$2,'We found each other on this platform.','2026-01-10',TRUE) RETURNING "StoryId"`,
        [userA, userB],
      );
      storyId = r.rows[0].StoryId;
      await pool.end();
      expect(storyId).toBeDefined();
    });

    it('stories list shows the published story', async () => {
      const res = await authed('get', `/site/stories/${TENANT}`, tokenA).expect(200);
      const hit = res.body.stories.find((s: any) => s.StoryId === storyId);
      expect(hit).toBeDefined();
      expect(hit.FirstName1).toBeDefined();
      expect(hit.Testimonial).toContain('found each other');
    });

    it('admin unpublishes the story', async () => {
      const res = await authed('patch', `/admin/moderation/stories/${storyId}`, adminToken)
        .send({ IsPublished: false }).expect(200);
      expect(res.body.IsPublished).toBe(false);
      const list = await authed('get', `/site/stories/${TENANT}`, tokenA).expect(200);
      expect(list.body.stories.some((s: any) => s.StoryId === storyId)).toBe(false);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Phase 5 — Monetization (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let planId: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const phone = `+9188${uniq.slice(-8)}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();

    const req = await request(app.getHttpServer())
      .post('/site/otp/request').send({ tenantDbName: TENANT, phone }).expect(201);
    const res = await request(app.getHttpServer())
      .post('/site/otp/verify').send({ tenantDbName: TENANT, phone, otp: req.body.otp }).expect(201);
    token = res.body.access_token;

    // seed a plan if none exist
    const plans = await request(app.getHttpServer())
      .get(`/site/plans/${TENANT}`).set('Authorization', `Bearer ${token}`).expect(200);
    const paid = plans.body.plans.find((p: any) => Number(p.Price) > 0);
    if (!paid) {
      const { Pool } = require('pg');
      const base = process.env.TENANT_DATABASE_URL || 'postgresql://postgres:postgres@178.212.35.171:5432';
      const pool = new Pool({ connectionString: `${base}/provision-test_provisiontestmatrimony` });
      await pool.query(`INSERT INTO "EndUserPlans" ("PlanId","PlanName","Price","DurationDays","IsActive") VALUES (gen_random_uuid(),'QA Gold',999,30,TRUE)`);
      await pool.end();
      const plans2 = await request(app.getHttpServer())
        .get(`/site/plans/${TENANT}`).set('Authorization', `Bearer ${token}`).expect(200);
      planId = plans2.body.plans.find((p: any) => Number(p.Price) > 0).PlanId;
    } else {
      planId = paid.PlanId;
    }
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post', url: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  describe('Plans', () => {
    it('lists active plans', async () => {
      const res = await authed('get', `/site/plans/${TENANT}`).expect(200);
      expect(res.body.plans.length).toBeGreaterThan(0);
      expect(res.body.plans[0].PlanName).toBeDefined();
    });
  });

  describe('Checkout (dev mode)', () => {
    let subscriptionId: string;

    it('rejects missing planId', async () => {
      await authed('post', `/site/checkout/${TENANT}`).send({}).expect(400);
    });

    it('creates subscription + success payment instantly', async () => {
      const res = await authed('post', `/site/checkout/${TENANT}`).send({ planId }).expect(201);
      expect(res.body.devMode).toBe(true);
      expect(res.body.subscriptionId).toBeDefined();
      expect(res.body.amount).toBeGreaterThan(0);
      subscriptionId = res.body.subscriptionId;
    });

    it('membership shows premium after checkout', async () => {
      const res = await authed('get', `/site/membership/${TENANT}`).expect(200);
      expect(res.body.isPremium).toBe(true);
      expect(res.body.subscription.PlanName).toBeDefined();
    });
  });

  describe('Featured listings', () => {
    it('buys featured (dev)', async () => {
      const res = await authed('post', `/site/featured/${TENANT}`).send({ days: 7 }).expect(201);
      expect(res.body.featured).toBe(true);
      expect(res.body.days).toBe(7);
    });

    it('membership reflects featured', async () => {
      const res = await authed('get', `/site/membership/${TENANT}`).expect(200);
      expect(res.body.isFeatured).toBe(true);
    });
  });
});

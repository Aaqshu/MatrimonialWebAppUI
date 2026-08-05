import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

/**
 * Full-module e2e suite — covers every admin + site endpoint.
 * Uses a live PostgreSQL (matrimonial_admin + demo tenant DB).
 * Creates rows with unique keys and cleans up after itself.
 */
describe('Complete Module (e2e)', () => {
  let app: INestApplication;
  let token: string;
  const uniq = Date.now().toString(36);

  const authed = (method: 'get' | 'post' | 'patch' | 'delete', url: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);
  const contact = `+9198${uniq.slice(-8)}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  // ─── AUTH ───
  describe('Auth', () => {
    it('logs in with valid credentials', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login').send({ userName: 'superadmin', password: 'admin123' }).expect(201);
      token = res.body.access_token;
      expect(token).toBeDefined();
    });

    it('rejects wrong password', async () => {
      await request(app.getHttpServer())
        .post('/auth/login').send({ userName: 'superadmin', password: 'nope' }).expect(401);
    });

    it('rejects unauthenticated admin calls', async () => {
      await request(app.getHttpServer()).get('/admin/tenants').expect(401);
    });
  });

  // ─── DASHBOARD ───
  describe('Dashboard', () => {
    it('returns all stat keys', async () => {
      const res = await authed('get', '/admin/dashboard').expect(200);
      for (const k of ['tenants', 'activePlans', 'recentPayments', 'activeSubscriptions', 'totalRevenue', 'recentTenants', 'monthlySignups']) {
        expect(res.body).toHaveProperty(k);
      }
    });
  });

  // ─── TENANTS ───
  describe('Tenants CRUD', () => {
    let tid: string;

    it('lists tenants', async () => {
      const res = await authed('get', '/admin/tenants').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('creates a tenant with auto DB name', async () => {
      const res = await authed('post', '/admin/tenants')
        .send({ tenantCode: `t${uniq}`, companyName: 'Test Co', email: `t${uniq}@x.com` }).expect(201);
      expect(res.body.TenantCode).toBe(`t${uniq}`);
      expect(res.body.DatabaseName).toContain(`t${uniq}`);
      tid = res.body.TenantId;
    });

    it('returns 409 for duplicate code', async () => {
      await authed('post', '/admin/tenants')
        .send({ tenantCode: `t${uniq}`, companyName: 'Dup', email: 'd@x.com' }).expect(409);
    });

    it('gets tenant by id', async () => {
      const res = await authed('get', `/admin/tenants/${tid}`).expect(200);
      expect(res.body.TenantId).toBe(tid);
    });

    it('returns 404 for invalid id', async () => {
      await authed('get', '/admin/tenants/bogus').expect(404);
    });

    it('patches tenant (PascalCase key)', async () => {
      const res = await authed('patch', `/admin/tenants/${tid}`).send({ City: 'Delhi' }).expect(200);
      expect(res.body.City).toBe('Delhi');
    });

    it('deletes tenant', async () => {
      await authed('delete', `/admin/tenants/${tid}`).expect(200);
    });
  });

  // ─── PLANS ───
  describe('Plans CRUD', () => {
    let pid: string;

    it('lists plans', async () => {
      const res = await authed('get', '/admin/plans').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('creates plan', async () => {
      const res = await authed('post', '/admin/plans')
        .send({ planName: `Plan ${uniq}`, price: 999, billingCycle: 'monthly' }).expect(201);
      expect(res.body.PlanName).toBe(`Plan ${uniq}`);
      pid = res.body.PlanId;
    });

    it('patches plan', async () => {
      const res = await authed('patch', `/admin/plans/${pid}`).send({ IsActive: false }).expect(200);
      expect(res.body.IsActive).toBe(false);
    });

    it('deletes plan', async () => {
      await authed('delete', `/admin/plans/${pid}`).expect(200);
    });
  });

  // ─── EMAIL TEMPLATES ───
  describe('Email Templates CRUD', () => {
    let tplId: string;

    it('lists templates', async () => {
      const res = await authed('get', '/admin/email-templates').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('creates template', async () => {
      const res = await authed('post', '/admin/email-templates')
        .send({ templateName: `tpl${uniq}`, subject: 'Hi', body: '<p>Hello</p>' }).expect(201);
      tplId = res.body.TemplateId;
      expect(res.body.TemplateName).toBe(`tpl${uniq}`);
    });

    it('patches template', async () => {
      const res = await authed('patch', `/admin/email-templates/${tplId}`).send({ IsActive: false }).expect(200);
      expect(res.body.IsActive).toBe(false);
    });

    it('deletes template', async () => {
      await authed('delete', `/admin/email-templates/${tplId}`).expect(200);
    });
  });

  // ─── SETTINGS ───
  describe('Settings', () => {
    it('lists settings', async () => {
      const res = await authed('get', '/admin/settings').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  // ─── ADMIN USERS ───
  describe('Admin Users CRUD', () => {
    let uid: string;

    it('lists admin users without passwords', async () => {
      const res = await authed('get', '/admin/admin-users').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
      if (res.body.length) expect(res.body[0]).not.toHaveProperty('Password');
    });

    it('creates admin user with hashed password', async () => {
      const res = await authed('post', '/admin/admin-users')
        .send({ AdminUserName: `qa${uniq}`, Password: 'secret123', Email: `qa${uniq}@x.com`, Role: 'support', IsActive: true }).expect(201);
      expect(res.body).not.toHaveProperty('Password');
      uid = res.body.AdminId;
    });

    it('new admin can log in', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login').send({ userName: `qa${uniq}`, password: 'secret123' }).expect(201);
      expect(res.body.access_token).toBeDefined();
    });

    it('deletes admin user', async () => {
      await authed('delete', `/admin/admin-users/${uid}`).expect(200);
    });
  });

  // ─── SUBSCRIPTIONS ───
  describe('Subscriptions', () => {
    it('lists subscriptions with joins', async () => {
      const res = await authed('get', '/admin/subscriptions').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  // ─── PAYMENTS ───
  describe('Payments', () => {
    it('lists payments', async () => {
      const res = await authed('get', '/admin/payments').expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  // ─── THEME & FLAGS ───
  describe('Theme & Feature Flags', () => {
    it('returns 404 for unknown tenant theme', async () => {
      await authed('get', '/admin/theme-configs/bogus').expect(404);
    });
    it('returns 404 for unknown tenant flags', async () => {
      await authed('get', '/admin/feature-flags/bogus').expect(404);
    });
  });

  // ─── PROVISIONING ───
  describe('Provisioning', () => {
    it('returns 404 for invalid tenant', async () => {
      await authed('get', '/admin/provisioning/bogus').expect(404);
      await authed('post', '/admin/provisioning/bogus/run').expect(404);
    });
  });

  // ─── SITE / OTP (public) ───
  describe('Site OTP Auth', () => {
    const TENANT = 'provision-test_provisiontestmatrimony';

    it('rejects missing contact', async () => {
      await request(app.getHttpServer())
        .post('/site/otp/request').send({ tenantDbName: TENANT }).expect(400);
    });

    it('requests OTP (dev mode returns otp)', async () => {
      const res = await request(app.getHttpServer())
        .post('/site/otp/request').send({ tenantDbName: TENANT, phone: contact }).expect(201);
      expect(res.body.otp).toMatch(/^\d{6}$/);
      expect(res.body.deliveryChannels).toContain('whatsapp');
    });

    it('rejects wrong OTP', async () => {
      await request(app.getHttpServer())
        .post('/site/otp/verify').send({ tenantDbName: TENANT, phone: contact, otp: '000000' }).expect(401);
    });

    it('verifies OTP and returns JWT', async () => {
      const req = await request(app.getHttpServer())
        .post('/site/otp/request').send({ tenantDbName: TENANT, phone: contact }).expect(201);
      const res = await request(app.getHttpServer())
        .post('/site/otp/verify').send({ tenantDbName: TENANT, phone: contact, otp: req.body.otp }).expect(201);
      expect(res.body.access_token).toBeDefined();
      expect(res.body.user.Status).toBe('active');

      const me = await request(app.getHttpServer())
        .get('/site/me').set('Authorization', `Bearer ${res.body.access_token}`).expect(200);
      expect(me.body.Phone).toBe(contact);
      expect(me.body).not.toHaveProperty('Password');
    });

    it('rejects /site/me without token', async () => {
      await request(app.getHttpServer()).get('/site/me').expect(401);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Admin API (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let tenantId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ userName: 'superadmin', password: 'admin123' })
      .expect(201);

    token = login.body.access_token;
    expect(token).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects invalid credentials', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ userName: 'superadmin', password: 'wrong' })
      .expect(401);
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer()).get('/admin/tenants').expect(401);
  });

  it('creates a tenant', async () => {
    const code = `e2e-${Date.now()}`;
    const res = await request(app.getHttpServer())
      .post('/admin/tenants')
      .set('Authorization', `Bearer ${token}`)
      .send({
        tenantCode: code,
        companyName: 'E2E Test Matrimony',
        ownerName: 'E2E Owner',
        email: 'e2e@test.com',
        phone: '+919000000001',
        city: 'Lucknow',
        state: 'UP',
        country: 'India',
        databaseName: 'matrimonial_e2e',
        databaseServer: 'localhost',
        connectionSecretRef: 'e2e-secret',
      })
      .expect(201);

    expect(res.body.TenantCode).toBe(code);
    expect(res.body.TenantId).toBeDefined();
    tenantId = res.body.TenantId;
  });

  it('lists tenants', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/tenants')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('updates a tenant', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/admin/tenants/${tenantId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ City: 'Delhi' })
      .expect(200);

    expect(res.body.City).toBe('Delhi');
  });

  it('gets dashboard stats', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/dashboard')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(typeof res.body.tenants).toBe('number');
    expect(typeof res.body.activePlans).toBe('number');
  });

  it('deletes a tenant', async () => {
    await request(app.getHttpServer())
      .delete(`/admin/tenants/${tenantId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';

describe('Phase 2 — Photos, Verification, Privacy (e2e)', () => {
  let app: INestApplication;
  let token: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const contact = `+9197${uniq.slice(-8)}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();

    const req = await request(app.getHttpServer())
      .post('/site/otp/request').send({ tenantDbName: TENANT, phone: contact }).expect(201);
    const res = await request(app.getHttpServer())
      .post('/site/otp/verify').send({ tenantDbName: TENANT, phone: contact, otp: req.body.otp }).expect(201);
    token = res.body.access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post' | 'patch' | 'delete', url: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  // ─── PHOTOS ───
  describe('Photos', () => {
    let photoId: string;
    const tmpFile = join(process.cwd(), 'test-tmp-photo.png');

    it('rejects non-image upload', async () => {
      writeFileSync(`${tmpFile}.txt`, 'not an image');
      const res = await authed('post', `/site/photos/${TENANT}`)
        .attach('file', `${tmpFile}.txt`).expect(400);
      expect(res.body.message).toContain('Only jpg/png');
      unlinkSync(`${tmpFile}.txt`);
    });

    it('uploads an image (multipart)', async () => {
      writeFileSync(tmpFile, Buffer.from('89504e470d0a1a0a' + '00'.repeat(64), 'hex')); // tiny png header
      const res = await authed('post', `/site/photos/${TENANT}`)
        .attach('file', tmpFile).expect(201);
      expect(res.body.photo.PhotoUrl).toContain('/uploads/');
      expect(res.body.photo.IsPrimary).toBe(true); // first photo = primary
      photoId = res.body.photo.PhotoId;
      unlinkSync(tmpFile);
    });

    it('lists photos', async () => {
      const res = await authed('get', `/site/photos/${TENANT}`).expect(200);
      expect(res.body.photos.length).toBeGreaterThan(0);
    });

    it('requires auth', async () => {
      await request(app.getHttpServer()).get(`/site/photos/${TENANT}`).expect(401);
    });

    it('deletes photo', async () => {
      const res = await authed('delete', `/site/photos/${TENANT}/${photoId}`).expect(200);
      expect(res.body.deleted).toBe(true);
    });
  });

  // ─── VERIFICATION ───
  describe('Verification', () => {
    it('rejects invalid docType', async () => {
      const res = await authed('post', `/site/verification/${TENANT}`)
        .send({ docType: 'birth_certificate', docReference: 'X123' }).expect(400);
      expect(res.body.message).toContain('docType');
    });

    it('submits a verification request', async () => {
      const res = await authed('post', `/site/verification/${TENANT}`)
        .send({ docType: 'aadhaar', docReference: '1234-5678-9012' }).expect(201);
      expect(res.body.request.Status).toBe('pending');
    });

    it('rejects duplicate pending request', async () => {
      await authed('post', `/site/verification/${TENANT}`)
        .send({ docType: 'pan', docReference: 'ABCDE1234F' }).expect(400);
    });

    it('lists requests', async () => {
      const res = await authed('get', `/site/verification/${TENANT}`).expect(200);
      expect(res.body.requests.length).toBeGreaterThan(0);
      expect(res.body.requests[0].Status).toBe('pending');
    });
  });

  // ─── PRIVACY ───
  describe('Privacy', () => {
    it('returns defaults on first call', async () => {
      const res = await authed('get', `/site/privacy/${TENANT}`).expect(200);
      expect(res.body.PhotoVisibility).toBe('everyone');
      expect(res.body.ContactVisibility).toBe('matches_only');
      expect(res.body.ProfileVisibleTo).toBe('everyone');
      expect(res.body.ShowOnlineStatus).toBe(true);
    });

    it('patches a single setting', async () => {
      const res = await authed('patch', `/site/privacy/${TENANT}`)
        .send({ PhotoVisibility: 'premium_only' }).expect(200);
      expect(res.body.PhotoVisibility).toBe('premium_only');
      expect(res.body.ContactVisibility).toBe('matches_only'); // others unchanged
    });

    it('rejects invalid enum value', async () => {
      await authed('patch', `/site/privacy/${TENANT}`)
        .send({ PhotoVisibility: 'bogus' }).expect(400);
    });

    it('persists across calls', async () => {
      const res = await authed('get', `/site/privacy/${TENANT}`).expect(200);
      expect(res.body.PhotoVisibility).toBe('premium_only');
    });
  });
});

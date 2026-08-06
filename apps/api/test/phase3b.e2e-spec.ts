import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Phase 3b — Suggestions, Viewers, Name sync (e2e)', () => {
  let app: INestApplication;
  let tokenA: string;
  let tokenB: string;
  let userA: string;
  let userB: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const phoneA = `+9194${uniq.slice(-8)}`;
  const phoneB = `+9193${uniq.slice(-8)}`;

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

    // B: full profile with name (female, opposite of A's male default is unknown — just make B female and A male)
    await request(app.getHttpServer())
      .post(`/site/profile/${TENANT}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({
        profile: {
          FirstName: 'Ayesha', LastName: 'Khan',
          Gender: 'female', DateOfBirth: '1996-04-10', Height: 5.4, Weight: 52,
          MaritalStatus: 'never_married', Religion: 'Muslim', Caste: 'Sunni', MotherTongue: 'Urdu',
        },
        location: { Country: 'India', State: 'UP', City: 'Lucknow' },
        preferences: { MinAge: 25, MaxAge: 33, Religion: ['Muslim'] },
      }).expect(201);

    // A: male profile with name
    await request(app.getHttpServer())
      .post(`/site/profile/${TENANT}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        profile: {
          FirstName: 'Ahmed', LastName: 'Ali',
          Gender: 'male', DateOfBirth: '1992-08-20', Height: 5.9, Weight: 75,
          MaritalStatus: 'never_married', Religion: 'Muslim', Caste: 'Sunni', MotherTongue: 'Urdu',
        },
        location: { Country: 'India', State: 'UP', City: 'Lucknow' },
        preferences: { MinAge: 23, MaxAge: 30, Religion: ['Muslim'], City: 'Lucknow' },
      }).expect(201);
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post', url: string, token: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  describe('FirstName sync', () => {
    it('Users.FirstName updated from profile', async () => {
      const me = await authed('get', '/site/me', tokenB).expect(200);
      expect(me.body.FirstName).toBe('Ayesha');
    });
  });

  describe('Suggestions', () => {
    it('returns scored opposite-gender suggestions', async () => {
      const res = await authed('get', `/site/suggestions/${TENANT}`, tokenA).expect(200);
      expect(res.body.suggestions.length).toBeGreaterThan(0);
      for (const s of res.body.suggestions) {
        expect(s.Gender).toBe('female');
        expect(s.MatchPercent).toBeGreaterThan(0);
      }
    });

    it('excludes self from suggestions', async () => {
      const res = await authed('get', `/site/suggestions/${TENANT}`, tokenA).expect(200);
      expect(res.body.suggestions.some((s: any) => s.UserId === userA)).toBe(false);
    });
  });

  describe('Viewers', () => {
    it('B sees A in viewers after A viewed B', async () => {
      // A views B's public profile → records ProfileViews
      await authed('get', `/site/profile/${TENANT}/${userB}`, tokenA).expect(200);
      const res = await authed('get', `/site/viewers/${TENANT}`, tokenB).expect(200);
      expect(res.body.viewers.length).toBeGreaterThan(0);
      expect(res.body.viewers[0].FirstName).toBe('Ahmed');
    });
  });
});

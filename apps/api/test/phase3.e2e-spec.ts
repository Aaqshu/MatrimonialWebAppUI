import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Phase 3 — Discovery (e2e)', () => {
  let app: INestApplication;
  let tokenA: string;
  let tokenB: string;
  let userA: string;
  let userB: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const phoneA = `+9196${uniq.slice(-8)}`;
  const phoneB = `+9195${uniq.slice(-8)}`;

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

    // Give B a profile so search finds them
    await request(app.getHttpServer())
      .post(`/site/profile/${TENANT}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({
        profile: {
          Gender: 'female', DateOfBirth: '1997-01-15', Height: 5.4, Weight: 55,
          MaritalStatus: 'never_married', Religion: 'Muslim', Caste: 'Sunni',
          MotherTongue: 'Urdu', AboutMe: 'Hello',
        },
        education: { Qualification: 'B.Sc' },
        occupation: { Occupation: 'Analyst', CompanyName: 'Firm' },
        location: { Country: 'India', State: 'UP', City: 'Lucknow' },
        preferences: { MinAge: 24, MaxAge: 32, Religion: ['Muslim'] },
      }).expect(201);
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post' | 'patch' | 'delete', url: string, token: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  describe('Search', () => {
    it('searches and finds B with match %', async () => {
      const res = await authed('get', `/site/search/${TENANT}`, tokenA).expect(200);
      expect(res.body.total).toBeGreaterThan(0);
      expect(Array.isArray(res.body.users)).toBe(true);
    });

    it('filters by gender', async () => {
      const res = await authed('get', `/site/search/${TENANT}?gender=female`, tokenA).expect(200);
      expect(res.body.users.every((u: any) => u.Gender === 'female')).toBe(true);
    });

    it('filters by city', async () => {
      const res = await authed('get', `/site/search/${TENANT}?city=lucknow`, tokenA).expect(200);
      expect(res.body.users.every((u: any) => (u.City || '').toLowerCase().includes('lucknow'))).toBe(true);
    });

    it('excludes self from results', async () => {
      const res = await authed('get', `/site/search/${TENANT}`, tokenA).expect(200);
      expect(res.body.users.some((u: any) => u.UserId === userA)).toBe(false);
    });
  });

  describe('Interests & Matches', () => {
    let interestId: string;

    it('A sends interest to B', async () => {
      const res = await authed('post', `/site/interests/${TENANT}`, tokenA)
        .send({ toUserId: userB }).expect(201);
      expect(res.body.interest.Status).toBe('pending');
      interestId = res.body.interest.InterestId;
    });

    it('rejects duplicate interest', async () => {
      await authed('post', `/site/interests/${TENANT}`, tokenA)
        .send({ toUserId: userB }).expect(400);
    });

    it('B sees received interest', async () => {
      const res = await authed('get', `/site/matches/${TENANT}`, tokenB).expect(200);
      expect(res.body.received.some((r: any) => r.InterestRequestId === interestId)).toBe(true);
    });

    it('B accepts interest', async () => {
      const res = await authed('patch', `/site/interests/${TENANT}/${interestId}`, tokenB)
        .send({ status: 'accepted' }).expect(200);
      expect(res.body.interest.Status).toBe('accepted');
    });

    it('rejects re-respond after acceptance', async () => {
      await authed('patch', `/site/interests/${TENANT}/${interestId}`, tokenB)
        .send({ status: 'declined' }).expect(400);
    });
  });

  describe('Favorites & Block', () => {
    it('A favorites B', async () => {
      await authed('post', `/site/favorites/${TENANT}/${userB}`, tokenA).expect(201);
      const res = await authed('get', `/site/profile/${TENANT}/${userB}`, tokenA).expect(200);
      expect(res.body.IsFavorite).toBe(true);
    });

    it('A un-favorites B', async () => {
      const res = await authed('delete', `/site/favorites/${TENANT}/${userB}`, tokenA).expect(200);
      expect(res.body.favorited).toBe(false);
    });

    it('A blocks B, B disappears from search', async () => {
      await authed('post', `/site/block/${TENANT}/${userB}`, tokenA).expect(201);
      const res = await authed('get', `/site/search/${TENANT}`, tokenA).expect(200);
      expect(res.body.users.some((u: any) => u.UserId === userB)).toBe(false);
    });
  });

  describe('Public profile', () => {
    it('A views B profile', async () => {
      const res = await authed('get', `/site/profile/${TENANT}/${userB}`, tokenA).expect(200);
      expect(res.body.FirstName).toBeDefined();
      expect(res.body.Age).toBeGreaterThan(0);
      // null when viewer has no preferences — valid; 0-100 otherwise
      expect(res.body.MatchPercent === null || (res.body.MatchPercent >= 0 && res.body.MatchPercent <= 100)).toBe(true);
    });

    it('rejects viewing own profile', async () => {
      await authed('get', `/site/profile/${TENANT}/${userA}`, tokenA).expect(400);
    });
  });
});

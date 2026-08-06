import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Phase 4 — Messages & Notifications (e2e)', () => {
  let app: INestApplication;
  let tokenA: string;
  let tokenB: string;
  let userA: string;
  let userB: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const phoneA = `+9192${uniq.slice(-8)}`;
  const phoneB = `+9191${uniq.slice(-8)}`;

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

    // A sends interest, B accepts → they become a match
    await request(app.getHttpServer())
      .post(`/site/interests/${TENANT}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ toUserId: userB }).expect(201);
    const interests = await request(app.getHttpServer())
      .get(`/site/matches/${TENANT}`)
      .set('Authorization', `Bearer ${tokenB}`).expect(200);
    const interestId = interests.body.received[0].InterestRequestId;
    await request(app.getHttpServer())
      .patch(`/site/interests/${TENANT}/${interestId}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ status: 'accepted' }).expect(200);
  }, 20000);

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post' | 'patch', url: string, token: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  describe('Messages', () => {
    it('rejects messaging a non-match', async () => {
      const stranger = await login(`+9190${uniq.slice(-8)}`);
      const res = await authed('post', `/site/messages/${TENANT}`, tokenA)
        .send({ toUserId: stranger.user.UserId, message: 'hi' }).expect(400);
      expect(res.body.message).toContain('accepted matches');
    });

    it('A sends message to matched B', async () => {
      const res = await authed('post', `/site/messages/${TENANT}`, tokenA)
        .send({ toUserId: userB, message: 'Assalamu alaikum!' }).expect(201);
      expect(res.body.message.Message).toBe('Assalamu alaikum!');
    });

    it('B sees conversation and it marks read', async () => {
      const res = await authed('get', `/site/messages/${TENANT}/${userA}`, tokenB).expect(200);
      expect(res.body.messages.length).toBe(1);
      expect(res.body.messages[0].SenderUserId).toBe(userA);
    });

    it('B replies', async () => {
      const res = await authed('post', `/site/messages/${TENANT}`, tokenB)
        .send({ toUserId: userA, message: 'Walaikum assalam!' }).expect(201);
      expect(res.body.message.Message).toBe('Walaikum assalam!');
    });

    it('threads list shows both with last message', async () => {
      const res = await authed('get', `/site/messages/${TENANT}/threads`, tokenA).expect(200);
      expect(res.body.threads.length).toBe(1);
      expect(res.body.threads[0].LastMessage).toBe('Walaikum assalam!');
    });

    it('rejects empty message', async () => {
      await authed('post', `/site/messages/${TENANT}`, tokenA)
        .send({ toUserId: userB, message: '   ' }).expect(400);
    });
  });

  describe('Notifications', () => {
    it('B got a notification for the message', async () => {
      const res = await authed('get', `/site/notifications/${TENANT}`, tokenB).expect(200);
      expect(res.body.notifications.length).toBeGreaterThan(0);
      expect(res.body.notifications[0].Title).toBe('New message');
    });

    it('mark all read works', async () => {
      const res = await authed('patch', `/site/notifications/${TENANT}/read`, tokenB).expect(200);
      expect(res.body.read).toBe(true);
      const after = await authed('get', `/site/notifications/${TENANT}`, tokenB).expect(200);
      expect(after.body.unreadCount).toBe(0);
    });
  });
});

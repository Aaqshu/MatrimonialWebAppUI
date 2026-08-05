import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Site Profile API (e2e)', () => {
  let app: INestApplication;
  let token: string;
  const TENANT = 'provision-test_provisiontestmatrimony';
  const uniq = Date.now().toString(36);
  const contact = `+9198${uniq.slice(-8)}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();

    // Register + login via OTP
    const req = await request(app.getHttpServer())
      .post('/site/otp/request').send({ tenantDbName: TENANT, phone: contact }).expect(201);
    const res = await request(app.getHttpServer())
      .post('/site/otp/verify').send({ tenantDbName: TENANT, phone: contact, otp: req.body.otp }).expect(201);
    token = res.body.access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  const authed = (method: 'get' | 'post' | 'patch', url: string) =>
    (request(app.getHttpServer()) as any)[method](url).set('Authorization', `Bearer ${token}`);

  it('rejects profile access without token', async () => {
    await request(app.getHttpServer()).get(`/site/profile/${TENANT}`).expect(401);
  });

  it('returns 404 before profile exists', async () => {
    await authed('get', `/site/profile/${TENANT}`).expect(404);
  });

  it('creates a profile', async () => {
    const res = await authed('post', `/site/profile/${TENANT}`).send({
      profile: {
        Gender: 'male', DateOfBirth: '1995-06-15', Height: 5.9, Weight: 72,
        MaritalStatus: 'never_married', Religion: 'Muslim', Caste: 'Sunni', Sect: 'Hanafi', MotherTongue: 'Urdu',
        BloodGroup: 'B+', AboutMe: 'Software engineer, family oriented.',
      },
      education: { Qualification: 'B.Tech', College: 'IIT', University: 'IIT Delhi', PassingYear: 2017, EducationType: 'Full-time' },
      occupation: { Occupation: 'Engineer', CompanyName: 'TechCorp', Designation: 'SDE', AnnualIncome: 1200000, WorkLocation: 'Lucknow' },
      family: { FamilyType: 'Joint', FamilyStatus: 'Middle class', FatherName: 'Ahmed', FatherOccupation: 'Business', MotherName: 'Fatima', MotherOccupation: 'Homemaker', Brothers: 1, Sisters: 2 },
      lifestyle: { Diet: 'non_vegetarian', Smoking: false, Drinking: false, Hobbies: 'Reading, cricket', LanguagesKnown: 'Hindi, English, Urdu' },
      location: { Country: 'India', State: 'UP', City: 'Lucknow', Address: '123 Main St', Pincode: '226001' },
      preferences: { MinAge: 22, MaxAge: 28, MinHeight: 5.2, MaxHeight: 6.1, Religion: ['Muslim'], Caste: ['Sunni'], Country: 'India', State: 'UP', City: 'Lucknow' },
    }).expect(201);
    expect(res.body.created).toBe(true);
  });

  it('returns full profile', async () => {
    const res = await authed('get', `/site/profile/${TENANT}`).expect(200);
    expect(res.body.profile.Gender).toBe('male');
    expect(res.body.profile.ProfileCompletionPercent).toBeGreaterThan(0);
    expect(res.body.education.Qualification).toBe('B.Tech');
    expect(res.body.occupation.CompanyName).toBe('TechCorp');
    expect(res.body.family.Brothers).toBe(1);
    expect(res.body.lifestyle.Diet).toBe('non_vegetarian');
    expect(res.body.location.City).toBe('Lucknow');
    expect(res.body.preferences.MinAge).toBe(22);
  });

  it('patches profile fields', async () => {
    const res = await authed('patch', `/site/profile/${TENANT}`).send({
      profile: { AboutMe: 'Updated about me text.' },
      lifestyle: { Hobbies: 'Reading, cricket, travel' },
    }).expect(200);
    expect(res.body.updated).toBe(true);
    const get = await authed('get', `/site/profile/${TENANT}`).expect(200);
    expect(get.body.profile.AboutMe).toBe('Updated about me text.');
    expect(get.body.lifestyle.Hobbies).toBe('Reading, cricket, travel');
  });

  it('gets preferences endpoint', async () => {
    const res = await authed('get', `/site/profile/${TENANT}/preferences`).expect(200);
    expect(res.body.MinAge).toBe(22);
    expect(res.body.Religion).toContain('Muslim');
  });

  it('validates required fields on create', async () => {
    const res = await request(app.getHttpServer())
      .post(`/site/profile/${TENANT}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ profile: { Height: 5.5 } }).expect(400);
    expect(res.body.message).toBe('Gender and DateOfBirth are required');
  });
});

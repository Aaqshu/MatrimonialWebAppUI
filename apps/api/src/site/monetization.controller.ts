import { BadRequestException, Body, Controller, Get, Headers, Param, Post, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID as uuid, randomBytes } from 'crypto';
import { Public } from '../auth/public.decorator';
import { TenantDbService } from './tenant-db.service';

const isDevMode = () => process.env.PAYMENTS_DEV_MODE !== 'false';

@Public()
@Controller('site')
export class SiteMonetizationController {
  constructor(
    private tenantDb: TenantDbService,
    private jwt: JwtService,
  ) {}

  private auth(headers: any): { sub: string } {
    const authz: string = headers['authorization'] || '';
    if (!authz.startsWith('Bearer ')) throw new UnauthorizedException('Missing bearer token');
    try {
      return this.jwt.verify(authz.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  // ── PLANS ──
  @Get('plans/:tenantDbName')
  async plans(@Param('tenantDbName') tenantDbName: string) {
    const db = this.tenantDb.getDb(tenantDbName);
    const { rows } = await db.query(
      `SELECT "PlanId","PlanName","Price","DurationDays","Features" FROM "EndUserPlans" WHERE "IsActive" = TRUE ORDER BY "Price"`,
    );
    return { plans: rows };
  }

  // ── CHECKOUT (dev mode: no Razorpay, returns mock order) ──
  @Post('checkout/:tenantDbName')
  async checkout(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const planId = body?.planId;
    if (!planId) throw new BadRequestException('planId required');
    const db = this.tenantDb.getDb(tenantDbName);

    const plan = (await db.query(
      `SELECT * FROM "EndUserPlans" WHERE "PlanId" = $1 AND "IsActive" = TRUE`,
      [planId],
    )).rows[0];
    if (!plan) throw new BadRequestException('Plan not found');

    // create subscription row (pending payment)
    const subId = uuid();
    const expiresOn = `NOW() + INTERVAL '${Number(plan.DurationDays)} days'`;
    await db.query(
      `INSERT INTO "EndUserSubscriptions" ("SubscriptionId","UserId","PlanId","Status","ExpiresOn")
       VALUES ($1,$2,$3,'active',${expiresOn})`,
      [subId, sub, planId],
    );

    if (isDevMode()) {
      // dev: instantly "pay" — mock provider ref
      const providerRef = `DEV_${randomBytes(8).toString('hex').toUpperCase()}`;
      await db.query(
        `INSERT INTO "EndUserPayments" ("PaymentId","UserId","SubscriptionId","Amount","Currency","Provider","ProviderRef","Status")
         VALUES ($1,$2,$3,$4,'INR','razorpay',$5,'success')`,
        [uuid(), sub, subId, plan.Price, providerRef],
      );
      return { orderId: null, subscriptionId: subId, devMode: true, amount: Number(plan.Price), plan: plan.PlanName };
    }

    // production: Razorpay order (needs keys in env)
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keyId || !keySecret) throw new BadRequestException('Razorpay not configured');
    const authz = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
    const res = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Basic ${authz}` },
      body: JSON.stringify({
        amount: Math.round(Number(plan.Price) * 100),
        currency: 'INR',
        receipt: subId,
        notes: { tenantDbName, planId },
      }),
    });
    const order = await res.json();
    return { orderId: order.id, subscriptionId: subId, keyId, amount: Number(plan.Price) };
  }

  // ── CONFIRM payment (production path; dev uses instant success above) ──
  @Post('payments/:tenantDbName/confirm')
  async confirmPayment(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const { subscriptionId, paymentId, signature } = body || {};
    if (!subscriptionId) throw new BadRequestException('subscriptionId required');
    const db = this.tenantDb.getDb(tenantDbName);

    // verify signature (production) — in dev accept anything with a paymentId
    if (!isDevMode()) {
      const secret = process.env.RAZORPAY_KEY_SECRET;
      const crypto = await import('crypto');
      const expected = crypto.createHmac('sha256', secret ?? '')
        .update(`${paymentId}|${subscriptionId}`).digest('hex');
      if (expected !== signature) throw new BadRequestException('Invalid signature');
    }

    const subRow = (await db.query(
      `SELECT s."SubscriptionId", s."PlanId", p."Price", p."PlanName"
       FROM "EndUserSubscriptions" s JOIN "EndUserPlans" p ON p."PlanId" = s."PlanId"
       WHERE s."SubscriptionId" = $1 AND s."UserId" = $2`,
      [subscriptionId, sub],
    )).rows[0];
    if (!subRow) throw new BadRequestException('Subscription not found');

    await db.query(
      `INSERT INTO "EndUserPayments" ("PaymentId","UserId","SubscriptionId","Amount","Currency","Provider","ProviderRef","Status")
       VALUES ($1,$2,$3,$4,'INR','razorpay',$5,'success')`,
      [uuid(), sub, subscriptionId, subRow.Price, paymentId ?? `DEV_${Date.now()}`],
    );
    return { success: true, plan: subRow.PlanName };
  }

  // ── MY SUBSCRIPTION + FEATURED STATUS ──
  @Get('membership/:tenantDbName')
  async membership(@Param('tenantDbName') tenantDbName: string, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const db = this.tenantDb.getDb(tenantDbName);

    const subRow = (await db.query(
      `SELECT s."SubscriptionId", s."Status", s."StartsOn", s."ExpiresOn", s."PaymentRef",
              p."PlanName", p."Price", p."DurationDays", p."Features"
       FROM "EndUserSubscriptions" s
       JOIN "EndUserPlans" p ON p."PlanId" = s."PlanId"
       WHERE s."UserId" = $1 AND s."Status" = 'active' AND s."ExpiresOn" > NOW()
       ORDER BY s."CreatedOn" DESC LIMIT 1`,
      [sub],
    )).rows[0];

    const featured = (await db.query(
      `SELECT 1 FROM "FeaturedListings" WHERE "UserId" = $1 AND "ExpiresOn" > NOW()`,
      [sub],
    )).rows[0];

    return { subscription: subRow ?? null, isPremium: !!subRow, isFeatured: !!featured };
  }

  // ── FEATURED LISTING (dev: free in dev mode) ──
  @Post('featured/:tenantDbName')
  async buyFeatured(@Param('tenantDbName') tenantDbName: string, @Body() body: any, @Headers() headers: any) {
    const { sub } = this.auth(headers);
    const days = Math.max(1, Math.min(30, Number(body?.days) || 7));
    const db = this.tenantDb.getDb(tenantDbName);

    const existing = (await db.query(
      `SELECT "FeaturedId" FROM "FeaturedListings" WHERE "UserId" = $1 AND "ExpiresOn" > NOW()`,
      [sub],
    )).rows[0];

    if (existing) {
      await db.query(
        `UPDATE "FeaturedListings" SET "ExpiresOn" = "ExpiresOn" + INTERVAL '${days} days' WHERE "FeaturedId" = $1`,
        [existing.FeaturedId],
      );
    } else {
      await db.query(
        `INSERT INTO "FeaturedListings" ("FeaturedId","UserId","StartsOn","ExpiresOn","PaymentRef")
         VALUES ($1,$2,NOW(),NOW() + INTERVAL '${days} days',$3)`,
        [uuid(), sub, isDevMode() ? `DEV_${Date.now()}` : null],
      );
    }
    return { featured: true, days };
  }
}

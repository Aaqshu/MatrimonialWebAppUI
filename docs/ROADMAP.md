# Feature Roadmap & Phase Guide

Based on `development-process.md` (12-week plan). Phase status reflects current progress.

## Phase 0 — Foundation ✅ DONE
- [x] Turborepo monorepo (Next.js + NestJS)
- [x] PostgreSQL migrations (admin, tenant template, feature additions, seed)
- [x] Tenant-resolution middleware (partially — tenant model exists, domain routing pending)
- [x] Docker Compose on VPS

## Phase 1 — Identity & tenant admin 🔨 IN PROGRESS
- [x] Admin login (JWT + bcrypt)
- [x] Admin panel: tenants, plans, email templates, settings
- [x] ThemeConfigs / FeatureFlags API
- [ ] OTP registration/login (MSG91)
- [ ] JWT session + UserSessions
- [ ] Tenant admin panel UI (theme/flag editing pages)
- [ ] GuardianDetails capture during signup

## Phase 2 — Profile & trust ⏳
- [ ] Multi-step profile builder (UserProfiles + related)
- [ ] Cloudinary photo upload + PhotosBlurredByDefault
- [ ] VerificationRequests + admin review queue
- [ ] IsBlueTickVerified badge logic
- [ ] PrivacySettings enforcement

## Phase 3 — Discovery & connection ⏳
- [ ] Search/filter (religion, caste, sect, city, education, occupation)
- [ ] Daily match suggestions (cron)
- [ ] InterestRequests + Matches (MatchPercentage)
- [ ] Favorites, ProfileViews
- [ ] FeaturedListings boost in ranking

## Phase 4 — Communication ⏳
- [ ] Messaging (Pusher/Ably)
- [ ] CallLogs + masked voice/video calling
- [ ] Notifications

## Phase 5 — Monetization ⏳
- [ ] EndUserPlans/Subscriptions/Payments (Razorpay)
- [ ] Paywall enforcement
- [ ] FeaturedListings purchase flow
- [ ] AssistedMatchmakingRequests + CuratedMatches admin workflow

## Phase 6 — Trust, safety & growth ⏳
- [ ] BlockedUsers, Reports + moderation queue
- [ ] SuccessStories submission + approval + display
- [ ] EmailTemplates + SystemSettings admin UI (EmailTemplates UI done ✅)

## Phase 7 — Hardening & launch ⏳
- [ ] Automated tenant provisioning (new tenant → new DB → schema → seed theme)
- [ ] Load testing
- [ ] Backup/restore verification per tenant DB
- [ ] Sentry + logging
- [ ] Soft launch

---

## Next recommended work items

1. **Tenant provisioning script** — when admin creates a tenant, auto: create tenant DB, run `002_tenant_schema.sql` + `003_feature_additions.sql`, insert ThemeConfigs + FeatureFlags rows, log steps in TenantProvisioningLog. Biggest remaining core piece.
2. **End-user OTP auth** (Phase 1) — MSG91 integration + Users/OTPRequests/UserSessions tables already exist.
3. **Theme/Feature flag admin UI** — wire existing API endpoints to tenant detail page.
4. **Tenant detail page** — view/edit a tenant's full record + provisioning status.

## Testing

```bash
# API e2e tests (8 tests)
cd apps/api && npx jest --config test/jest-e2e.json --runInBand

# Web production build check
cd apps/web && npm run build
```

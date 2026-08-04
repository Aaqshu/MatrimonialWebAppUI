# Matrimonial SaaS Platform — Documentation

Multi-tenant matrimonial SaaS platform. Admin panel + tenant websites (roadmap).

## Repo layout

```
MatrimonialWebAppUI/
├── apps/
│   ├── web/          # Next.js 16 admin panel (port 3100)
│   └── api/          # NestJS 11 backend API (port 3001)
├── packages/
│   └── database/     # PostgreSQL migrations + Prisma schema
├── docker-compose.yml
└── docs/             # this documentation
```

## Stack

- Frontend: Next.js 16 + Tailwind v4 + shadcn/ui (Base UI)
- Backend: NestJS 11, modular monolith, raw SQL via pg
- Database: PostgreSQL 16 (admin DB + one DB per tenant)
- Deploy: Ubuntu VPS (178.212.35.171), Docker (Postgres/Redis), PM2 (API + Web)
- Planned: MSG91 OTP, Pusher chat, Cloudinary, Razorpay, Sentry

## Live URLs

| Service | URL |
|---------|-----|
| Admin panel | http://178.212.35.171:3100 |
| API | http://178.212.35.171:3001 |
| DB web UI (Adminer) | http://178.212.35.171:8081 |
| Postgres | 178.212.35.171:5432 (postgres/postgres) |

Default admin login: `superadmin` / `admin123`

---

## Feature: Admin Authentication

- `POST /auth/login` — `{ userName, password }` → JWT (`access_token`, 24h)
- All `/admin/*` routes protected by JWT guard (`Authorization: Bearer <token>`)
- Passwords bcrypt-hashed. Seed admin: `superadmin` / `admin123`

## Feature: Dashboard

- `GET /admin/dashboard` — stats: total tenants, active plans, payments in last 7 days

## Feature: Tenants (multi-tenancy core)

- `GET /admin/tenants` — list all
- `GET /admin/tenants/:id` — one tenant
- `POST /admin/tenants` — create
- `PATCH /admin/tenants/:id` — update (partial)
- `DELETE /admin/tenants/:id` — delete

Form rules (per product decision):
- **DB Name** — auto-generated server-side as `tenantCode_companyname` (e.g. `shadi_shadimatrimony`). Not user input.
- **DB Server** — optional. Host where tenant's Postgres lives.
- **Secret Ref** — optional. Secrets Manager ARN / Vault path for tenant DB credentials (never raw passwords).

UI: Add Tenant dialog, toggle active (🟢/🔴), status badge.

## Feature: Subscription Plans (tenant billing tiers)

- `GET /admin/plans` · `POST /admin/plans` · `PATCH /admin/plans/:id` · `DELETE /admin/plans/:id`
- Fields: planName, description, price (₹), billingCycle (monthly/yearly), isActive
- UI: full CRUD — Add/Edit dialog, active switch, delete with confirm
- These are plans the PLATFORM sells to TENANTS (billing in admin DB). End-user plans live in tenant DB (`EndUserPlans`).

## Feature: Email Templates

- `GET /admin/email-templates` · `POST` · `PATCH /:id` · `DELETE /:id`
- Fields: templateName, subject, body (HTML), isActive
- UI: full CRUD — Add/Edit dialog with variable quick-insert chips
- Template variables: `{{FirstName}} {{LastName}} {{OTP}} {{VerificationLink}} {{LoginLink}} {{ProfileLink}} {{MatchPercentage}} {{SenderName}}`

## Feature: System Settings

- `GET /admin/settings` — list key/value pairs
- `PATCH /admin/settings/:id` — update value
- UI: inline edit per row

## Feature: Tenant Provisioning Logs (partial)

- `GET /admin/provisioning/:tenantId` — provisioning steps for a tenant (create_database, run_migrations, seed_theme, send_invite)

## Feature: Theme & Feature Flags (API ready, UI in roadmap)

- `GET/PATCH /admin/theme-configs/:tenantId` — per-tenant branding (colors, logo, fonts)
- `GET/PATCH /admin/feature-flags/:tenantId` — per-tenant toggles (matching, video call, kundli, max photos)

---

## Database

Three migration files (PostgreSQL 16):

| File | Contents |
|------|----------|
| `001_admin_schema.sql` | Admin DB: AdminUsers, Tenants, ThemeConfigs, FeatureFlags, SubscriptionPlans, TenantSubscriptions, Payments, EmailTemplates, SystemSettings, TenantProvisioningLog |
| `002_tenant_schema.sql` | Tenant DB template: Users, OTPRequests, UserSessions, UserProfiles, UserPhotos, UserEducation, UserOccupation, UserFamilyDetails, UserLifestyle, UserLocation, UserPreferences, VerificationRequests, InterestRequests, Matches, ProfileViews, Favorites, Messages, Notifications, BlockedUsers, Reports, EndUserPlans/Subscriptions/Payments |
| `003_feature_additions.sql` | Competitive additions: Sect, GuardianDetails, PrivacySettings, CallLogs, FeaturedListings, SuccessStories, AssistedMatchmakingRequests, CuratedMatches |
| `004_seed.sql` | Seed admin + demo tenant + theme + flags |

Conventions: UUID PKs, ENUM types, `set_updated_on()` trigger for UpdatedOn, JSONB for flexible fields.

## Deployment (VPS)

1. `git pull` on server (`/root/matrimonial`)
2. API: `cd apps/api && npm install && npm run build && pm2 restart matrimonial-api`
3. Web: `cd apps/web && npm install && npm run build && pm2 restart matrimonial-web`
4. DB: Postgres runs in Docker (`/root/matrimonial-deploy`), initdb scripts auto-create schema on fresh volume
5. PM2 auto-starts both apps (`pm2 save` done)

## Dev workflow (Hermes + Claude Code)

- `main` — production (auto-deployed)
- `feature/admin-*` — feature branches; tests must pass before merge
- API e2e tests: `cd apps/api && npx jest --config test/jest-e2e.json --runInBand` (8 tests)
- Web build check: `cd apps/web && npm run build`

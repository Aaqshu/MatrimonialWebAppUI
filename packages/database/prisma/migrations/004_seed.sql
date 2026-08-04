-- ============================================================================
-- SEED DATA   (PostgreSQL 16)
-- Sample admin user, one demo tenant, and its default theme + feature flags.
--
-- All four tables seeded here (AdminUsers, Tenants, ThemeConfigs,
-- FeatureFlags) live in the ADMIN database (see 001_admin_schema.sql) — run
-- this against that same connection, after 001_admin_schema.sql has been
-- applied. Fixed UUID literals are used (instead of gen_random_uuid()) so
-- the rows below can reference each other and re-running this file is a
-- no-op via ON CONFLICT DO NOTHING.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Sample admin user
-- Password is a placeholder bcrypt-shaped hash for local/dev use only —
-- replace with a real hash (e.g. via your app's bcrypt/argon2 lib) before
-- using this seed anywhere credentials matter.
-- ----------------------------------------------------------------------------
INSERT INTO "AdminUsers" (
    "AdminId", "AdminUserName", "Password", "FirstName", "LastName",
    "Email", "Phone", "Role", "IsActive"
) VALUES (
    'a0000000-0000-4000-8000-000000000001',
    'superadmin',
    '$2b$12$CwTycUXWue0Thq9StjUM0uJ8vJ8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    'Platform',
    'Owner',
    'admin@platform.local',
    '+911234567890',
    'super_admin',
    TRUE
)
ON CONFLICT ("AdminId") DO NOTHING;

-- ----------------------------------------------------------------------------
-- One demo tenant, created by the sample admin above
-- ----------------------------------------------------------------------------
INSERT INTO "Tenants" (
    "TenantId", "TenantCode", "CompanyName", "OwnerName", "Email", "Phone",
    "City", "State", "Country", "DatabaseName", "DatabaseServer",
    "ConnectionSecretRef", "Status", "IsActive", "CreatedBy"
) VALUES (
    'b0000000-0000-4000-8000-000000000001',
    'demotenant',
    'Demo Matrimony Pvt Ltd',
    'Demo Owner',
    'owner@demotenant.local',
    '+919876543210',
    'Mumbai',
    'Maharashtra',
    'India',
    'matrimonial_tenant_demotenant',
    'localhost',
    'secretsmanager://matrimonial/tenants/demotenant/db-credentials',
    'active',
    TRUE,
    'a0000000-0000-4000-8000-000000000001'
)
ON CONFLICT ("TenantId") DO NOTHING;

-- ----------------------------------------------------------------------------
-- Default theme for the demo tenant
-- ----------------------------------------------------------------------------
INSERT INTO "ThemeConfigs" (
    "TenantId", "BusinessName", "PrimaryColor", "SecondaryColor",
    "FontFamily", "Tagline", "ContactEmail", "ContactPhone"
) VALUES (
    'b0000000-0000-4000-8000-000000000001',
    'Demo Matrimony',
    '#1D9E75',
    '#0F6E56',
    'Inter',
    'Find your perfect match',
    'owner@demotenant.local',
    '+919876543210'
)
ON CONFLICT ("TenantId") DO NOTHING;

-- ----------------------------------------------------------------------------
-- Default feature flags for the demo tenant
-- ----------------------------------------------------------------------------
INSERT INTO "FeatureFlags" (
    "TenantId", "MatchingEnabled", "VideoCallEnabled", "KundliMatchingEnabled",
    "MaxPhotosPerProfile", "CustomFlags"
) VALUES (
    'b0000000-0000-4000-8000-000000000001',
    TRUE,
    FALSE,
    FALSE,
    6,
    '{}'::jsonb
)
ON CONFLICT ("TenantId") DO NOTHING;

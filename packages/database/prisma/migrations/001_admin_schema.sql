-- ============================================================================
-- DATABASE 1 — ADMIN / PLATFORM DB   (PostgreSQL 16)
-- Converted from 01_admin_db_mysql.sql (MySQL 8.0+).
-- One shared database, managed by the platform owner. Holds tenant records,
-- billing between platform and tenants, and platform-wide configuration.
-- Never put end-user or profile data here.
--
-- Runs against schema "public" of the admin database. No CREATE DATABASE /
-- USE statements — connect to the target admin database before running this.
-- gen_random_uuid() is built into PostgreSQL core as of v13, no extension
-- required on PG16.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ENUM types
-- CREATE TYPE has no native IF NOT EXISTS in PostgreSQL, so each type is
-- wrapped in a DO block that swallows the duplicate_object error, making
-- this script safely re-runnable.
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE admin_role AS ENUM ('super_admin','support');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE tenant_status AS ENUM ('provisioning','active','suspended','cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE billing_cycle AS ENUM ('monthly','yearly');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_payment_status AS ENUM ('pending','paid','failed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active','past_due','cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_txn_status AS ENUM ('pending','success','failed','refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE provisioning_status AS ENUM ('pending','success','failed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ----------------------------------------------------------------------------
-- Trigger function to emulate MySQL's TIMESTAMP ... ON UPDATE CURRENT_TIMESTAMP
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_on()
RETURNS TRIGGER AS $$
BEGIN
    NEW."UpdatedOn" = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 1. AdminUsers  (unchanged from original design)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "AdminUsers" (
    "AdminId"       UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "AdminUserName" VARCHAR(100)  NOT NULL UNIQUE,
    "Password"      VARCHAR(255)  NOT NULL,
    "FirstName"     VARCHAR(100),
    "LastName"      VARCHAR(100),
    "Email"         VARCHAR(200)  NOT NULL UNIQUE,
    "Phone"         VARCHAR(20),
    "Role"          admin_role    NOT NULL DEFAULT 'support',
    "IsActive"      BOOLEAN       NOT NULL DEFAULT TRUE,
    "LastLogin"     TIMESTAMPTZ,
    "CreatedOn"     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedOn"     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_adminusers_updated_on ON "AdminUsers";
CREATE TRIGGER trg_adminusers_updated_on
    BEFORE UPDATE ON "AdminUsers"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

-- ----------------------------------------------------------------------------
-- 2. Tenants  (original design + Slug/Status added; ConnectionString
--    replaced with a SECRET REFERENCE, not raw credentials — see note below)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "Tenants" (
    "TenantId"            UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "TenantCode"          VARCHAR(50)   NOT NULL UNIQUE,          -- e.g. "sharmamatrimony" -> subdomain
    "CompanyName"         VARCHAR(200)  NOT NULL,
    "OwnerName"           VARCHAR(150),
    "Email"               VARCHAR(200)  NOT NULL,
    "Phone"               VARCHAR(20),
    "Address"             VARCHAR(500),
    "City"                VARCHAR(100),
    "State"               VARCHAR(100),
    "Country"             VARCHAR(100)  DEFAULT 'India',
    "ZipCode"             VARCHAR(20),
    "CustomDomain"        VARCHAR(255)  UNIQUE,                   -- optional vanity domain, verified separately
    "LogoUrl"             VARCHAR(500),
    "DatabaseName"        VARCHAR(100)  NOT NULL,
    "DatabaseServer"      VARCHAR(200)  NOT NULL,
    -- SECURITY: do NOT store a raw connection string / password here.
    -- Store a reference (e.g. AWS Secrets Manager ARN / HashiCorp Vault path)
    -- and resolve the real credentials at runtime. A single leaked row in
    -- this table would otherwise expose every tenant's database.
    "ConnectionSecretRef" VARCHAR(500)  NOT NULL,
    "Status"              tenant_status NOT NULL DEFAULT 'provisioning',
    "IsActive"            BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedBy"           UUID,
    "CreatedOn"           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedOn"           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_tenants_createdby FOREIGN KEY ("CreatedBy") REFERENCES "AdminUsers"("AdminId")
);

DROP TRIGGER IF EXISTS trg_tenants_updated_on ON "Tenants";
CREATE TRIGGER trg_tenants_updated_on
    BEFORE UPDATE ON "Tenants"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

CREATE INDEX IF NOT EXISTS idx_tenants_code ON "Tenants"("TenantCode");
CREATE INDEX IF NOT EXISTS idx_tenants_status ON "Tenants"("Status");

-- ----------------------------------------------------------------------------
-- 2a. ThemeConfigs  (ADDED — needed for "on-demand theme/color/name changes")
--     Kept as its own table so branding updates never touch the Tenants row.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "ThemeConfigs" (
    "TenantId"       UUID          NOT NULL PRIMARY KEY,
    "BusinessName"   VARCHAR(150)  NOT NULL,
    "LogoUrl"        VARCHAR(500),
    "PrimaryColor"   VARCHAR(7)    NOT NULL DEFAULT '#1D9E75',
    "SecondaryColor" VARCHAR(7)    NOT NULL DEFAULT '#0F6E56',
    "FontFamily"     VARCHAR(100)  NOT NULL DEFAULT 'Inter',
    "Tagline"        VARCHAR(255),
    "ContactEmail"   VARCHAR(200),
    "ContactPhone"   VARCHAR(20),
    "UpdatedOn"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_theme_tenant FOREIGN KEY ("TenantId") REFERENCES "Tenants"("TenantId") ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_themeconfigs_updated_on ON "ThemeConfigs";
CREATE TRIGGER trg_themeconfigs_updated_on
    BEFORE UPDATE ON "ThemeConfigs"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

-- ----------------------------------------------------------------------------
-- 2b. FeatureFlags  (ADDED — per-tenant feature toggles)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "FeatureFlags" (
    "TenantId"              UUID       NOT NULL PRIMARY KEY,
    "MatchingEnabled"       BOOLEAN    NOT NULL DEFAULT TRUE,
    "VideoCallEnabled"      BOOLEAN    NOT NULL DEFAULT FALSE,
    "KundliMatchingEnabled" BOOLEAN    NOT NULL DEFAULT FALSE,
    "MaxPhotosPerProfile"   SMALLINT   NOT NULL DEFAULT 6,
    "CustomFlags"           JSONB,
    "UpdatedOn"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_flags_tenant FOREIGN KEY ("TenantId") REFERENCES "Tenants"("TenantId") ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_featureflags_updated_on ON "FeatureFlags";
CREATE TRIGGER trg_featureflags_updated_on
    BEFORE UPDATE ON "FeatureFlags"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

-- ----------------------------------------------------------------------------
-- 3. SubscriptionPlans  (original design, columns clarified)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "SubscriptionPlans" (
    "PlanId"       UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "PlanName"     VARCHAR(100)  NOT NULL,
    "Description"  VARCHAR(1000),
    "Price"        NUMERIC(10,2) NOT NULL,
    "BillingCycle" billing_cycle NOT NULL DEFAULT 'monthly',
    "IsActive"     BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedOn"    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. TenantSubscriptions  (original design)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "TenantSubscriptions" (
    "TenantSubscriptionId" UUID                        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "TenantId"              UUID                        NOT NULL,
    "PlanId"                UUID                        NOT NULL,
    "StartDate"             DATE                        NOT NULL,
    "EndDate"               DATE,
    "NextBillingDate"       DATE,
    "Amount"                NUMERIC(10,2)               NOT NULL,
    "PaymentStatus"         subscription_payment_status NOT NULL DEFAULT 'pending',
    "SubscriptionStatus"    subscription_status         NOT NULL DEFAULT 'active',
    "CreatedOn"             TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_tenantsub_tenant FOREIGN KEY ("TenantId") REFERENCES "Tenants"("TenantId") ON DELETE CASCADE,
    CONSTRAINT fk_tenantsub_plan FOREIGN KEY ("PlanId") REFERENCES "SubscriptionPlans"("PlanId")
);

CREATE INDEX IF NOT EXISTS idx_tenantsub_tenant ON "TenantSubscriptions"("TenantId");

-- ----------------------------------------------------------------------------
-- 5. Payments  (platform-level: tenant paying the platform owner)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "Payments" (
    "PaymentId"      UUID                NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "SubscriptionId" UUID                NOT NULL,
    "TenantId"       UUID                NOT NULL,
    "Amount"         NUMERIC(10,2)       NOT NULL,
    "Currency"       VARCHAR(3)          NOT NULL DEFAULT 'INR',
    "PaymentMethod"  VARCHAR(50),
    "TransactionId"  VARCHAR(255),
    "InvoiceNumber"  VARCHAR(100),
    "PaymentGateway" VARCHAR(50),                 -- razorpay | cashfree | stripe
    "Status"         payment_txn_status  NOT NULL DEFAULT 'pending',
    "PaidOn"         TIMESTAMPTZ,
    CONSTRAINT fk_payments_sub FOREIGN KEY ("SubscriptionId") REFERENCES "TenantSubscriptions"("TenantSubscriptionId"),
    CONSTRAINT fk_payments_tenant FOREIGN KEY ("TenantId") REFERENCES "Tenants"("TenantId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_payments_tenant ON "Payments"("TenantId");

-- ----------------------------------------------------------------------------
-- 6. EmailTemplates  (original design)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "EmailTemplates" (
    "TemplateId"   UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "TemplateName" VARCHAR(100)  NOT NULL UNIQUE,
    "Subject"      VARCHAR(255)  NOT NULL,
    "Body"         TEXT          NOT NULL,
    "IsActive"     BOOLEAN       NOT NULL DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 7. SystemSettings  (original design)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "SystemSettings" (
    "SettingId"    UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "SettingKey"   VARCHAR(100)  NOT NULL UNIQUE,
    "SettingValue" VARCHAR(1000)
);

-- ----------------------------------------------------------------------------
-- 8. TenantProvisioningLog  (ADDED — tracks automated onboarding steps:
--    create DB, run schema, seed theme, generate admin invite, etc.)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "TenantProvisioningLog" (
    "ProvisioningLogId" UUID                 NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "TenantId"           UUID                 NOT NULL,
    "Step"               VARCHAR(100)         NOT NULL,   -- create_database | run_migrations | seed_theme | send_invite
    "Status"             provisioning_status  NOT NULL DEFAULT 'pending',
    "ErrorMessage"       TEXT,
    "CreatedOn"          TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_provlog_tenant FOREIGN KEY ("TenantId") REFERENCES "Tenants"("TenantId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_provlog_tenant ON "TenantProvisioningLog"("TenantId");

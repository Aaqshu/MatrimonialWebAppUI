-- ============================================================================
-- MIGRATION: Competitive feature additions   (PostgreSQL 16)
-- Converted from 03_feature_additions_mysql.sql (MySQL 8.0+).
-- Adds to 002_tenant_schema.sql based on Shadi.com / MuslimMatrimony analysis.
-- Run AFTER the base tenant schema (002_tenant_schema.sql) is applied, against
-- the same per-tenant database.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ENUM types
-- ----------------------------------------------------------------------------
-- Shared by PrivacySettings.PhotoVisibility and PrivacySettings.ContactVisibility
DO $$ BEGIN
    CREATE TYPE visibility_scope AS ENUM ('everyone','matches_only','premium_only','nobody');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE profile_visible_to_type AS ENUM ('everyone','same_community','premium_only');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE call_type AS ENUM ('voice','video');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE call_status AS ENUM ('initiated','completed','missed','failed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE assisted_request_status AS ENUM ('open','in_progress','closed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Trigger function to emulate MySQL's TIMESTAMP ... ON UPDATE CURRENT_TIMESTAMP
-- (matches the definition created in 002_tenant_schema.sql; safe to re-run)
CREATE OR REPLACE FUNCTION set_updated_on()
RETURNS TRIGGER AS $$
BEGIN
    NEW."UpdatedOn" = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 1. Extend UserProfiles: sect, verified badge, blurred-photo preference
--    (MySQL's AFTER clause has no Postgres equivalent — column order is
--    irrelevant here, so it's dropped; ADD COLUMN IF NOT EXISTS keeps this
--    idempotent.)
-- ----------------------------------------------------------------------------
ALTER TABLE "UserProfiles"
    ADD COLUMN IF NOT EXISTS "Sect" VARCHAR(100),                                    -- e.g. Sunni, Shia — distinct from Caste
    ADD COLUMN IF NOT EXISTS "IsBlueTickVerified" BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS "PhotosBlurredByDefault" BOOLEAN NOT NULL DEFAULT FALSE;

-- ----------------------------------------------------------------------------
-- 2. GuardianDetails (Wali) — optional guardian linked to a profile
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "GuardianDetails" (
    "GuardianId"          UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"              UUID          NOT NULL UNIQUE,
    "FullName"            VARCHAR(150)  NOT NULL,
    "Relationship"        VARCHAR(50)   NOT NULL,      -- father | brother | uncle | other
    "Phone"               VARCHAR(20),
    "Email"               VARCHAR(200),
    "CanReceiveInterests" BOOLEAN       NOT NULL DEFAULT FALSE,   -- if true, interest notifications CC the guardian
    "CreatedOn"           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_guardian_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- 3. PrivacySettings — "Who Can See Me" granular control (MuslimMatrimony)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "PrivacySettings" (
    "UserId"           UUID                      NOT NULL PRIMARY KEY,
    "PhotoVisibility"  visibility_scope           NOT NULL DEFAULT 'everyone',
    "ContactVisibility" visibility_scope          NOT NULL DEFAULT 'matches_only',
    "ProfileVisibleTo" profile_visible_to_type     NOT NULL DEFAULT 'everyone',
    "ShowOnlineStatus" BOOLEAN                    NOT NULL DEFAULT TRUE,
    "UpdatedOn"        TIMESTAMPTZ                NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_privacy_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_privacysettings_updated_on ON "PrivacySettings";
CREATE TRIGGER trg_privacysettings_updated_on
    BEFORE UPDATE ON "PrivacySettings"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

-- ----------------------------------------------------------------------------
-- 4. CallLogs — masked voice/video calling (Shaadi.com: "connect without
--    revealing your number")
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "CallLogs" (
    "CallId"          UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "CallerUserId"    UUID         NOT NULL,
    "ReceiverUserId"  UUID         NOT NULL,
    "CallType"        call_type    NOT NULL,
    "ProviderCallRef" VARCHAR(255),           -- reference ID from Exotel/Twilio/similar masked-calling provider
    "DurationSeconds" INT DEFAULT 0,
    "Status"          call_status  NOT NULL DEFAULT 'initiated',
    "StartedOn"       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_calls_caller FOREIGN KEY ("CallerUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_calls_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_calls_receiver ON "CallLogs"("ReceiverUserId");

-- ----------------------------------------------------------------------------
-- 5. FeaturedListings — paid visibility boost, separate from subscription tier
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "FeaturedListings" (
    "FeaturedId" UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"     UUID         NOT NULL,
    "StartsOn"   TIMESTAMPTZ  NOT NULL,
    "ExpiresOn"  TIMESTAMPTZ  NOT NULL,
    "PaymentRef" VARCHAR(255),
    "CreatedOn"  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_featured_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_featured_active ON "FeaturedListings"("UserId", "ExpiresOn");

-- ----------------------------------------------------------------------------
-- 6. SuccessStories — social proof (Shaadi.com: "80 lakh success stories")
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "SuccessStories" (
    "StoryId"      UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId1"      UUID         NOT NULL,
    "UserId2"      UUID         NOT NULL,
    "Testimonial"  TEXT,
    "PhotoUrl"     VARCHAR(500),
    "MarriageDate" DATE,
    "IsPublished"  BOOLEAN      NOT NULL DEFAULT FALSE,   -- tenant admin approves before showing publicly
    "ApprovedBy"   UUID,
    "CreatedOn"    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_story_user1 FOREIGN KEY ("UserId1") REFERENCES "Users"("UserId"),
    CONSTRAINT fk_story_user2 FOREIGN KEY ("UserId2") REFERENCES "Users"("UserId"),
    CONSTRAINT fk_story_approver FOREIGN KEY ("ApprovedBy") REFERENCES "Users"("UserId")
);

-- ----------------------------------------------------------------------------
-- 7. AssistedMatchmakingRequests — human-curated matching tier
--    (Shadi.com: "Prime Assist" / "Prime Plus")
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "AssistedMatchmakingRequests" (
    "RequestId"       UUID                      NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"          UUID                      NOT NULL,
    "AssignedAdminId" UUID,               -- tenant staff member handling this request
    "Status"          assisted_request_status  NOT NULL DEFAULT 'open',
    "Notes"           TEXT,
    "CreatedOn"       TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_assisted_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_assisted_admin FOREIGN KEY ("AssignedAdminId") REFERENCES "Users"("UserId")
);

-- ----------------------------------------------------------------------------
-- 8. Curated match assignments made by tenant staff under an assisted request
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "CuratedMatches" (
    "CuratedMatchId"  UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "RequestId"       UUID          NOT NULL,
    "SuggestedUserId" UUID          NOT NULL,
    "CuratedBy"       UUID          NOT NULL,
    "Notes"           VARCHAR(500),
    "CreatedOn"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_curated_request FOREIGN KEY ("RequestId") REFERENCES "AssistedMatchmakingRequests"("RequestId") ON DELETE CASCADE,
    CONSTRAINT fk_curated_suggested FOREIGN KEY ("SuggestedUserId") REFERENCES "Users"("UserId"),
    CONSTRAINT fk_curated_by FOREIGN KEY ("CuratedBy") REFERENCES "Users"("UserId")
);

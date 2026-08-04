-- ============================================================================
-- DATABASE 2 — TENANT DB TEMPLATE   (PostgreSQL 16)
-- Converted from 02_tenant_db_mysql.sql (MySQL 8.0+).
-- One database per tenant, created fresh during provisioning. This exact
-- script is run once per new tenant against an empty database (or schema).
--
-- NOTE ON TenantId: the original design included TenantId as a column on
-- Users inside this database. Since isolation here is the database
-- boundary itself (separate DB per tenant), that column is intentionally
-- removed — keeping it would invite a query to filter by the wrong
-- tenant inside a database that's supposed to only ever contain one.
-- If you ever need to know which tenant a database belongs to (for an
-- ops script, say), look it up from Tenants.DatabaseName in the admin DB.
--
-- No CREATE DATABASE / USE statements — connect to the tenant's own
-- database (or schema) before running this template.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ENUM types
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('end_user','tenant_admin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('pending_verification','active','suspended');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE gender_type AS ENUM ('male','female','other');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE marital_status AS ENUM ('never_married','divorced','widowed','awaiting_divorce');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE profile_visibility AS ENUM ('public','hidden','premium_only');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Shared by UserProfiles.VerificationStatus and VerificationRequests.Status
DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('unverified','pending','verified','rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE diet_type AS ENUM ('vegetarian','non_vegetarian','eggetarian','vegan');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE doc_type AS ENUM ('aadhaar','pan','passport','driving_license');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE interest_status AS ENUM ('pending','accepted','declined');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE report_status AS ENUM ('open','reviewing','resolved','dismissed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE enduser_subscription_status AS ENUM ('active','expired','cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE enduser_payment_status AS ENUM ('pending','success','failed','refunded');
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

-- ============================================================================
-- AUTH
-- ============================================================================

-- 1. Users  (original design, minus TenantId; Password now nullable to
--    support OTP-only accounts; Role/Status added)
CREATE TABLE IF NOT EXISTS "Users" (
    "UserId"    UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserName"  VARCHAR(50)   UNIQUE,
    "FirstName" VARCHAR(100)  NOT NULL,
    "LastName"  VARCHAR(100),
    "Email"     VARCHAR(200)  UNIQUE,
    "Phone"     VARCHAR(20)   UNIQUE,
    "Password"  VARCHAR(255),                 -- nullable: OTP-only users may never set one
    "Role"      user_role     NOT NULL DEFAULT 'end_user',
    "Status"    user_status   NOT NULL DEFAULT 'pending_verification',
    "IsActive"  BOOLEAN       NOT NULL DEFAULT TRUE,
    "LastLogin" TIMESTAMPTZ,
    "CreatedOn" TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedOn" TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_phone_or_email CHECK ("Phone" IS NOT NULL OR "Email" IS NOT NULL)
);

DROP TRIGGER IF EXISTS trg_users_updated_on ON "Users";
CREATE TRIGGER trg_users_updated_on
    BEFORE UPDATE ON "Users"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

-- 2. OTPRequests  (ADDED — phone/OTP is the primary auth pattern for India)
CREATE TABLE IF NOT EXISTS "OTPRequests" (
    "OTPRequestId" UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"       UUID,
    "Phone"        VARCHAR(20)  NOT NULL,
    "OTPHash"      VARCHAR(255) NOT NULL,
    "IsVerified"   BOOLEAN      NOT NULL DEFAULT FALSE,
    "ExpiresOn"    TIMESTAMPTZ  NOT NULL,
    "CreatedOn"    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_otp_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_otp_phone ON "OTPRequests"("Phone");

-- 3. UserSessions  (original design)
CREATE TABLE IF NOT EXISTS "UserSessions" (
    "SessionId"    UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"       UUID          NOT NULL,
    "RefreshToken" VARCHAR(500)  NOT NULL,          -- store a HASH, not the raw token
    "DeviceName"   VARCHAR(200),
    "Browser"      VARCHAR(100),
    "IPAddress"    VARCHAR(50),
    "LoginTime"    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "LogoutTime"   TIMESTAMPTZ,
    CONSTRAINT fk_sessions_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON "UserSessions"("UserId");

-- ============================================================================
-- PROFILE
-- ============================================================================

-- 4. UserProfiles  (original design + Visibility/VerificationStatus added)
CREATE TABLE IF NOT EXISTS "UserProfiles" (
    "ProfileId"                UUID                 NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"                   UUID                 NOT NULL UNIQUE,
    "Gender"                   gender_type           NOT NULL,
    "DateOfBirth"              DATE                 NOT NULL,
    "Height"                   NUMERIC(5,2),
    "Weight"                   NUMERIC(5,2),
    "MaritalStatus"            marital_status        NOT NULL DEFAULT 'never_married',
    "Religion"                 VARCHAR(100),
    "Caste"                    VARCHAR(100),
    "SubCaste"                 VARCHAR(100),
    "MotherTongue"             VARCHAR(100),
    "BloodGroup"               VARCHAR(20),
    "AboutMe"                  TEXT,
    "ProfileCompletionPercent" SMALLINT             NOT NULL DEFAULT 0,
    "Visibility"               profile_visibility    NOT NULL DEFAULT 'public',
    "VerificationStatus"       verification_status   NOT NULL DEFAULT 'unverified',
    "CreatedOn"                TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    "UpdatedOn"                TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_profiles_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_userprofiles_updated_on ON "UserProfiles";
CREATE TRIGGER trg_userprofiles_updated_on
    BEFORE UPDATE ON "UserProfiles"
    FOR EACH ROW EXECUTE FUNCTION set_updated_on();

CREATE INDEX IF NOT EXISTS idx_profiles_search ON "UserProfiles"("Gender", "Religion", "MaritalStatus");
CREATE INDEX IF NOT EXISTS idx_profiles_visibility ON "UserProfiles"("Visibility");

-- 5. UserPhotos  (original design, IsApproved kept for moderation)
CREATE TABLE IF NOT EXISTS "UserPhotos" (
    "PhotoId"      UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"       UUID         NOT NULL,
    "PhotoUrl"     VARCHAR(500) NOT NULL,
    "IsPrimary"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "DisplayOrder" INT          NOT NULL DEFAULT 0,
    "IsApproved"   BOOLEAN      NOT NULL DEFAULT FALSE,
    "UploadedOn"   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_photos_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_photos_user ON "UserPhotos"("UserId");

-- 6. UserEducation  (original design)
CREATE TABLE IF NOT EXISTS "UserEducation" (
    "EducationId"   UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"        UUID         NOT NULL,
    "Qualification" VARCHAR(150),
    "College"       VARCHAR(200),
    "University"    VARCHAR(200),
    "PassingYear"   INT,
    "EducationType" VARCHAR(100),
    CONSTRAINT fk_education_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- 7. UserOccupation  (original design)
CREATE TABLE IF NOT EXISTS "UserOccupation" (
    "OccupationId" UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"       UUID          NOT NULL,
    "Occupation"   VARCHAR(150),
    "CompanyName"  VARCHAR(200),
    "Designation"  VARCHAR(150),
    "AnnualIncome" NUMERIC(18,2),
    "WorkLocation" VARCHAR(200),
    CONSTRAINT fk_occupation_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- 8. UserFamilyDetails  (original design)
CREATE TABLE IF NOT EXISTS "UserFamilyDetails" (
    "FamilyId"         UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"           UUID          NOT NULL,
    "FamilyType"       VARCHAR(50),
    "FamilyStatus"     VARCHAR(100),
    "FatherName"       VARCHAR(100),
    "FatherOccupation" VARCHAR(150),
    "MotherName"       VARCHAR(100),
    "MotherOccupation" VARCHAR(150),
    "Brothers"         INT DEFAULT 0,
    "Sisters"          INT DEFAULT 0,
    CONSTRAINT fk_family_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- 9. UserLifestyle  (original design)
CREATE TABLE IF NOT EXISTS "UserLifestyle" (
    "LifestyleId"    UUID       NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"         UUID       NOT NULL,
    "Diet"           diet_type,
    "Smoking"        BOOLEAN DEFAULT FALSE,
    "Drinking"       BOOLEAN DEFAULT FALSE,
    "Hobbies"        TEXT,
    "LanguagesKnown" VARCHAR(500),
    CONSTRAINT fk_lifestyle_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- 10. UserLocation  (original design)
CREATE TABLE IF NOT EXISTS "UserLocation" (
    "LocationId" UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"     UUID          NOT NULL,
    "Country"    VARCHAR(100)  DEFAULT 'India',
    "State"      VARCHAR(100),
    "City"       VARCHAR(100),
    "Address"    VARCHAR(500),
    "Pincode"    VARCHAR(20),
    CONSTRAINT fk_location_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_location_city ON "UserLocation"("City", "State");

-- 11. UserPreferences  (original design — partner search preferences)
CREATE TABLE IF NOT EXISTS "UserPreferences" (
    "PreferenceId" UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"       UUID          NOT NULL UNIQUE,
    "MinAge"       SMALLINT,
    "MaxAge"       SMALLINT,
    "MinHeight"    NUMERIC(5,2),
    "MaxHeight"    NUMERIC(5,2),
    "Religion"     JSONB,          -- array of acceptable values, e.g. ["Hindu","Jain"]
    "Caste"        JSONB,
    "Education"    JSONB,
    "Occupation"   JSONB,
    "Country"      VARCHAR(100),
    "State"        VARCHAR(100),
    "City"         VARCHAR(100),
    CONSTRAINT fk_preferences_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

-- 12. VerificationRequests  (ADDED — KYC/ID verification, trust is critical
--     for matrimonial platforms)
CREATE TABLE IF NOT EXISTS "VerificationRequests" (
    "VerificationId" UUID                 NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"          UUID                 NOT NULL,
    "DocType"         doc_type             NOT NULL,
    "DocReference"    VARCHAR(500)         NOT NULL,   -- encrypted reference to stored doc, never raw content
    "Status"          verification_status  NOT NULL DEFAULT 'pending',
    "ReviewedBy"      UUID,                -- Users.UserId of the tenant_admin who reviewed
    "ReviewedOn"      TIMESTAMPTZ,
    "CreatedOn"       TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_verification_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_verification_reviewer FOREIGN KEY ("ReviewedBy") REFERENCES "Users"("UserId")
);

CREATE INDEX IF NOT EXISTS idx_verification_status ON "VerificationRequests"("Status");

-- ============================================================================
-- MATCHING & DISCOVERY
-- ============================================================================

-- 13. InterestRequests  (original design)
CREATE TABLE IF NOT EXISTS "InterestRequests" (
    "InterestId"     UUID             NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "SenderUserId"   UUID             NOT NULL,
    "ReceiverUserId" UUID             NOT NULL,
    "Status"         interest_status  NOT NULL DEFAULT 'pending',
    "SentOn"         TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    "RespondedOn"    TIMESTAMPTZ,
    CONSTRAINT fk_interest_sender FOREIGN KEY ("SenderUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_interest_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT uq_interest_pair UNIQUE ("SenderUserId", "ReceiverUserId"),
    CONSTRAINT chk_interest_not_self CHECK ("SenderUserId" <> "ReceiverUserId")
);

CREATE INDEX IF NOT EXISTS idx_interest_receiver ON "InterestRequests"("ReceiverUserId", "Status");

-- 14. Matches  (original design — persisted match score, avoids recomputation)
CREATE TABLE IF NOT EXISTS "Matches" (
    "MatchId"         UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId1"         UUID          NOT NULL,
    "UserId2"         UUID          NOT NULL,
    "MatchPercentage" NUMERIC(5,2)  NOT NULL,
    "MatchedOn"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_matches_user1 FOREIGN KEY ("UserId1") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_matches_user2 FOREIGN KEY ("UserId2") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT uq_match_pair UNIQUE ("UserId1", "UserId2"),
    CONSTRAINT chk_match_not_self CHECK ("UserId1" <> "UserId2")
);

CREATE INDEX IF NOT EXISTS idx_matches_user1 ON "Matches"("UserId1");
CREATE INDEX IF NOT EXISTS idx_matches_user2 ON "Matches"("UserId2");

-- 15. ProfileViews  (original design — "who viewed me")
CREATE TABLE IF NOT EXISTS "ProfileViews" (
    "ViewId"       UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "ViewerUserId" UUID         NOT NULL,
    "ViewedUserId" UUID         NOT NULL,
    "ViewedOn"     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_views_viewer FOREIGN KEY ("ViewerUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_views_viewed FOREIGN KEY ("ViewedUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_views_viewed ON "ProfileViews"("ViewedUserId", "ViewedOn");

-- 16. Favorites  (original design — shortlist)
CREATE TABLE IF NOT EXISTS "Favorites" (
    "FavoriteId"     UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"         UUID         NOT NULL,
    "FavoriteUserId" UUID         NOT NULL,
    "CreatedOn"      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_favorites_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_favorites_target FOREIGN KEY ("FavoriteUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT uq_favorite_pair UNIQUE ("UserId", "FavoriteUserId")
);

-- ============================================================================
-- COMMUNICATION
-- ============================================================================

-- 17. Messages  (original design — direct sender/receiver model)
CREATE TABLE IF NOT EXISTS "Messages" (
    "MessageId"      UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "SenderUserId"   UUID         NOT NULL,
    "ReceiverUserId" UUID         NOT NULL,
    "Message"        TEXT         NOT NULL,
    "IsRead"         BOOLEAN      NOT NULL DEFAULT FALSE,
    "SentOn"         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_messages_sender FOREIGN KEY ("SenderUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_messages_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_messages_thread ON "Messages"("SenderUserId", "ReceiverUserId", "SentOn");

-- 18. Notifications  (original design)
CREATE TABLE IF NOT EXISTS "Notifications" (
    "NotificationId" UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"          UUID          NOT NULL,
    "Title"           VARCHAR(200)  NOT NULL,
    "Message"         TEXT,
    "IsRead"          BOOLEAN       NOT NULL DEFAULT FALSE,
    "CreatedOn"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_notifications_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON "Notifications"("UserId", "IsRead");

-- ============================================================================
-- SAFETY & TRUST
-- ============================================================================

-- 19. BlockedUsers  (ADDED — named in the original table list, not detailed)
CREATE TABLE IF NOT EXISTS "BlockedUsers" (
    "BlockId"       UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"        UUID         NOT NULL,   -- the user who blocked
    "BlockedUserId" UUID         NOT NULL,   -- the user being blocked
    "CreatedOn"     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_blocked_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_blocked_target FOREIGN KEY ("BlockedUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT uq_block_pair UNIQUE ("UserId", "BlockedUserId")
);

-- 20. Reports  (ADDED — named in the original table list, not detailed)
CREATE TABLE IF NOT EXISTS "Reports" (
    "ReportId"       UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "ReporterUserId" UUID          NOT NULL,
    "ReportedUserId" UUID          NOT NULL,
    "Reason"         VARCHAR(100)  NOT NULL,   -- fake_profile | harassment | inappropriate_content | other
    "Description"    TEXT,
    "Status"         report_status NOT NULL DEFAULT 'open',
    "ReviewedBy"     UUID,
    "ReviewedOn"     TIMESTAMPTZ,
    "CreatedOn"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_reports_reporter FOREIGN KEY ("ReporterUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_reports_reported FOREIGN KEY ("ReportedUserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_reports_reviewer FOREIGN KEY ("ReviewedBy") REFERENCES "Users"("UserId")
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON "Reports"("Status");

-- ============================================================================
-- MONETIZATION (end users paying the TENANT — distinct from Database 1's
-- Payments table, which is the tenant paying the PLATFORM)
-- ============================================================================

-- 21. EndUserPlans  (ADDED)
CREATE TABLE IF NOT EXISTS "EndUserPlans" (
    "PlanId"       UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "PlanName"     VARCHAR(100)  NOT NULL,
    "Price"        NUMERIC(10,2) NOT NULL,
    "DurationDays" INT           NOT NULL,
    "Features"     JSONB,
    "IsActive"     BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedOn"    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 22. EndUserSubscriptions  (ADDED)
CREATE TABLE IF NOT EXISTS "EndUserSubscriptions" (
    "SubscriptionId" UUID                          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"          UUID                          NOT NULL,
    "PlanId"          UUID                          NOT NULL,
    "Status"          enduser_subscription_status   NOT NULL DEFAULT 'active',
    "StartsOn"        TIMESTAMPTZ                   NOT NULL DEFAULT NOW(),
    "ExpiresOn"       TIMESTAMPTZ                   NOT NULL,
    "PaymentRef"      VARCHAR(255),           -- Razorpay/Cashfree payment ID
    "CreatedOn"       TIMESTAMPTZ                   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_endusersub_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE,
    CONSTRAINT fk_endusersub_plan FOREIGN KEY ("PlanId") REFERENCES "EndUserPlans"("PlanId")
);

CREATE INDEX IF NOT EXISTS idx_endusersub_user ON "EndUserSubscriptions"("UserId", "Status");

-- 23. EndUserPayments  (ADDED — distinct from Database 1's Payments)
CREATE TABLE IF NOT EXISTS "EndUserPayments" (
    "PaymentId"      UUID                    NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"          UUID                    NOT NULL,
    "SubscriptionId"  UUID,
    "Amount"          NUMERIC(10,2)           NOT NULL,
    "Currency"        VARCHAR(3)              NOT NULL DEFAULT 'INR',
    "Provider"        VARCHAR(30)             NOT NULL,   -- razorpay | cashfree
    "ProviderRef"     VARCHAR(255)            NOT NULL,
    "Status"          enduser_payment_status  NOT NULL DEFAULT 'pending',
    "CreatedOn"       TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_enduserpay_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId"),
    CONSTRAINT fk_enduserpay_sub FOREIGN KEY ("SubscriptionId") REFERENCES "EndUserSubscriptions"("SubscriptionId")
);

CREATE INDEX IF NOT EXISTS idx_enduserpay_user ON "EndUserPayments"("UserId");
CREATE INDEX IF NOT EXISTS idx_enduserpay_ref ON "EndUserPayments"("ProviderRef");

-- PrivacySettings — added for Phase 2 privacy controls (tenant DB)
CREATE TABLE IF NOT EXISTS "PrivacySettings" (
    "SettingId"              UUID    NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    "UserId"                 UUID    NOT NULL UNIQUE,
    "VisibleToLoggedIn"      BOOLEAN NOT NULL DEFAULT TRUE,
    "VisibleToVerified"      BOOLEAN NOT NULL DEFAULT TRUE,
    "PhotoBlurEnabled"       BOOLEAN NOT NULL DEFAULT TRUE,
    "ShowExactAge"           BOOLEAN NOT NULL DEFAULT TRUE,
    "HideProfileUntilActive" BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedOn"              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedOn"              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_privacy_user FOREIGN KEY ("UserId") REFERENCES "Users"("UserId") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_privacy_user ON "PrivacySettings"("UserId");

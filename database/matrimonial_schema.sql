-- ============================================================
-- Matrimonial Web App - Complete Database Schema
-- ============================================================

-- Users table (core authentication & basic info)
CREATE TABLE users (
    user_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    email           VARCHAR(255) NOT NULL UNIQUE,
    phone           VARCHAR(20) UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    gender          ENUM('male','female','other') NOT NULL,
    date_of_birth   DATE NOT NULL,
    profile_for     ENUM('self','son','daughter','brother','sister','relative','friend') NOT NULL DEFAULT 'self',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    email_verified_at TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_gender (gender),
    INDEX idx_active (is_active)
);

-- User profiles (detailed biographical info)
CREATE TABLE profiles (
    profile_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL UNIQUE,
    -- Basic info
    headline        VARCHAR(200),
    about_me        TEXT,
    mother_tongue   VARCHAR(50),
    marital_status  ENUM('never_married','divorced','widowed','separated','awaiting_divorce') DEFAULT 'never_married',
    height_cm       SMALLINT,
    weight_kg       SMALLINT,
    blood_group     VARCHAR(5),
    body_type       VARCHAR(50),
    complexion      VARCHAR(50),
    physical_status ENUM('normal','differently_abled') DEFAULT 'normal',
    -- Lifestyle
    diet            ENUM('vegetarian','non_vegetarian','eggetarian','vegan','occasionally_non_veg') DEFAULT 'non_vegetarian',
    smoking         ENUM('yes','no','occasionally') DEFAULT 'no',
    drinking        ENUM('yes','no','occasionally') DEFAULT 'no',
    hobbies         TEXT,
    interests       TEXT,
    -- Religion
    religion        VARCHAR(100),
    caste           VARCHAR(100),
    sub_caste       VARCHAR(100),
    gotra           VARCHAR(100),
    manglik         ENUM('yes','no','dont_know') DEFAULT 'dont_know',
    horoscope_match_required BOOLEAN DEFAULT FALSE,
    -- Location
    country         VARCHAR(100) NOT NULL,
    state           VARCHAR(100),
    city            VARCHAR(100),
    citizenship     VARCHAR(100),
    residing_since  YEAR,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_religion (religion),
    INDEX idx_city (city),
    INDEX idx_marital_status (marital_status),
    FULLTEXT idx_about (about_me)
);

-- Family details
CREATE TABLE family_details (
    family_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL UNIQUE,
    family_type     ENUM('joint','nuclear','extended') DEFAULT 'nuclear',
    family_values   ENUM('orthodox','traditional','moderate','liberal') DEFAULT 'moderate',
    family_status   ENUM('upper_class','upper_middle_class','middle_class','lower_middle_class') DEFAULT 'middle_class',
    father_name     VARCHAR(100),
    father_occupation VARCHAR(100),
    mother_name     VARCHAR(100),
    mother_occupation VARCHAR(100),
    brothers        TINYINT DEFAULT 0,
    sisters         TINYINT DEFAULT 0,
    brother_married TINYINT DEFAULT 0,
    sister_married  TINYINT DEFAULT 0,
    about_family    TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Education & Career
CREATE TABLE education_career (
    edu_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL UNIQUE,
    -- Education
    highest_education   VARCHAR(200),
    education_details   TEXT,
    college_name        VARCHAR(200),
    university          VARCHAR(200),
    -- Career
    employed_in         ENUM('government','private','business','self_employed','defense','not_working','student') DEFAULT 'private',
    occupation          VARCHAR(200),
    company_name        VARCHAR(200),
    job_title           VARCHAR(200),
    annual_income_currency VARCHAR(10) DEFAULT 'INR',
    annual_income_min   DECIMAL(12,2),
    annual_income_max   DECIMAL(12,2),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Photos (multiple per user)
CREATE TABLE photos (
    photo_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL,
    photo_url       VARCHAR(500) NOT NULL,
    thumbnail_url   VARCHAR(500),
    is_profile_photo BOOLEAN DEFAULT FALSE,
    is_visible_to_all BOOLEAN DEFAULT TRUE,
    is_approved     BOOLEAN DEFAULT FALSE,
    sort_order      TINYINT DEFAULT 0,
    uploaded_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_photos (user_id, is_profile_photo)
);

-- Partner Preferences (what user is looking for)
CREATE TABLE partner_preferences (
    preference_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id             BIGINT NOT NULL UNIQUE,
    age_min             TINYINT DEFAULT 21,
    age_max             TINYINT DEFAULT 35,
    height_min_cm       SMALLINT,
    height_max_cm       SMALLINT,
    marital_status      JSON,
    religion            JSON,
    caste               JSON,
    sub_caste           JSON,
    manglik             VARCHAR(20),
    mother_tongue       JSON,
    country             JSON,
    state               JSON,
    city                JSON,
    diet                JSON,
    smoking             JSON,
    drinking            JSON,
    education           JSON,
    occupation          JSON,
    employed_in         JSON,
    annual_income_min   DECIMAL(12,2),
    annual_income_max   DECIMAL(12,2),
    body_type           JSON,
    physical_status     JSON,
    description         TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Interest / Shortlist (user shows interest in another profile)
CREATE TABLE interests (
    interest_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
    from_user_id    BIGINT NOT NULL,
    to_user_id      BIGINT NOT NULL,
    status          ENUM('pending','accepted','rejected','cancelled') DEFAULT 'pending',
    message         TEXT,
    responded_at    TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY uk_interest_pair (from_user_id, to_user_id),
    INDEX idx_status (status),
    INDEX idx_to_user (to_user_id, status)
);

-- Shortlist / Bookmarks
CREATE TABLE shortlists (
    shortlist_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL,
    target_user_id  BIGINT NOT NULL,
    note            VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY uk_shortlist (user_id, target_user_id)
);

-- Matches (mutual acceptance -> match)
CREATE TABLE matches (
    match_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    user1_id        BIGINT NOT NULL,
    user2_id        BIGINT NOT NULL,
    matched_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active       BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user1_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY uk_match_pair (user1_id, user2_id),
    INDEX idx_active_matches (is_active)
);

-- Messages (between matched users)
CREATE TABLE messages (
    message_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    match_id        BIGINT NOT NULL,
    sender_id       BIGINT NOT NULL,
    message_text    TEXT NOT NULL,
    is_read         BOOLEAN DEFAULT FALSE,
    read_at         TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_match_messages (match_id, created_at),
    INDEX idx_unread (match_id, is_read, sender_id)
);

-- Notifications
CREATE TABLE notifications (
    notification_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT NOT NULL,
    type            ENUM('interest_received','interest_accepted','interest_rejected','new_match','new_message','profile_visit','birthday') NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT,
    related_user_id BIGINT,
    is_read         BOOLEAN DEFAULT FALSE,
    read_at         TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_notifications (user_id, is_read, created_at)
);

-- Profile Views (who viewed whom)
CREATE TABLE profile_views (
    view_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    viewer_id       BIGINT NOT NULL,
    viewed_user_id  BIGINT NOT NULL,
    viewed_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (viewer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (viewed_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_viewed (viewed_user_id, viewed_at)
);

-- Success Stories
CREATE TABLE success_stories (
    story_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    match_id        BIGINT NOT NULL UNIQUE,
    story_text      TEXT NOT NULL,
    is_approved     BOOLEAN DEFAULT FALSE,
    approved_by     BIGINT,
    wedding_date    DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    INDEX idx_approved (is_approved)
);

-- Admin users
CREATE TABLE admins (
    admin_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    username        VARCHAR(100) NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    role            ENUM('super_admin','moderator','support') DEFAULT 'moderator',
    is_active       BOOLEAN DEFAULT TRUE,
    last_login_at   TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert a sample admin
INSERT INTO admins (username, email, password_hash, role) VALUES
('admin', 'admin@matrimonial.com', '$2y$10$samplehash', 'super_admin');

--
-- PostgreSQL database dump
--

\restrict VJTR2ayyaoXgXV17Gv3GMVpJz9sa6BMittL6199lnLWAmPr3HwBmwyknjvGlioo

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: admin_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.admin_role AS ENUM (
    'super_admin',
    'support'
);


--
-- Name: billing_cycle; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.billing_cycle AS ENUM (
    'monthly',
    'yearly'
);


--
-- Name: payment_txn_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_txn_status AS ENUM (
    'pending',
    'success',
    'failed',
    'refunded'
);


--
-- Name: provisioning_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.provisioning_status AS ENUM (
    'pending',
    'success',
    'failed'
);


--
-- Name: subscription_payment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_payment_status AS ENUM (
    'pending',
    'paid',
    'failed'
);


--
-- Name: subscription_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_status AS ENUM (
    'active',
    'past_due',
    'cancelled'
);


--
-- Name: tenant_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tenant_status AS ENUM (
    'provisioning',
    'active',
    'suspended',
    'cancelled'
);


--
-- Name: set_updated_on(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_on() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW."UpdatedOn" = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AdminUsers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AdminUsers" (
    "AdminId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "AdminUserName" character varying(100) NOT NULL,
    "Password" character varying(255) NOT NULL,
    "FirstName" character varying(100),
    "LastName" character varying(100),
    "Email" character varying(200) NOT NULL,
    "Phone" character varying(20),
    "Role" public.admin_role DEFAULT 'support'::public.admin_role NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "LastLogin" timestamp with time zone,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: EmailTemplates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmailTemplates" (
    "TemplateId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "TemplateName" character varying(100) NOT NULL,
    "Subject" character varying(255) NOT NULL,
    "Body" text NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL
);


--
-- Name: FeatureFlags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."FeatureFlags" (
    "TenantId" uuid NOT NULL,
    "MatchingEnabled" boolean DEFAULT true NOT NULL,
    "VideoCallEnabled" boolean DEFAULT false NOT NULL,
    "KundliMatchingEnabled" boolean DEFAULT false NOT NULL,
    "MaxPhotosPerProfile" smallint DEFAULT 6 NOT NULL,
    "CustomFlags" jsonb,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: Payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Payments" (
    "PaymentId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "SubscriptionId" uuid NOT NULL,
    "TenantId" uuid NOT NULL,
    "Amount" numeric(10,2) NOT NULL,
    "Currency" character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    "PaymentMethod" character varying(50),
    "TransactionId" character varying(255),
    "InvoiceNumber" character varying(100),
    "PaymentGateway" character varying(50),
    "Status" public.payment_txn_status DEFAULT 'pending'::public.payment_txn_status NOT NULL,
    "PaidOn" timestamp with time zone
);


--
-- Name: SubscriptionPlans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SubscriptionPlans" (
    "PlanId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "PlanName" character varying(100) NOT NULL,
    "Description" character varying(1000),
    "Price" numeric(10,2) NOT NULL,
    "BillingCycle" public.billing_cycle DEFAULT 'monthly'::public.billing_cycle NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: SystemSettings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SystemSettings" (
    "SettingId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "SettingKey" character varying(100) NOT NULL,
    "SettingValue" character varying(1000)
);


--
-- Name: TenantProvisioningLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TenantProvisioningLog" (
    "ProvisioningLogId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "TenantId" uuid NOT NULL,
    "Step" character varying(100) NOT NULL,
    "Status" public.provisioning_status DEFAULT 'pending'::public.provisioning_status NOT NULL,
    "ErrorMessage" text,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TenantSubscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TenantSubscriptions" (
    "TenantSubscriptionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "TenantId" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "StartDate" date NOT NULL,
    "EndDate" date,
    "NextBillingDate" date,
    "Amount" numeric(10,2) NOT NULL,
    "PaymentStatus" public.subscription_payment_status DEFAULT 'pending'::public.subscription_payment_status NOT NULL,
    "SubscriptionStatus" public.subscription_status DEFAULT 'active'::public.subscription_status NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: Tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Tenants" (
    "TenantId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "TenantCode" character varying(50) NOT NULL,
    "CompanyName" character varying(200) NOT NULL,
    "OwnerName" character varying(150),
    "Email" character varying(200) NOT NULL,
    "Phone" character varying(20),
    "Address" character varying(500),
    "City" character varying(100),
    "State" character varying(100),
    "Country" character varying(100) DEFAULT 'India'::character varying,
    "ZipCode" character varying(20),
    "CustomDomain" character varying(255),
    "LogoUrl" character varying(500),
    "DatabaseName" character varying(100) NOT NULL,
    "DatabaseServer" character varying(200),
    "ConnectionSecretRef" character varying(500),
    "Status" public.tenant_status DEFAULT 'provisioning'::public.tenant_status NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedBy" uuid,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ThemeConfigs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ThemeConfigs" (
    "TenantId" uuid NOT NULL,
    "BusinessName" character varying(150) NOT NULL,
    "LogoUrl" character varying(500),
    "PrimaryColor" character varying(7) DEFAULT '#1D9E75'::character varying NOT NULL,
    "SecondaryColor" character varying(7) DEFAULT '#0F6E56'::character varying NOT NULL,
    "FontFamily" character varying(100) DEFAULT 'Inter'::character varying NOT NULL,
    "Tagline" character varying(255),
    "ContactEmail" character varying(200),
    "ContactPhone" character varying(20),
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Data for Name: AdminUsers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AdminUsers" ("AdminId", "AdminUserName", "Password", "FirstName", "LastName", "Email", "Phone", "Role", "IsActive", "LastLogin", "CreatedOn", "UpdatedOn") FROM stdin;
a0000000-0000-4000-8000-000000000001	superadmin	$2b$12$tPHD4wPNJgsLNH1UPXUO2.LYkFZNjkFQwakJNBx1BHhxv1aFdZ1IS	Platform	Owner	admin@platform.local	+911234567890	super_admin	t	\N	2026-08-06 09:47:10.633753+00	2026-08-06 09:47:11.969252+00
\.


--
-- Data for Name: EmailTemplates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EmailTemplates" ("TemplateId", "TemplateName", "Subject", "Body", "IsActive") FROM stdin;
590c92e8-2cf9-4507-abc0-0ce55f6b40bf	welcome_email	Welcome to {{PlatformName}}!	<h2>Assalamu Alaikum {{FirstName}},</h2><p>Welcome to {{PlatformName}}! Your account is ready.</p><p><a href="{{LoginLink}}">Login to complete your profile</a></p>	t
7098d818-f9f2-4aac-adf2-f3705dfde7b8	otp_login	Your OTP for {{PlatformName}}	<p>Your One-Time Password is <strong>{{OTP}}</strong></p><p>Valid for {{OTPExpiry}} minutes. Never share this code.</p>	t
5eb1c4e4-56cb-47c6-a3e1-a79d3da80604	interest_received	You received a new interest!	<p>{{SenderName}} has shown interest in your profile.</p><p><a href="{{ProfileLink}}">View profile</a></p>	t
760aec02-6f1e-4e5f-81ad-7e8ccbb789c9	match_suggestion	Your daily match suggestions	<p>We found {{MatchCount}} new matches for you today. Your best match is {{MatchPercentage}}% compatible.</p><p><a href="{{LoginLink}}">See matches</a></p>	t
db6b43da-53df-416d-9cad-06588b8528c7	verification_approved	Your profile is verified ✅	<p>Congratulations {{FirstName}}! Your profile is now verified with the blue tick.</p>	t
363bcb5c-870e-47a3-a205-883871152aa1	subscription_expiring	Your subscription expires soon	<p>Your {{PlanName}} plan expires on {{ExpiryDate}}. <a href="{{RenewLink}}">Renew now</a> to keep enjoying premium features.</p>	t
\.


--
-- Data for Name: FeatureFlags; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."FeatureFlags" ("TenantId", "MatchingEnabled", "VideoCallEnabled", "KundliMatchingEnabled", "MaxPhotosPerProfile", "CustomFlags", "UpdatedOn") FROM stdin;
b0000000-0000-4000-8000-000000000001	t	f	f	6	{}	2026-08-06 09:47:10.65934+00
\.


--
-- Data for Name: Payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Payments" ("PaymentId", "SubscriptionId", "TenantId", "Amount", "Currency", "PaymentMethod", "TransactionId", "InvoiceNumber", "PaymentGateway", "Status", "PaidOn") FROM stdin;
\.


--
-- Data for Name: SubscriptionPlans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SubscriptionPlans" ("PlanId", "PlanName", "Description", "Price", "BillingCycle", "IsActive", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: SystemSettings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SystemSettings" ("SettingId", "SettingKey", "SettingValue") FROM stdin;
2b3072ed-9519-47e0-9c4b-ffe4a10545ff	platform_name	Matrimonial SaaS Platform
fc0be98c-01fc-4b03-acba-c9c2c4cd1f9a	support_email	support@platform.local
f6fdf777-ef05-482a-86e2-b23e351986c6	otp_expiry_minutes	5
24b54559-5023-4f28-bc31-47efd4508e0b	max_photos_default	6
0684fdb8-ef8f-47f2-a7ab-359eabf9148a	currency	INR
\.


--
-- Data for Name: TenantProvisioningLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TenantProvisioningLog" ("ProvisioningLogId", "TenantId", "Step", "Status", "ErrorMessage", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: TenantSubscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TenantSubscriptions" ("TenantSubscriptionId", "TenantId", "PlanId", "StartDate", "EndDate", "NextBillingDate", "Amount", "PaymentStatus", "SubscriptionStatus", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: Tenants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Tenants" ("TenantId", "TenantCode", "CompanyName", "OwnerName", "Email", "Phone", "Address", "City", "State", "Country", "ZipCode", "CustomDomain", "LogoUrl", "DatabaseName", "DatabaseServer", "ConnectionSecretRef", "Status", "IsActive", "CreatedBy", "CreatedOn", "UpdatedOn") FROM stdin;
b0000000-0000-4000-8000-000000000001	demotenant	Demo Matrimony Pvt Ltd	Demo Owner	owner@demotenant.local	+919876543210	\N	Mumbai	Maharashtra	India	\N	\N	\N	matrimonial_tenant_demotenant	localhost	secretsmanager://matrimonial/tenants/demotenant/db-credentials	active	t	a0000000-0000-4000-8000-000000000001	2026-08-06 09:47:10.644015+00	2026-08-06 09:47:10.644015+00
c8c4414b-6606-44cc-87dc-ed2240d5b1ae	shadi	Shadi Matrimony	\N	shadi@albarkat.in	\N	\N	\N	\N	India	\N	\N	\N	shadi_shadi_matrimony	\N	\N	suspended	f	\N	2026-08-06 09:47:14.65719+00	2026-08-06 09:47:14.65719+00
0fcc3275-d1ce-4743-8bf1-bb644ec9190c	provision-test	Provision Test Matrimony	\N	provision@albarkat.in	\N	\N	\N	\N	India	\N	\N	\N	provision-test_provisiontestmatrimony	\N	\N	active	t	\N	2026-08-06 09:47:14.65719+00	2026-08-06 09:47:14.65719+00
\.


--
-- Data for Name: ThemeConfigs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ThemeConfigs" ("TenantId", "BusinessName", "LogoUrl", "PrimaryColor", "SecondaryColor", "FontFamily", "Tagline", "ContactEmail", "ContactPhone", "UpdatedOn") FROM stdin;
b0000000-0000-4000-8000-000000000001	Demo Matrimony	\N	#1D9E75	#0F6E56	Inter	Find your perfect match	owner@demotenant.local	+919876543210	2026-08-06 09:47:10.651395+00
\.


--
-- Name: AdminUsers AdminUsers_AdminUserName_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AdminUsers"
    ADD CONSTRAINT "AdminUsers_AdminUserName_key" UNIQUE ("AdminUserName");


--
-- Name: AdminUsers AdminUsers_Email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AdminUsers"
    ADD CONSTRAINT "AdminUsers_Email_key" UNIQUE ("Email");


--
-- Name: AdminUsers AdminUsers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AdminUsers"
    ADD CONSTRAINT "AdminUsers_pkey" PRIMARY KEY ("AdminId");


--
-- Name: EmailTemplates EmailTemplates_TemplateName_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailTemplates"
    ADD CONSTRAINT "EmailTemplates_TemplateName_key" UNIQUE ("TemplateName");


--
-- Name: EmailTemplates EmailTemplates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailTemplates"
    ADD CONSTRAINT "EmailTemplates_pkey" PRIMARY KEY ("TemplateId");


--
-- Name: FeatureFlags FeatureFlags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FeatureFlags"
    ADD CONSTRAINT "FeatureFlags_pkey" PRIMARY KEY ("TenantId");


--
-- Name: Payments Payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Payments"
    ADD CONSTRAINT "Payments_pkey" PRIMARY KEY ("PaymentId");


--
-- Name: SubscriptionPlans SubscriptionPlans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SubscriptionPlans"
    ADD CONSTRAINT "SubscriptionPlans_pkey" PRIMARY KEY ("PlanId");


--
-- Name: SystemSettings SystemSettings_SettingKey_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SystemSettings"
    ADD CONSTRAINT "SystemSettings_SettingKey_key" UNIQUE ("SettingKey");


--
-- Name: SystemSettings SystemSettings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SystemSettings"
    ADD CONSTRAINT "SystemSettings_pkey" PRIMARY KEY ("SettingId");


--
-- Name: TenantProvisioningLog TenantProvisioningLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TenantProvisioningLog"
    ADD CONSTRAINT "TenantProvisioningLog_pkey" PRIMARY KEY ("ProvisioningLogId");


--
-- Name: TenantSubscriptions TenantSubscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TenantSubscriptions"
    ADD CONSTRAINT "TenantSubscriptions_pkey" PRIMARY KEY ("TenantSubscriptionId");


--
-- Name: Tenants Tenants_CustomDomain_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Tenants"
    ADD CONSTRAINT "Tenants_CustomDomain_key" UNIQUE ("CustomDomain");


--
-- Name: Tenants Tenants_TenantCode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Tenants"
    ADD CONSTRAINT "Tenants_TenantCode_key" UNIQUE ("TenantCode");


--
-- Name: Tenants Tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Tenants"
    ADD CONSTRAINT "Tenants_pkey" PRIMARY KEY ("TenantId");


--
-- Name: ThemeConfigs ThemeConfigs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ThemeConfigs"
    ADD CONSTRAINT "ThemeConfigs_pkey" PRIMARY KEY ("TenantId");


--
-- Name: idx_payments_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_tenant ON public."Payments" USING btree ("TenantId");


--
-- Name: idx_provlog_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_provlog_tenant ON public."TenantProvisioningLog" USING btree ("TenantId");


--
-- Name: idx_tenants_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_code ON public."Tenants" USING btree ("TenantCode");


--
-- Name: idx_tenants_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_status ON public."Tenants" USING btree ("Status");


--
-- Name: idx_tenantsub_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenantsub_tenant ON public."TenantSubscriptions" USING btree ("TenantId");


--
-- Name: AdminUsers trg_adminusers_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adminusers_updated_on BEFORE UPDATE ON public."AdminUsers" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: FeatureFlags trg_featureflags_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_featureflags_updated_on BEFORE UPDATE ON public."FeatureFlags" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: Tenants trg_tenants_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_tenants_updated_on BEFORE UPDATE ON public."Tenants" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: ThemeConfigs trg_themeconfigs_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_themeconfigs_updated_on BEFORE UPDATE ON public."ThemeConfigs" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: FeatureFlags fk_flags_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FeatureFlags"
    ADD CONSTRAINT fk_flags_tenant FOREIGN KEY ("TenantId") REFERENCES public."Tenants"("TenantId") ON DELETE CASCADE;


--
-- Name: Payments fk_payments_sub; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Payments"
    ADD CONSTRAINT fk_payments_sub FOREIGN KEY ("SubscriptionId") REFERENCES public."TenantSubscriptions"("TenantSubscriptionId");


--
-- Name: Payments fk_payments_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Payments"
    ADD CONSTRAINT fk_payments_tenant FOREIGN KEY ("TenantId") REFERENCES public."Tenants"("TenantId") ON DELETE CASCADE;


--
-- Name: TenantProvisioningLog fk_provlog_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TenantProvisioningLog"
    ADD CONSTRAINT fk_provlog_tenant FOREIGN KEY ("TenantId") REFERENCES public."Tenants"("TenantId") ON DELETE CASCADE;


--
-- Name: Tenants fk_tenants_createdby; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Tenants"
    ADD CONSTRAINT fk_tenants_createdby FOREIGN KEY ("CreatedBy") REFERENCES public."AdminUsers"("AdminId");


--
-- Name: TenantSubscriptions fk_tenantsub_plan; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TenantSubscriptions"
    ADD CONSTRAINT fk_tenantsub_plan FOREIGN KEY ("PlanId") REFERENCES public."SubscriptionPlans"("PlanId");


--
-- Name: TenantSubscriptions fk_tenantsub_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TenantSubscriptions"
    ADD CONSTRAINT fk_tenantsub_tenant FOREIGN KEY ("TenantId") REFERENCES public."Tenants"("TenantId") ON DELETE CASCADE;


--
-- Name: ThemeConfigs fk_theme_tenant; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ThemeConfigs"
    ADD CONSTRAINT fk_theme_tenant FOREIGN KEY ("TenantId") REFERENCES public."Tenants"("TenantId") ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict VJTR2ayyaoXgXV17Gv3GMVpJz9sa6BMittL6199lnLWAmPr3HwBmwyknjvGlioo


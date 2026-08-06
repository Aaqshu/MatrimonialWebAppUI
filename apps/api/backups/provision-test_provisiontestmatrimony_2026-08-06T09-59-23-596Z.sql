--
-- PostgreSQL database dump
--

\restrict 9Ag1x2XtHJ73HdXtMucayzoqFhD4YsRJfQgeDZpDxKBv6U88FVtqbQh5Q4jJ7Va

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
-- Name: assisted_request_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.assisted_request_status AS ENUM (
    'open',
    'in_progress',
    'closed'
);


--
-- Name: call_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.call_status AS ENUM (
    'initiated',
    'completed',
    'missed',
    'failed'
);


--
-- Name: call_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.call_type AS ENUM (
    'voice',
    'video'
);


--
-- Name: diet_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.diet_type AS ENUM (
    'vegetarian',
    'non_vegetarian',
    'eggetarian',
    'vegan'
);


--
-- Name: doc_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.doc_type AS ENUM (
    'aadhaar',
    'pan',
    'passport',
    'driving_license'
);


--
-- Name: enduser_payment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enduser_payment_status AS ENUM (
    'pending',
    'success',
    'failed',
    'refunded'
);


--
-- Name: enduser_subscription_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enduser_subscription_status AS ENUM (
    'active',
    'expired',
    'cancelled'
);


--
-- Name: gender_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gender_type AS ENUM (
    'male',
    'female',
    'other'
);


--
-- Name: interest_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.interest_status AS ENUM (
    'pending',
    'accepted',
    'declined'
);


--
-- Name: marital_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.marital_status AS ENUM (
    'never_married',
    'divorced',
    'widowed',
    'awaiting_divorce'
);


--
-- Name: profile_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.profile_visibility AS ENUM (
    'public',
    'hidden',
    'premium_only'
);


--
-- Name: profile_visible_to_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.profile_visible_to_type AS ENUM (
    'everyone',
    'same_community',
    'premium_only'
);


--
-- Name: report_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.report_status AS ENUM (
    'open',
    'reviewing',
    'resolved',
    'dismissed'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'end_user',
    'tenant_admin'
);


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status AS ENUM (
    'pending_verification',
    'active',
    'suspended'
);


--
-- Name: verification_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.verification_status AS ENUM (
    'unverified',
    'pending',
    'verified',
    'rejected'
);


--
-- Name: visibility_scope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.visibility_scope AS ENUM (
    'everyone',
    'matches_only',
    'premium_only',
    'nobody'
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
-- Name: AssistedMatchmakingRequests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AssistedMatchmakingRequests" (
    "RequestId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "AssignedAdminId" uuid,
    "Status" public.assisted_request_status DEFAULT 'open'::public.assisted_request_status NOT NULL,
    "Notes" text,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: BlockedUsers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."BlockedUsers" (
    "BlockId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "BlockedUserId" uuid NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: CallLogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CallLogs" (
    "CallId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CallerUserId" uuid NOT NULL,
    "ReceiverUserId" uuid NOT NULL,
    "CallType" public.call_type NOT NULL,
    "ProviderCallRef" character varying(255),
    "DurationSeconds" integer DEFAULT 0,
    "Status" public.call_status DEFAULT 'initiated'::public.call_status NOT NULL,
    "StartedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: CuratedMatches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CuratedMatches" (
    "CuratedMatchId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "RequestId" uuid NOT NULL,
    "SuggestedUserId" uuid NOT NULL,
    "CuratedBy" uuid NOT NULL,
    "Notes" character varying(500),
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: EndUserPayments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EndUserPayments" (
    "PaymentId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "SubscriptionId" uuid,
    "Amount" numeric(10,2) NOT NULL,
    "Currency" character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    "Provider" character varying(30) NOT NULL,
    "ProviderRef" character varying(255) NOT NULL,
    "Status" public.enduser_payment_status DEFAULT 'pending'::public.enduser_payment_status NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: EndUserPlans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EndUserPlans" (
    "PlanId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "PlanName" character varying(100) NOT NULL,
    "Price" numeric(10,2) NOT NULL,
    "DurationDays" integer NOT NULL,
    "Features" jsonb,
    "IsActive" boolean DEFAULT true NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: EndUserSubscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EndUserSubscriptions" (
    "SubscriptionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "Status" public.enduser_subscription_status DEFAULT 'active'::public.enduser_subscription_status NOT NULL,
    "StartsOn" timestamp with time zone DEFAULT now() NOT NULL,
    "ExpiresOn" timestamp with time zone NOT NULL,
    "PaymentRef" character varying(255),
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: Favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Favorites" (
    "FavoriteId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "FavoriteUserId" uuid NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: FeaturedListings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."FeaturedListings" (
    "FeaturedId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "StartsOn" timestamp with time zone NOT NULL,
    "ExpiresOn" timestamp with time zone NOT NULL,
    "PaymentRef" character varying(255),
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: GuardianDetails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."GuardianDetails" (
    "GuardianId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "FullName" character varying(150) NOT NULL,
    "Relationship" character varying(50) NOT NULL,
    "Phone" character varying(20),
    "Email" character varying(200),
    "CanReceiveInterests" boolean DEFAULT false NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: InterestRequests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."InterestRequests" (
    "InterestId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "SenderUserId" uuid NOT NULL,
    "ReceiverUserId" uuid NOT NULL,
    "Status" public.interest_status DEFAULT 'pending'::public.interest_status NOT NULL,
    "SentOn" timestamp with time zone DEFAULT now() NOT NULL,
    "RespondedOn" timestamp with time zone,
    CONSTRAINT chk_interest_not_self CHECK (("SenderUserId" <> "ReceiverUserId"))
);


--
-- Name: Matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Matches" (
    "MatchId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId1" uuid NOT NULL,
    "UserId2" uuid NOT NULL,
    "MatchPercentage" numeric(5,2) NOT NULL,
    "MatchedOn" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_match_not_self CHECK (("UserId1" <> "UserId2"))
);


--
-- Name: Messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Messages" (
    "MessageId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "SenderUserId" uuid NOT NULL,
    "ReceiverUserId" uuid NOT NULL,
    "Message" text NOT NULL,
    "IsRead" boolean DEFAULT false NOT NULL,
    "SentOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: Notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Notifications" (
    "NotificationId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Title" character varying(200) NOT NULL,
    "Message" text,
    "IsRead" boolean DEFAULT false NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "RefUserId" uuid
);


--
-- Name: OTPRequests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OTPRequests" (
    "OTPRequestId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid,
    "Phone" character varying(20) NOT NULL,
    "OTPHash" character varying(255) NOT NULL,
    "IsVerified" boolean DEFAULT false NOT NULL,
    "ExpiresOn" timestamp with time zone NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: PrivacySettings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PrivacySettings" (
    "UserId" uuid NOT NULL,
    "PhotoVisibility" public.visibility_scope DEFAULT 'everyone'::public.visibility_scope NOT NULL,
    "ContactVisibility" public.visibility_scope DEFAULT 'matches_only'::public.visibility_scope NOT NULL,
    "ProfileVisibleTo" public.profile_visible_to_type DEFAULT 'everyone'::public.profile_visible_to_type NOT NULL,
    "ShowOnlineStatus" boolean DEFAULT true NOT NULL,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ProfileViews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProfileViews" (
    "ViewId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "ViewerUserId" uuid NOT NULL,
    "ViewedUserId" uuid NOT NULL,
    "ViewedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: Reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Reports" (
    "ReportId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "ReporterUserId" uuid NOT NULL,
    "ReportedUserId" uuid NOT NULL,
    "Reason" character varying(100) NOT NULL,
    "Description" text,
    "Status" public.report_status DEFAULT 'open'::public.report_status NOT NULL,
    "ReviewedBy" uuid,
    "ReviewedOn" timestamp with time zone,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: SuccessStories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SuccessStories" (
    "StoryId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId1" uuid NOT NULL,
    "UserId2" uuid NOT NULL,
    "Testimonial" text,
    "PhotoUrl" character varying(500),
    "MarriageDate" date,
    "IsPublished" boolean DEFAULT false NOT NULL,
    "ApprovedBy" uuid,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: UserEducation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserEducation" (
    "EducationId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Qualification" character varying(150),
    "College" character varying(200),
    "University" character varying(200),
    "PassingYear" integer,
    "EducationType" character varying(100)
);


--
-- Name: UserFamilyDetails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserFamilyDetails" (
    "FamilyId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "FamilyType" character varying(50),
    "FamilyStatus" character varying(100),
    "FatherName" character varying(100),
    "FatherOccupation" character varying(150),
    "MotherName" character varying(100),
    "MotherOccupation" character varying(150),
    "Brothers" integer DEFAULT 0,
    "Sisters" integer DEFAULT 0
);


--
-- Name: UserLifestyle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserLifestyle" (
    "LifestyleId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Diet" public.diet_type,
    "Smoking" boolean DEFAULT false,
    "Drinking" boolean DEFAULT false,
    "Hobbies" text,
    "LanguagesKnown" character varying(500)
);


--
-- Name: UserLocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserLocation" (
    "LocationId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Country" character varying(100) DEFAULT 'India'::character varying,
    "State" character varying(100),
    "City" character varying(100),
    "Address" character varying(500),
    "Pincode" character varying(20)
);


--
-- Name: UserOccupation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserOccupation" (
    "OccupationId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Occupation" character varying(150),
    "CompanyName" character varying(200),
    "Designation" character varying(150),
    "AnnualIncome" numeric(18,2),
    "WorkLocation" character varying(200)
);


--
-- Name: UserPhotos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserPhotos" (
    "PhotoId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "PhotoUrl" character varying(500) NOT NULL,
    "IsPrimary" boolean DEFAULT false NOT NULL,
    "DisplayOrder" integer DEFAULT 0 NOT NULL,
    "IsApproved" boolean DEFAULT false NOT NULL,
    "UploadedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: UserPreferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserPreferences" (
    "PreferenceId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "MinAge" smallint,
    "MaxAge" smallint,
    "MinHeight" numeric(5,2),
    "MaxHeight" numeric(5,2),
    "Religion" jsonb,
    "Caste" jsonb,
    "Education" jsonb,
    "Occupation" jsonb,
    "Country" character varying(100),
    "State" character varying(100),
    "City" character varying(100)
);


--
-- Name: UserProfiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserProfiles" (
    "ProfileId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "Gender" public.gender_type NOT NULL,
    "DateOfBirth" date NOT NULL,
    "Height" numeric(5,2),
    "Weight" numeric(5,2),
    "MaritalStatus" public.marital_status DEFAULT 'never_married'::public.marital_status NOT NULL,
    "Religion" character varying(100),
    "Caste" character varying(100),
    "SubCaste" character varying(100),
    "MotherTongue" character varying(100),
    "BloodGroup" character varying(20),
    "AboutMe" text,
    "ProfileCompletionPercent" smallint DEFAULT 0 NOT NULL,
    "Visibility" public.profile_visibility DEFAULT 'public'::public.profile_visibility NOT NULL,
    "VerificationStatus" public.verification_status DEFAULT 'unverified'::public.verification_status NOT NULL,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "Sect" character varying(100),
    "IsBlueTickVerified" boolean DEFAULT false NOT NULL,
    "PhotosBlurredByDefault" boolean DEFAULT false NOT NULL
);


--
-- Name: UserSessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserSessions" (
    "SessionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "RefreshToken" character varying(500) NOT NULL,
    "DeviceName" character varying(200),
    "Browser" character varying(100),
    "IPAddress" character varying(50),
    "LoginTime" timestamp with time zone DEFAULT now() NOT NULL,
    "LogoutTime" timestamp with time zone
);


--
-- Name: Users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Users" (
    "UserId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserName" character varying(50),
    "FirstName" character varying(100) NOT NULL,
    "LastName" character varying(100),
    "Email" character varying(200),
    "Phone" character varying(20),
    "Password" character varying(255),
    "Role" public.user_role DEFAULT 'end_user'::public.user_role NOT NULL,
    "Status" public.user_status DEFAULT 'pending_verification'::public.user_status NOT NULL,
    "IsActive" boolean DEFAULT true NOT NULL,
    "LastLogin" timestamp with time zone,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    "UpdatedOn" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_phone_or_email CHECK ((("Phone" IS NOT NULL) OR ("Email" IS NOT NULL)))
);


--
-- Name: VerificationRequests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."VerificationRequests" (
    "VerificationId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "UserId" uuid NOT NULL,
    "DocType" public.doc_type NOT NULL,
    "DocReference" character varying(500) NOT NULL,
    "Status" public.verification_status DEFAULT 'pending'::public.verification_status NOT NULL,
    "ReviewedBy" uuid,
    "ReviewedOn" timestamp with time zone,
    "CreatedOn" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Data for Name: AssistedMatchmakingRequests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AssistedMatchmakingRequests" ("RequestId", "UserId", "AssignedAdminId", "Status", "Notes", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: BlockedUsers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."BlockedUsers" ("BlockId", "UserId", "BlockedUserId", "CreatedOn") FROM stdin;
df0c8bcc-f2e6-4615-8e51-1bba79497b2a	1993fb25-6147-4b5d-bb36-88f756254fd6	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	2026-08-05 15:23:58.29682+00
f07123a9-71c9-4f8b-94b5-468c2b2959f2	c8a549c1-0fe0-4e7f-af9e-56cc61372088	efcd6ed2-c765-4041-9feb-cd72f820ee45	2026-08-05 15:24:13.541775+00
e52ad4f3-7e62-43a7-9230-1133b0106566	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	e576df13-6cd8-44a2-be61-44cb945bc25a	2026-08-05 15:31:00.471124+00
b9b9e5a3-1e2f-4048-afc1-97573dfe54a0	44edbe9e-2762-4722-bac2-b9731acd35b7	fbd4b51b-493b-429d-a938-94354ce49c63	2026-08-05 15:32:02.686265+00
4be0d6e7-1d8f-4893-b8e0-bab06e8680f5	a8ba3347-742a-4523-aed8-77c774142345	3d8c7d31-67c4-4023-b401-4ac046cf56ac	2026-08-05 15:32:20.110084+00
5d5d3c56-d638-4613-89d3-57f26aec0f82	36615d5a-0131-4c21-98e3-956ceca31d48	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 16:28:23.005978+00
60615005-9e84-49a9-9f6f-569271f13439	2d150870-1d4e-42e0-863c-0bad5782141e	d4e10fc0-e272-4867-81cd-567a0e84cfdf	2026-08-06 02:30:35.697658+00
7b0661d2-4bbe-498e-9446-1585b96c061e	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	2026-08-06 06:32:30.91776+00
2a2b3e25-bfb5-4f97-94f2-c84a4b398a04	1c16cafc-57a6-4651-b25f-a364716b322e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	2026-08-06 06:33:21.143175+00
ab36e7b3-250b-43ff-b1a4-f5db5bd37949	7294e7cd-2388-4a10-9e3a-31f532b748ee	d7c3fa7c-c268-4e5c-acec-0450571fdb18	2026-08-06 06:33:58.16576+00
ae5c51eb-3e63-4c7c-94c1-6ea103198b14	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	2026-08-06 07:24:25.979403+00
28b60cbb-6822-4a4c-83fd-19f46cda56ef	ddcd3ad5-423b-436e-b921-4322d3397be4	cf8b1225-10c8-42b4-81a9-6dc603b4b753	2026-08-06 07:24:59.884724+00
23192bf5-d333-450f-8844-7a7ffe3d0767	19d0db83-6560-4103-ac51-6d11e51c4d76	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	2026-08-06 07:25:50.256759+00
996a3c15-400f-4d5e-9f63-66a80c408da5	7eb32340-5dc9-4180-ae5f-626b2090eb41	367fdce2-dc07-4945-af3f-22a1305b03e0	2026-08-06 07:27:08.954004+00
6212fc23-0cf5-4ba0-b441-2a3ae9665aa7	3bd0bf00-d276-46c2-ae5b-11870c818ec5	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	2026-08-06 07:39:34.141193+00
b2d2bb4e-86e5-4444-af66-07b970e819dd	c118f901-1a69-4866-98b8-677f315742a1	cf11c185-cff1-4c4c-a254-63c9cae16950	2026-08-06 07:40:07.704996+00
e5e12b3b-dde9-44d0-b1dc-bb96f034e287	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	9a619129-5447-45a7-b1a9-45ca14708e7b	2026-08-06 07:40:44.286751+00
\.


--
-- Data for Name: CallLogs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CallLogs" ("CallId", "CallerUserId", "ReceiverUserId", "CallType", "ProviderCallRef", "DurationSeconds", "Status", "StartedOn") FROM stdin;
\.


--
-- Data for Name: CuratedMatches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CuratedMatches" ("CuratedMatchId", "RequestId", "SuggestedUserId", "CuratedBy", "Notes", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: EndUserPayments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EndUserPayments" ("PaymentId", "UserId", "SubscriptionId", "Amount", "Currency", "Provider", "ProviderRef", "Status", "CreatedOn") FROM stdin;
146f5f9d-9995-4cdb-afc2-24bb1e62e2d2	ca5f760e-7b1d-46d9-b000-1d6041f494a5	b107c30e-2eff-41da-8786-9ec371ae919c	0.00	INR	razorpay	DEV_D42E13E1FC22E9C3	success	2026-08-06 07:39:43.595512+00
242df06d-8f96-46ff-9092-af121a1f6f2f	010bb5b8-d47d-43d9-87e1-4cb2e927b635	c7e1c068-7eda-4129-80ba-3df52c008263	0.00	INR	razorpay	DEV_26BEAB5095548878	success	2026-08-06 07:39:58.895527+00
a52adb6c-927a-4ea1-b609-4a77628c70fa	886d75e0-e090-4177-a6d8-570db8b1208c	60ca49ec-681a-40ed-a5f4-e68945276c63	1999.00	INR	razorpay	DEV_A9713B2A1B7627B5	success	2026-08-06 07:42:05.098331+00
\.


--
-- Data for Name: EndUserPlans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EndUserPlans" ("PlanId", "PlanName", "Price", "DurationDays", "Features", "IsActive", "CreatedOn") FROM stdin;
ba4e6b71-87b7-421b-ad9c-2c0cbedb0fa2	Free	0.00	365	["basic_profile", "5_interests_month"]	t	2026-08-06 07:39:21.7136+00
4b7e3a36-f5d0-4465-ab16-95051599b7e7	Gold	1999.00	30	["unlimited_interests", "see_photos", "read_receipts", "call_masking"]	t	2026-08-06 07:39:21.7136+00
a850983e-2339-4744-a6cb-a992b7fbc640	Platinum	4999.00	90	["unlimited_interests", "see_photos", "read_receipts", "call_masking", "featured_7d", "priority_support"]	t	2026-08-06 07:39:21.7136+00
f871e051-5038-4e19-a9f5-3f09b55729db	Royal	15999.00	365	["unlimited_interests", "see_photos", "read_receipts", "call_masking", "featured_30d", "priority_support", "match_concierge"]	t	2026-08-06 07:39:21.7136+00
\.


--
-- Data for Name: EndUserSubscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EndUserSubscriptions" ("SubscriptionId", "UserId", "PlanId", "Status", "StartsOn", "ExpiresOn", "PaymentRef", "CreatedOn") FROM stdin;
b107c30e-2eff-41da-8786-9ec371ae919c	ca5f760e-7b1d-46d9-b000-1d6041f494a5	ba4e6b71-87b7-421b-ad9c-2c0cbedb0fa2	active	2026-08-06 07:39:43.557768+00	2027-08-06 07:39:43.557768+00	\N	2026-08-06 07:39:43.557768+00
c7e1c068-7eda-4129-80ba-3df52c008263	010bb5b8-d47d-43d9-87e1-4cb2e927b635	ba4e6b71-87b7-421b-ad9c-2c0cbedb0fa2	active	2026-08-06 07:39:58.854197+00	2027-08-06 07:39:58.854197+00	\N	2026-08-06 07:39:58.854197+00
60ca49ec-681a-40ed-a5f4-e68945276c63	886d75e0-e090-4177-a6d8-570db8b1208c	4b7e3a36-f5d0-4465-ab16-95051599b7e7	active	2026-08-06 07:42:05.092125+00	2026-09-05 07:42:05.092125+00	\N	2026-08-06 07:42:05.092125+00
\.


--
-- Data for Name: Favorites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Favorites" ("FavoriteId", "UserId", "FavoriteUserId", "CreatedOn") FROM stdin;
9b803fab-9c72-4e4e-8853-c482ac7f19ed	36615d5a-0131-4c21-98e3-956ceca31d48	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 16:28:22.79335+00
19841e43-3b69-4ee3-b161-15ebe17e4c59	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 17:32:23.192717+00
fd9f9fc5-4575-4a32-b9c9-ab95e18dffde	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-05 18:21:09.40683+00
\.


--
-- Data for Name: FeaturedListings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."FeaturedListings" ("FeaturedId", "UserId", "StartsOn", "ExpiresOn", "PaymentRef", "CreatedOn") FROM stdin;
b3cf3a76-9a99-4467-b866-d8170560982b	2f3e926f-0cbc-487f-bf08-9e1521cd4775	2026-08-06 07:39:14.680761+00	2026-08-13 07:39:14.680761+00	DEV_1786001954494	2026-08-06 07:39:14.680761+00
6ba523e2-6fb0-446a-8aca-45756516076b	ca5f760e-7b1d-46d9-b000-1d6041f494a5	2026-08-06 07:39:43.759408+00	2026-08-13 07:39:43.759408+00	DEV_1786001983574	2026-08-06 07:39:43.759408+00
c48588ef-9918-4997-8af2-b37c092e78e7	010bb5b8-d47d-43d9-87e1-4cb2e927b635	2026-08-06 07:39:59.076915+00	2026-08-13 07:39:59.076915+00	DEV_1786001998892	2026-08-06 07:39:59.076915+00
aeb8e524-598c-4b52-bd83-36c24cd75a4d	605f37bc-fb38-43e6-b3bc-11412f4a1724	2026-08-06 07:40:39.485077+00	2026-08-13 07:40:39.485077+00	DEV_1786002039300	2026-08-06 07:40:39.485077+00
bd2140eb-7911-4d80-aac0-06bad47eadfc	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-06 07:42:05.386983+00	2026-08-13 07:42:05.386983+00	DEV_1786002125386	2026-08-06 07:42:05.386983+00
\.


--
-- Data for Name: GuardianDetails; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."GuardianDetails" ("GuardianId", "UserId", "FullName", "Relationship", "Phone", "Email", "CanReceiveInterests", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: InterestRequests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."InterestRequests" ("InterestId", "SenderUserId", "ReceiverUserId", "Status", "SentOn", "RespondedOn") FROM stdin;
1f595ba8-7cc9-4d1e-be19-a55524757395	1993fb25-6147-4b5d-bb36-88f756254fd6	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	accepted	2026-08-05 15:23:57.700916+00	2026-08-05 15:23:57.903665+00
c5804b30-da77-4d0e-9bc6-b7e72a860edd	c8a549c1-0fe0-4e7f-af9e-56cc61372088	efcd6ed2-c765-4041-9feb-cd72f820ee45	accepted	2026-08-05 15:24:13.015755+00	2026-08-05 15:24:13.191544+00
cd38afac-da04-487d-ae72-165ced88df68	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	e576df13-6cd8-44a2-be61-44cb945bc25a	accepted	2026-08-05 15:24:37.034184+00	2026-08-05 15:24:37.435884+00
45da6dd1-f25f-45ad-b768-44a4ff1e6f8b	44edbe9e-2762-4722-bac2-b9731acd35b7	fbd4b51b-493b-429d-a938-94354ce49c63	accepted	2026-08-05 15:32:01.904424+00	2026-08-05 15:32:02.261786+00
b9e7eb15-039f-4273-b933-c069ac702e24	a8ba3347-742a-4523-aed8-77c774142345	3d8c7d31-67c4-4023-b401-4ac046cf56ac	accepted	2026-08-05 15:32:19.543756+00	2026-08-05 15:32:19.723974+00
cd149197-45bc-4dd0-94fe-e0d4dd0fa6ac	36615d5a-0131-4c21-98e3-956ceca31d48	fd039e52-629b-489a-b445-3003be85cb8d	pending	2026-08-05 16:28:22.698852+00	\N
3d749f74-f0d3-4ca7-80eb-2a28a0ea9b93	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	accepted	2026-08-05 18:21:59.846243+00	2026-08-05 18:23:43.247439+00
8c40d066-f890-4665-bd44-d075bb48127b	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	declined	2026-08-05 18:24:02.08712+00	2026-08-05 18:24:34.814889+00
0f7adeb0-591c-4676-b25e-8f2ae462826d	2d150870-1d4e-42e0-863c-0bad5782141e	d4e10fc0-e272-4867-81cd-567a0e84cfdf	accepted	2026-08-06 02:30:34.975271+00	2026-08-06 02:30:35.283459+00
943dc11a-6a94-4652-8ac1-879432337675	f6d46263-407d-429f-aabc-f9e3c7b6aed3	4758c076-09d2-42d8-88cc-cce435637c32	accepted	2026-08-06 06:31:47.989044+00	2026-08-06 06:31:48.140454+00
aa38f164-b0ea-4745-aae3-8294ac8a44fe	5ad80524-52fe-43f5-b245-2a7ae49a92cf	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	accepted	2026-08-06 06:31:58.513058+00	2026-08-06 06:31:58.668915+00
a81555ae-6775-4008-aad3-f77cc9da9d84	6914b9da-19a1-48d7-bccb-a39a08216f7c	12387821-8e7e-402f-9291-8f1fbadbce1e	accepted	2026-08-06 06:32:07.63767+00	2026-08-06 06:32:07.789925+00
70d1f0b4-4937-49f4-abda-c407d6dd2340	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	d31b3330-980a-4d38-bf4d-c221a5033bda	accepted	2026-08-06 06:32:21.576896+00	2026-08-06 06:32:21.763764+00
68afddc5-159b-405c-a21a-f727e10b40f7	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	accepted	2026-08-06 06:32:30.362765+00	2026-08-06 06:32:30.543229+00
fe00bf6a-7279-4472-960d-1c39c8a5f680	e81e56cc-db91-4ddb-b1e8-530510958e6c	25634a36-337f-4d14-a96d-1a843df8614e	accepted	2026-08-06 06:33:15.74431+00	2026-08-06 06:33:16.376431+00
702c8f9f-7e6d-485b-bbdf-f26dd58ea2b9	1c16cafc-57a6-4651-b25f-a364716b322e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	accepted	2026-08-06 06:33:20.530202+00	2026-08-06 06:33:20.773726+00
cb7136d7-7046-4f6c-b14d-97ee33157d50	730aab59-18e5-4343-8ea5-20d21d417f9a	b23ee7a2-7e56-495e-96b8-f1253aeaea36	accepted	2026-08-06 06:33:53.035299+00	2026-08-06 06:33:53.317509+00
1866c913-424a-413f-a263-078dfc90ef69	7294e7cd-2388-4a10-9e3a-31f532b748ee	d7c3fa7c-c268-4e5c-acec-0450571fdb18	accepted	2026-08-06 06:33:57.498753+00	2026-08-06 06:33:57.75716+00
438be13a-e371-48b8-b1d2-f4e63fd84593	bba02b1e-aae7-4873-9983-7a8196db808b	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	accepted	2026-08-06 06:35:35.129621+00	2026-08-06 06:35:35.373917+00
8bda2177-16c7-4404-9ab0-719a4964cdb7	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	accepted	2026-08-06 07:24:25.241762+00	2026-08-06 07:24:25.520567+00
832e97c5-34bf-4515-9bac-1a4410667e7c	b3e94172-8013-4cdc-b429-33dd88309863	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	accepted	2026-08-06 07:24:31.789736+00	2026-08-06 07:24:32.037951+00
a2640b8f-269a-41d9-ab29-fef522f5e55f	ddcd3ad5-423b-436e-b921-4322d3397be4	cf8b1225-10c8-42b4-81a9-6dc603b4b753	accepted	2026-08-06 07:24:59.171179+00	2026-08-06 07:24:59.482761+00
01f4255d-f614-4a23-8b40-20359b3a616b	f20698bd-7049-4b40-8d92-c62216637198	b53dcfda-741c-4278-a232-6c0f18ad2805	accepted	2026-08-06 07:25:01.846156+00	2026-08-06 07:25:02.073767+00
d62e2f26-335a-4c14-b013-572c19b9497c	30a21658-542f-4803-a13c-651be1e25909	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	accepted	2026-08-06 07:25:45.271891+00	2026-08-06 07:25:45.487332+00
373a2b53-f0d8-4ca3-89e7-1276b11e4451	19d0db83-6560-4103-ac51-6d11e51c4d76	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	accepted	2026-08-06 07:25:49.595847+00	2026-08-06 07:25:49.851726+00
9109a1cf-227a-415e-b25b-9a4a569738eb	7eb32340-5dc9-4180-ae5f-626b2090eb41	367fdce2-dc07-4945-af3f-22a1305b03e0	accepted	2026-08-06 07:27:08.24731+00	2026-08-06 07:27:08.514813+00
9c513a5c-922b-4968-966c-77117c375ac5	d91dd487-28c3-4f03-8206-3d7bc12e0765	b4163d69-9347-4fb5-8edf-0a58dedfd768	accepted	2026-08-06 07:27:14.411772+00	2026-08-06 07:27:14.642652+00
ebc6d298-f8ea-4c32-8891-c60e5d1e812e	3bd0bf00-d276-46c2-ae5b-11870c818ec5	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	accepted	2026-08-06 07:39:33.464781+00	2026-08-06 07:39:33.734024+00
f50442ac-15fa-4e81-b850-5733372aa595	7ea9daf4-0016-43c4-b811-70ec6b60254d	c3b43f87-73b1-435c-94a0-c45939b5ee02	accepted	2026-08-06 07:39:36.928931+00	2026-08-06 07:39:37.216433+00
3f8a11d0-77c7-4040-9e02-b6d01eda1b6c	c118f901-1a69-4866-98b8-677f315742a1	cf11c185-cff1-4c4c-a254-63c9cae16950	accepted	2026-08-06 07:40:06.218286+00	2026-08-06 07:40:07.007014+00
4a86efa6-9e08-4709-a49f-8707123e9a4e	77a4ff3b-0afa-4776-8504-a026984e3b14	0a0ca69a-734a-464d-846d-03905795c51c	accepted	2026-08-06 07:40:09.891926+00	2026-08-06 07:40:10.120673+00
c0e45615-ad7e-4c62-a347-c6d79fcec369	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	9a619129-5447-45a7-b1a9-45ca14708e7b	accepted	2026-08-06 07:40:43.337764+00	2026-08-06 07:40:43.793753+00
f810aff9-888e-4fe0-9792-08f9c938b2b6	215f7372-6d92-40ec-9f9a-1879debb080d	0270429b-5a36-466a-82f5-0dbe02c49821	accepted	2026-08-06 07:40:53.719182+00	2026-08-06 07:40:53.92875+00
\.


--
-- Data for Name: Matches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Matches" ("MatchId", "UserId1", "UserId2", "MatchPercentage", "MatchedOn") FROM stdin;
377c7c6a-aa64-4b98-a94c-056038944cd6	3d8c7d31-67c4-4023-b401-4ac046cf56ac	e2fd25fb-510b-4af5-a453-84ab5a69cf21	100.00	2026-08-06 02:29:48.222467+00
dacbd21a-8bf6-4d5b-967c-ccde4048d000	e2fd25fb-510b-4af5-a453-84ab5a69cf21	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 02:29:48.258039+00
632dda4d-d48e-4c47-b8fe-5656b947448c	e2fd25fb-510b-4af5-a453-84ab5a69cf21	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 02:29:48.290075+00
b75bd06c-99d7-46ae-9214-9dde2c993676	e2fd25fb-510b-4af5-a453-84ab5a69cf21	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 02:29:48.325753+00
b4ab5507-2d96-44ad-93e0-5d9a798c8316	e2fd25fb-510b-4af5-a453-84ab5a69cf21	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 02:29:48.358567+00
621fb830-3c27-4da1-93ee-9eca6fa2e39f	36615d5a-0131-4c21-98e3-956ceca31d48	e2fd25fb-510b-4af5-a453-84ab5a69cf21	100.00	2026-08-06 02:29:48.389271+00
8e9e4a98-379c-4c12-a5cc-b24fbb9d4e89	e2fd25fb-510b-4af5-a453-84ab5a69cf21	f1d17cc9-15ee-4758-846e-e01e49b8779a	100.00	2026-08-06 02:29:48.425365+00
46bf1c52-2c9c-4867-95b5-fa5fcb52ccb5	59296eac-cc9d-44d1-913d-a5ef3365343c	e2fd25fb-510b-4af5-a453-84ab5a69cf21	100.00	2026-08-06 02:29:48.458572+00
9b75152a-cca0-44f0-b20f-bc3f44a280f2	3d8c7d31-67c4-4023-b401-4ac046cf56ac	8b6fae7c-974a-4d6e-9221-f37cf6a97469	100.00	2026-08-06 02:29:57.134761+00
50a379f3-958d-47d2-a054-307370823479	8b6fae7c-974a-4d6e-9221-f37cf6a97469	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 02:29:57.167867+00
7b7b049a-0322-4274-ad0b-d09705562523	8b6fae7c-974a-4d6e-9221-f37cf6a97469	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 02:29:57.206514+00
ef760f18-6977-4cd4-9e8b-88650fe9635f	8b6fae7c-974a-4d6e-9221-f37cf6a97469	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 02:29:57.238839+00
b398ce5e-f041-489d-834a-0a7cf533d667	8b6fae7c-974a-4d6e-9221-f37cf6a97469	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 02:29:57.271888+00
b06f27fb-01b4-44c7-8b41-7726887b1a1d	36615d5a-0131-4c21-98e3-956ceca31d48	8b6fae7c-974a-4d6e-9221-f37cf6a97469	100.00	2026-08-06 02:29:57.305515+00
9cac5984-d8f4-4e14-931c-920f1dced9e8	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	8b6fae7c-974a-4d6e-9221-f37cf6a97469	100.00	2026-08-06 02:29:57.337283+00
891ea98d-6e26-4133-bfb9-58521aac09c5	8b6fae7c-974a-4d6e-9221-f37cf6a97469	f1d17cc9-15ee-4758-846e-e01e49b8779a	100.00	2026-08-06 02:29:57.376226+00
bc2ea57c-cc94-49f8-a527-61847582ff74	59296eac-cc9d-44d1-913d-a5ef3365343c	8b6fae7c-974a-4d6e-9221-f37cf6a97469	100.00	2026-08-06 02:29:57.406657+00
6c9a5b5e-5814-431d-adba-ad02c94d8462	3d8c7d31-67c4-4023-b401-4ac046cf56ac	3f591c6a-5509-45f9-a2e5-050be735735a	100.00	2026-08-06 02:30:18.290646+00
69a7b007-cbdc-4164-bab2-c7065f73b73b	3f591c6a-5509-45f9-a2e5-050be735735a	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 02:30:18.342756+00
25ef5e7f-057e-4390-8f1d-8c9befba3a03	3f591c6a-5509-45f9-a2e5-050be735735a	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 02:30:18.375713+00
ed86d906-5354-4e71-9c7d-0c2c6b1aa1bf	3f591c6a-5509-45f9-a2e5-050be735735a	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 02:30:18.444172+00
863d6e9f-b758-4c10-8a98-ff5b6691c05b	3f591c6a-5509-45f9-a2e5-050be735735a	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 02:30:18.476571+00
5b24af90-4d42-4af4-8bd2-2292ef21b548	6df70e40-bb74-457a-a687-5e470514447b	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 06:33:24.995876+00
105c56b2-f1a4-48f3-bc47-b21a221fb29d	3f591c6a-5509-45f9-a2e5-050be735735a	f5a61371-a191-4bfe-9659-1a05b788696b	100.00	2026-08-06 02:30:18.539811+00
b825a4a9-0ec3-4fee-a3eb-5eb2d7b09419	3f591c6a-5509-45f9-a2e5-050be735735a	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	100.00	2026-08-06 02:30:18.575523+00
9d362d44-7b06-491c-80d5-e5ab7b93ea0a	3f591c6a-5509-45f9-a2e5-050be735735a	f1d17cc9-15ee-4758-846e-e01e49b8779a	100.00	2026-08-06 02:30:18.606752+00
56fd5d1a-0bc3-4c11-8ef9-ee74f9a87be9	3f591c6a-5509-45f9-a2e5-050be735735a	59296eac-cc9d-44d1-913d-a5ef3365343c	100.00	2026-08-06 02:30:18.64074+00
259343ef-c3b7-44e8-84fc-5f06dfcfa292	3d8c7d31-67c4-4023-b401-4ac046cf56ac	6c982b06-1aca-4977-b319-191e16fc4de6	100.00	2026-08-06 02:30:31.37335+00
fa1ee78e-5e2a-4df0-a68d-100977ea910f	6c982b06-1aca-4977-b319-191e16fc4de6	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 02:30:31.40707+00
f37bf641-c84f-4de6-a300-498e625d1e2f	6c982b06-1aca-4977-b319-191e16fc4de6	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 02:30:31.448406+00
3605fb8c-1429-4d73-8ee3-fa24da1c65ab	6c982b06-1aca-4977-b319-191e16fc4de6	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 02:30:31.506908+00
64119ab9-4278-42f7-b56b-b74a91459d25	6c982b06-1aca-4977-b319-191e16fc4de6	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 02:30:31.544211+00
9ccdeb53-7842-490e-8585-e397e5b64bb1	3d8c7d31-67c4-4023-b401-4ac046cf56ac	6df70e40-bb74-457a-a687-5e470514447b	100.00	2026-08-06 06:33:25.067967+00
931b4f11-b58d-4629-ac87-f85dbf2b8861	15628c01-d0a0-422c-95b2-dcc978ad6fa1	6c982b06-1aca-4977-b319-191e16fc4de6	100.00	2026-08-06 02:30:31.61785+00
0e99c65f-f45f-41a8-871f-2397c8be6335	6c982b06-1aca-4977-b319-191e16fc4de6	f5a61371-a191-4bfe-9659-1a05b788696b	100.00	2026-08-06 02:30:31.648589+00
a97d3e7e-60a6-4170-ba99-32a876c738d2	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	6c982b06-1aca-4977-b319-191e16fc4de6	100.00	2026-08-06 02:30:31.684226+00
52b98f42-a73d-4590-a623-f69b5bb5ac4e	6c982b06-1aca-4977-b319-191e16fc4de6	f1d17cc9-15ee-4758-846e-e01e49b8779a	100.00	2026-08-06 02:30:31.716179+00
987c3b16-7457-44c4-9412-3db652d411a1	36615d5a-0131-4c21-98e3-956ceca31d48	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	100.00	2026-08-06 02:31:47.051752+00
0c4c896f-2df4-4c6b-a031-c874399a35cc	36615d5a-0131-4c21-98e3-956ceca31d48	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	33.00	2026-08-06 02:31:47.060641+00
b1ed2bbb-4962-4746-9f01-ed4147cada19	36615d5a-0131-4c21-98e3-956ceca31d48	d45844b4-81d5-448a-9e5b-549832b07407	100.00	2026-08-06 02:31:47.064188+00
a165f02c-4bfd-4725-a40a-c6f92adfc509	36615d5a-0131-4c21-98e3-956ceca31d48	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	100.00	2026-08-06 02:31:47.069372+00
fa7d2f3d-44ae-4a18-9015-54ed2a858ee5	36615d5a-0131-4c21-98e3-956ceca31d48	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	100.00	2026-08-06 02:31:47.073199+00
f2a1d3b2-56cb-4bbc-95ba-bfaa91f63b76	36615d5a-0131-4c21-98e3-956ceca31d48	5b90a2de-8e41-493d-8311-e21b2e27a452	100.00	2026-08-06 02:31:47.075393+00
0b224b14-65f6-4d40-ad9f-7e38be96e572	36615d5a-0131-4c21-98e3-956ceca31d48	60f50480-cbe7-45b2-b94a-462ddc882514	100.00	2026-08-06 02:31:47.080429+00
bc221e1b-143f-43ec-b16e-bd759bb8b07b	36615d5a-0131-4c21-98e3-956ceca31d48	886d75e0-e090-4177-a6d8-570db8b1208c	33.00	2026-08-06 02:31:47.084468+00
7869a17c-44f7-40dd-882f-7ce86fee45c3	36615d5a-0131-4c21-98e3-956ceca31d48	6c982b06-1aca-4977-b319-191e16fc4de6	83.00	2026-08-06 02:30:31.574953+00
c3d4cd6b-47b5-443d-b8ff-8eb9cffd4f26	36615d5a-0131-4c21-98e3-956ceca31d48	3f591c6a-5509-45f9-a2e5-050be735735a	83.00	2026-08-06 02:30:18.50786+00
6f4b8f5c-2c61-4768-b1d7-eec9a350d751	679a9cbd-c4bc-4326-a754-e6d09a55b010	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 06:32:33.483426+00
5e3d7759-c65b-402f-9468-51d3f0105182	679a9cbd-c4bc-4326-a754-e6d09a55b010	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 06:32:33.524233+00
866abb78-ec8d-46d6-bd02-f0fafa7ae3b6	3d8c7d31-67c4-4023-b401-4ac046cf56ac	679a9cbd-c4bc-4326-a754-e6d09a55b010	100.00	2026-08-06 06:32:33.560863+00
744c7fc8-b39d-4418-bdae-05a5fd33b6c1	679a9cbd-c4bc-4326-a754-e6d09a55b010	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 06:32:33.593116+00
67be905e-cce2-4639-82e8-dcc62f12ac3c	679a9cbd-c4bc-4326-a754-e6d09a55b010	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 06:32:33.63259+00
dced9ef0-16f4-48de-92aa-142379143eb3	679a9cbd-c4bc-4326-a754-e6d09a55b010	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 06:32:33.66693+00
0eeaf8e9-6c28-4cc2-85f5-4d2dac346e5d	679a9cbd-c4bc-4326-a754-e6d09a55b010	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 06:32:33.699945+00
7ec87688-dd77-4d88-9a5b-a794177afa0f	36615d5a-0131-4c21-98e3-956ceca31d48	679a9cbd-c4bc-4326-a754-e6d09a55b010	100.00	2026-08-06 06:32:33.729811+00
9b693f2e-0499-46cb-870b-4e56f090b0ac	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	679a9cbd-c4bc-4326-a754-e6d09a55b010	100.00	2026-08-06 06:32:33.761617+00
1d2b7979-510f-4a62-8697-94ba9396e01e	15628c01-d0a0-422c-95b2-dcc978ad6fa1	679a9cbd-c4bc-4326-a754-e6d09a55b010	100.00	2026-08-06 06:32:33.793727+00
eebfad5d-c5f9-48a8-9540-c9e4717bdd0e	6df70e40-bb74-457a-a687-5e470514447b	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 06:33:24.870764+00
82616f37-fe69-43af-8b6b-80f57cff268e	6df70e40-bb74-457a-a687-5e470514447b	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 06:33:24.906238+00
5d9cbe93-a637-4f51-86c6-bb8bdbb626f0	6df70e40-bb74-457a-a687-5e470514447b	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 06:33:25.128107+00
6d2bce91-b103-4ec8-9562-f291c303283b	6df70e40-bb74-457a-a687-5e470514447b	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 06:33:25.170138+00
6f69b418-0f6c-4a62-8cc9-0f6c9270b6c5	6df70e40-bb74-457a-a687-5e470514447b	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 06:33:25.201656+00
4bd93c00-783c-4d03-ab28-a8ae00c610df	6df70e40-bb74-457a-a687-5e470514447b	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 06:33:25.270121+00
a9aa4213-471b-49b5-b8c8-af6f20cc6fa8	36615d5a-0131-4c21-98e3-956ceca31d48	6df70e40-bb74-457a-a687-5e470514447b	100.00	2026-08-06 06:33:25.345495+00
3df09942-6396-45b7-8610-0a8149e47d1b	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	6df70e40-bb74-457a-a687-5e470514447b	100.00	2026-08-06 06:33:25.37614+00
c3b152d4-3418-4141-aa53-3e4efb36f68b	287fea1f-a616-4b7f-82f8-fc0886dceda0	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 06:33:49.996132+00
3db1b9e1-f41d-4305-af6b-1d5b58ea891e	287fea1f-a616-4b7f-82f8-fc0886dceda0	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 06:33:50.029753+00
c7bd3fe5-782a-4008-a0af-c89b3970b5f4	287fea1f-a616-4b7f-82f8-fc0886dceda0	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 06:33:50.059754+00
e680a936-156f-4f95-ad6f-d4b4931706aa	287fea1f-a616-4b7f-82f8-fc0886dceda0	3d8c7d31-67c4-4023-b401-4ac046cf56ac	100.00	2026-08-06 06:33:50.093438+00
f3e49dce-c511-4406-ae4f-a6fc36fa8f37	287fea1f-a616-4b7f-82f8-fc0886dceda0	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 06:33:50.134226+00
f6b67474-ed7b-4526-950d-094669b2481d	287fea1f-a616-4b7f-82f8-fc0886dceda0	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 06:33:50.165421+00
77844d8e-f255-4ee2-825d-1346b075f81e	287fea1f-a616-4b7f-82f8-fc0886dceda0	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 06:33:50.201226+00
55e89a02-0fe4-4f7b-bb8d-cb4b60ed7657	287fea1f-a616-4b7f-82f8-fc0886dceda0	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 06:33:50.234925+00
586c2dd9-fd0f-4f4c-8d01-6dd4f3156742	287fea1f-a616-4b7f-82f8-fc0886dceda0	36615d5a-0131-4c21-98e3-956ceca31d48	100.00	2026-08-06 06:33:50.269218+00
62adfef9-89c1-4d29-a9ae-587b0c93edb0	287fea1f-a616-4b7f-82f8-fc0886dceda0	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	100.00	2026-08-06 06:33:50.304752+00
2d4b34a9-6fa9-4746-aab8-376289069c67	7607d532-01cb-4685-93d0-019c266c06ca	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:24:28.92976+00
8cfa2e87-7035-463e-8348-5e5dace3aad8	7607d532-01cb-4685-93d0-019c266c06ca	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:24:28.975758+00
1120c119-df1f-4ba1-9b3f-dad6694abc3c	7607d532-01cb-4685-93d0-019c266c06ca	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:24:29.048472+00
aa7dffd8-4006-4c95-b2d7-35ebef74298a	7607d532-01cb-4685-93d0-019c266c06ca	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:24:29.091619+00
c31d7c83-c0f3-4fd6-a941-29ecfe1fef35	7607d532-01cb-4685-93d0-019c266c06ca	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:24:29.129755+00
b259222e-5d34-4467-a6cc-7f520d4824b1	3d8c7d31-67c4-4023-b401-4ac046cf56ac	7607d532-01cb-4685-93d0-019c266c06ca	100.00	2026-08-06 07:24:29.174073+00
e626d9a8-ccf8-44b6-9dc3-350c97a926c4	7607d532-01cb-4685-93d0-019c266c06ca	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:24:29.215297+00
d6bc9899-a986-4d95-ab7f-d89ebd095493	7607d532-01cb-4685-93d0-019c266c06ca	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:24:29.254243+00
63a0c763-6789-4771-8881-1101339993a6	7607d532-01cb-4685-93d0-019c266c06ca	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 07:24:29.288755+00
622971d2-6a63-4e75-bf95-93431ef7ba8f	7607d532-01cb-4685-93d0-019c266c06ca	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 07:24:29.336577+00
4bbe1490-e7f7-4b45-af94-0bad2209ad6e	86061e0a-d9e9-4fd4-91cc-f4113ffece92	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:24:51.96176+00
4fbc82ce-23f6-4fdc-9899-e838a9f4fae1	86061e0a-d9e9-4fd4-91cc-f4113ffece92	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:24:52.003167+00
5a1389a2-dfce-495e-8beb-523bdd0ee19d	86061e0a-d9e9-4fd4-91cc-f4113ffece92	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:24:52.037422+00
6ec89fbc-655e-44d9-be75-21a40d31a67d	86061e0a-d9e9-4fd4-91cc-f4113ffece92	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:24:52.073588+00
cad3419a-c050-4477-b337-9113a73bd9d7	86061e0a-d9e9-4fd4-91cc-f4113ffece92	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:24:52.107635+00
1fac81da-e485-4dba-bb6d-50efd8a83844	3d8c7d31-67c4-4023-b401-4ac046cf56ac	86061e0a-d9e9-4fd4-91cc-f4113ffece92	100.00	2026-08-06 07:24:52.14664+00
338032e1-598f-43b0-be57-49ecbc9228ac	86061e0a-d9e9-4fd4-91cc-f4113ffece92	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:24:52.18144+00
0b9fe0f3-aab8-4bb0-8a97-2254cb9abd7e	86061e0a-d9e9-4fd4-91cc-f4113ffece92	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:24:52.214759+00
6f574f03-257f-4c12-af47-f554de9f2e00	86061e0a-d9e9-4fd4-91cc-f4113ffece92	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 07:24:52.257593+00
82e0c790-8dd7-49f3-b9ed-e9a69337c250	86061e0a-d9e9-4fd4-91cc-f4113ffece92	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	100.00	2026-08-06 07:24:52.320067+00
9b038776-7592-4093-b25e-19a26bd5f81f	5380e05f-af41-420b-a86b-6661ba12fa65	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:25:21.236763+00
af4f77b3-4d76-4a6b-8d36-063b65595ef8	5380e05f-af41-420b-a86b-6661ba12fa65	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:25:21.279864+00
c26a8dff-e606-4df0-9130-938136d65942	5380e05f-af41-420b-a86b-6661ba12fa65	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:25:21.312998+00
69ead9bb-9c3a-41aa-8005-33777951824b	5380e05f-af41-420b-a86b-6661ba12fa65	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:25:21.346128+00
21875e30-996a-4c3b-a305-6d6727624d56	5380e05f-af41-420b-a86b-6661ba12fa65	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:25:21.380196+00
5b3d008b-f870-4c8b-b083-ef32b4be391a	5380e05f-af41-420b-a86b-6661ba12fa65	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:25:21.416871+00
de6e48fb-43a8-4e00-8f06-659a468d810f	3d8c7d31-67c4-4023-b401-4ac046cf56ac	5380e05f-af41-420b-a86b-6661ba12fa65	100.00	2026-08-06 07:25:21.448128+00
4cadef81-192b-4d64-bc2b-3ae4baa442dd	5380e05f-af41-420b-a86b-6661ba12fa65	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:25:21.491258+00
fed2f3f2-5db8-40eb-96d9-2d5d6543e09b	5380e05f-af41-420b-a86b-6661ba12fa65	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:25:21.52516+00
73681996-37ce-4e31-9476-f290e21c16b2	5380e05f-af41-420b-a86b-6661ba12fa65	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 07:25:21.557883+00
ad21c4c6-3ac9-497a-a949-f355f3d98250	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:25:42.368488+00
3c327f68-879a-4158-8d89-0e3e509591ed	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:25:42.408294+00
f3d653e5-92cc-4a8c-8951-050004b8d132	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:25:42.443298+00
54460887-860a-4b81-b6f6-a3daa2fb5cb1	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:25:42.483965+00
eadd98b2-0e11-48e3-8aac-cb69707c9e43	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:25:42.516653+00
76967099-afa8-47cb-bcfe-ccda3f414b91	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:25:42.578184+00
1cf56594-d79a-4e50-990f-d9d0c6eea157	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	3d8c7d31-67c4-4023-b401-4ac046cf56ac	100.00	2026-08-06 07:25:42.620264+00
ec7d09b9-74da-4c34-b716-3694d51bdb12	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:25:42.667444+00
fa760174-635f-499e-9533-876fdf80c049	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:25:42.699133+00
ea36b60c-6553-4804-8713-0d364de14c37	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	efcd6ed2-c765-4041-9feb-cd72f820ee45	100.00	2026-08-06 07:25:42.732372+00
5094d297-3c82-4f66-a150-28d45512b06a	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	afa30051-73b4-41e7-8b44-fe64122d74c6	100.00	2026-08-06 07:26:08.968755+00
8b2d7e92-ebaa-48ca-ae4a-e91974d2b8b2	afa30051-73b4-41e7-8b44-fe64122d74c6	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:26:09.006776+00
b618d601-edf4-4669-854e-fef71f28748b	afa30051-73b4-41e7-8b44-fe64122d74c6	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:26:09.043829+00
58c0cf33-d670-4434-bb53-68776fd80016	afa30051-73b4-41e7-8b44-fe64122d74c6	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:26:09.077222+00
c1962e2f-a1da-4ec9-9c25-2c10094a46f9	afa30051-73b4-41e7-8b44-fe64122d74c6	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:26:09.113669+00
90b8f38c-fe8c-4cb8-baff-a98f87a42757	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	afa30051-73b4-41e7-8b44-fe64122d74c6	100.00	2026-08-06 07:26:09.146738+00
d177f41c-2d71-470f-8e81-a3e5583d3cae	afa30051-73b4-41e7-8b44-fe64122d74c6	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:26:09.17978+00
556c8d93-3f9d-4401-8d86-ca9047483a0b	3d8c7d31-67c4-4023-b401-4ac046cf56ac	afa30051-73b4-41e7-8b44-fe64122d74c6	100.00	2026-08-06 07:26:09.212037+00
424cfeb4-308a-480b-b12c-989983b45a02	afa30051-73b4-41e7-8b44-fe64122d74c6	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:26:09.269997+00
2101beb6-0a0e-4c1e-b3ef-cc8aa923265b	afa30051-73b4-41e7-8b44-fe64122d74c6	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:26:09.363866+00
14d7442e-a8a0-44de-909c-b2174ac886cf	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	8dce8e30-e3b1-4588-816e-60891d8a3202	100.00	2026-08-06 07:26:51.90062+00
488f1471-fe51-41ea-b2c1-87f60ff3dd77	8dce8e30-e3b1-4588-816e-60891d8a3202	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:26:51.941853+00
4b3cbc2a-c7b1-4794-86db-26d31e850f19	8dce8e30-e3b1-4588-816e-60891d8a3202	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:26:51.987748+00
b92fa5f1-f6eb-4553-ad13-f59fead11dac	8dce8e30-e3b1-4588-816e-60891d8a3202	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:26:52.020905+00
892357dd-573f-4aa1-ace8-b477d44bb3ff	8dce8e30-e3b1-4588-816e-60891d8a3202	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:26:52.054406+00
b6e50989-b348-4e82-a52f-28ddccb3d569	8dce8e30-e3b1-4588-816e-60891d8a3202	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:26:52.087443+00
4b7235cb-f4fb-4e06-8533-036381c60b87	8dce8e30-e3b1-4588-816e-60891d8a3202	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:26:52.127215+00
4c45dd19-fa3e-494b-9bbc-5e1454889ce6	3d8c7d31-67c4-4023-b401-4ac046cf56ac	8dce8e30-e3b1-4588-816e-60891d8a3202	100.00	2026-08-06 07:26:52.156567+00
a19d5d94-5aed-411b-b44b-dad887bbdbbf	8dce8e30-e3b1-4588-816e-60891d8a3202	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:26:52.189438+00
e3ac6cac-ccf9-4596-a356-ba1c97c3b529	8dce8e30-e3b1-4588-816e-60891d8a3202	e576df13-6cd8-44a2-be61-44cb945bc25a	100.00	2026-08-06 07:26:52.230381+00
c65b6708-b9f8-491a-921f-b7ef2028a03f	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.664422+00
d09448ff-b49d-457a-8272-e2ce2c661838	cf8b1225-10c8-42b4-81a9-6dc603b4b753	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.714763+00
7dde8a76-e920-4cc0-bef6-a35a534a2021	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.748604+00
02ff12d9-15dd-480a-b1a4-696c6ac196e3	d7c3fa7c-c268-4e5c-acec-0450571fdb18	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.780053+00
93540eee-5c05-48bf-9e27-f5ff0ef2895e	eaf120d8-bd47-43fc-aa4b-975400c5f579	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:27:04.818085+00
859b6967-eb48-414a-9909-96d2c6d94473	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.856264+00
f31b3486-a502-4c50-b806-b6441414afcb	d4e10fc0-e272-4867-81cd-567a0e84cfdf	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.902295+00
97871235-cda1-48c9-a2ec-b204913daa48	3d8c7d31-67c4-4023-b401-4ac046cf56ac	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:04.951131+00
bd0ef681-7b79-4a83-9698-dd6fb64b1eae	eaf120d8-bd47-43fc-aa4b-975400c5f579	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:27:04.989593+00
0ab5397e-f5a7-4c34-8f16-ec1d9f9d56e3	e576df13-6cd8-44a2-be61-44cb945bc25a	eaf120d8-bd47-43fc-aa4b-975400c5f579	100.00	2026-08-06 07:27:05.029348+00
f3a73e49-ecc2-4fa4-ac32-be4d43a403fc	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	367fdce2-dc07-4945-af3f-22a1305b03e0	100.00	2026-08-06 07:39:26.136825+00
d7f8bdca-d5eb-4905-b821-9349042db6f3	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	100.00	2026-08-06 07:39:26.201384+00
a58da09d-af62-42ff-8e53-e82575777dd0	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:39:26.271454+00
9ec2981d-50a4-4a30-bd97-cded4c24bc0f	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:39:26.324497+00
6ed59705-d085-4b3f-a832-68841946ed2f	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:39:26.384851+00
29a2921c-5fce-425c-b585-aa47b79c7f98	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:39:26.418527+00
f2205f8d-ef1c-4614-9fed-b8c68335e911	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:39:26.453315+00
1f6f5191-3ded-417c-a509-ced2915762bc	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:39:26.485551+00
8de8f71d-53c4-451d-af6b-42f1d4c78cdd	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	3d8c7d31-67c4-4023-b401-4ac046cf56ac	100.00	2026-08-06 07:39:26.528771+00
e5a29ce5-a921-46a3-bdc1-c1d6e4ffdf84	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	fbd4b51b-493b-429d-a938-94354ce49c63	100.00	2026-08-06 07:39:26.586968+00
d348fa6a-0e66-4881-8818-1c2d1c240eb8	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	89f81735-a971-4f31-be35-afce72c93bfc	100.00	2026-08-06 07:40:02.039117+00
ead30b55-109e-465a-81f8-d1af21351b48	367fdce2-dc07-4945-af3f-22a1305b03e0	89f81735-a971-4f31-be35-afce72c93bfc	100.00	2026-08-06 07:40:02.07568+00
03692d18-fd25-4167-8eef-bc986c504607	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	89f81735-a971-4f31-be35-afce72c93bfc	100.00	2026-08-06 07:40:02.107241+00
0d445b80-bb07-4492-876c-45e075eefac1	89f81735-a971-4f31-be35-afce72c93bfc	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:40:02.140629+00
b08f55c6-0903-4f53-92bd-c86cc976b468	89f81735-a971-4f31-be35-afce72c93bfc	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:40:02.174971+00
d53da928-087c-41a3-9725-a3a8b37317a0	89f81735-a971-4f31-be35-afce72c93bfc	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:40:02.232247+00
8b0f3fb8-f978-4361-a975-ff85c845effd	89f81735-a971-4f31-be35-afce72c93bfc	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:40:02.285826+00
0d50df4d-3310-41af-a3b8-952798f84261	89f81735-a971-4f31-be35-afce72c93bfc	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:40:02.395413+00
d2056676-45a6-41d0-b83e-064d18807c59	89f81735-a971-4f31-be35-afce72c93bfc	d4e10fc0-e272-4867-81cd-567a0e84cfdf	100.00	2026-08-06 07:40:02.441565+00
b4822850-87f8-463b-90bb-153e56e45159	3d8c7d31-67c4-4023-b401-4ac046cf56ac	89f81735-a971-4f31-be35-afce72c93bfc	100.00	2026-08-06 07:40:02.471134+00
76144b51-87c6-4629-9c9a-ce90947dbc51	7c916865-cac4-42be-a99b-c45e15e6845e	9a619129-5447-45a7-b1a9-45ca14708e7b	100.00	2026-08-06 07:40:47.266245+00
5782513c-7043-4e5a-8ce3-0650652fedf8	7c916865-cac4-42be-a99b-c45e15e6845e	cf11c185-cff1-4c4c-a254-63c9cae16950	100.00	2026-08-06 07:40:47.307007+00
91eb2905-e2b2-4b1d-a61b-545ad38bb50b	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	7c916865-cac4-42be-a99b-c45e15e6845e	100.00	2026-08-06 07:40:47.341011+00
adb7646b-14b8-40d1-b981-1bbe84cdc690	367fdce2-dc07-4945-af3f-22a1305b03e0	7c916865-cac4-42be-a99b-c45e15e6845e	100.00	2026-08-06 07:40:47.389823+00
1a219dc6-71ba-4a4f-aabd-67031ab9a035	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	7c916865-cac4-42be-a99b-c45e15e6845e	100.00	2026-08-06 07:40:47.423077+00
91e3e0e2-e7cd-4560-bc7e-d91c2e1a9a7f	7c916865-cac4-42be-a99b-c45e15e6845e	cf8b1225-10c8-42b4-81a9-6dc603b4b753	100.00	2026-08-06 07:40:47.454774+00
e417753f-482f-4a81-bc01-d4052f6f881c	7c916865-cac4-42be-a99b-c45e15e6845e	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	100.00	2026-08-06 07:40:47.503755+00
b2308c50-dfa7-4c34-8cdb-7b1464555afd	7c916865-cac4-42be-a99b-c45e15e6845e	d7c3fa7c-c268-4e5c-acec-0450571fdb18	100.00	2026-08-06 07:40:47.542128+00
32cdd052-590f-4c2d-8c45-fb1928768f09	7c916865-cac4-42be-a99b-c45e15e6845e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	100.00	2026-08-06 07:40:47.586991+00
f7ffd5eb-a3e5-44fe-aa39-c5d1ce3a1897	7c916865-cac4-42be-a99b-c45e15e6845e	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	100.00	2026-08-06 07:40:47.621663+00
\.


--
-- Data for Name: Messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Messages" ("MessageId", "SenderUserId", "ReceiverUserId", "Message", "IsRead", "SentOn") FROM stdin;
a0f6b101-7e65-4902-b2a6-a32eb020aa50	f6d46263-407d-429f-aabc-f9e3c7b6aed3	4758c076-09d2-42d8-88cc-cce435637c32	Assalamu alaikum!	t	2026-08-06 06:31:48.761319+00
69c4be74-e664-4e67-80e2-f6b54aee4b2c	4758c076-09d2-42d8-88cc-cce435637c32	f6d46263-407d-429f-aabc-f9e3c7b6aed3	Walaikum assalam!	f	2026-08-06 06:31:49.020456+00
15432e8b-701c-49ac-9c33-b61c057cae02	5ad80524-52fe-43f5-b245-2a7ae49a92cf	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	Assalamu alaikum!	t	2026-08-06 06:31:59.242415+00
0ebb3ce9-c4de-4f8b-9189-d948dcb757df	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	5ad80524-52fe-43f5-b245-2a7ae49a92cf	Walaikum assalam!	f	2026-08-06 06:31:59.473893+00
0ba26e5a-d8b9-4f73-8546-12bc602a4c5f	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	d31b3330-980a-4d38-bf4d-c221a5033bda	Assalamu alaikum!	t	2026-08-06 06:32:22.474833+00
7e05c408-bb81-4124-93e0-878584391a2d	d31b3330-980a-4d38-bf4d-c221a5033bda	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	Walaikum assalam!	f	2026-08-06 06:32:22.89891+00
225d4668-e37d-4f1a-9117-e40c52e6b0d2	e81e56cc-db91-4ddb-b1e8-530510958e6c	25634a36-337f-4d14-a96d-1a843df8614e	Assalamu alaikum!	t	2026-08-06 06:33:17.15455+00
1d872323-d32d-4675-80cc-64739adbd857	25634a36-337f-4d14-a96d-1a843df8614e	e81e56cc-db91-4ddb-b1e8-530510958e6c	Walaikum assalam!	f	2026-08-06 06:33:17.428495+00
415b2aeb-1129-4a97-94a8-b3fc8ed29072	730aab59-18e5-4343-8ea5-20d21d417f9a	b23ee7a2-7e56-495e-96b8-f1253aeaea36	Assalamu alaikum!	t	2026-08-06 06:33:54.123968+00
c36f6a28-d08f-4403-a339-844b2cbc6156	b23ee7a2-7e56-495e-96b8-f1253aeaea36	730aab59-18e5-4343-8ea5-20d21d417f9a	Walaikum assalam!	f	2026-08-06 06:33:54.378975+00
fcedd1c1-07f1-4c78-9d06-5494ad451263	bba02b1e-aae7-4873-9983-7a8196db808b	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	Assalamu alaikum, how are you?	t	2026-08-06 06:35:35.494938+00
66c55f76-3a00-4086-bf95-c4a6199bae6a	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	bba02b1e-aae7-4873-9983-7a8196db808b	Walaikum assalam! I am good, you?	f	2026-08-06 06:35:35.678744+00
6856820e-d733-48da-b55b-574781098cf0	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	Hi, testing chat	t	2026-08-06 06:57:45.067747+00
0d589592-6b3b-41e0-9102-98d17545d3be	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	Hello from the browser test!	t	2026-08-06 07:01:58.958751+00
2a954f9e-4dc6-4e80-b5fa-1c00d1ee5228	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	asslamualykum	t	2026-08-06 07:03:16.767745+00
47248841-b8ba-45d5-a13a-69212fb71de4	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	walkekum salam	t	2026-08-06 07:04:13.700404+00
d48f879b-ea09-4e71-a3d2-f4b5e09a3717	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	kya haal	t	2026-08-06 07:04:23.352066+00
b8fd4a54-156b-4c36-ac0e-590fceccaa3d	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	masts	t	2026-08-06 07:04:28.442919+00
f8493688-1ebf-41a4-b17e-f0a79f4bf712	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	aur bataoa	t	2026-08-06 07:04:37.580173+00
218b5ed6-458c-4714-8cb2-80227b50f28d	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	good	t	2026-08-06 07:04:48.309017+00
ad2ed764-67ab-4c5f-ad80-ca97ce460643	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	hkio	t	2026-08-06 07:06:00.115006+00
e48142f0-ebe8-43fe-b6c5-00f3830ede9a	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	hello	t	2026-08-06 07:06:22.379743+00
9ffde106-c086-44c1-a95b-b286730e0b27	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	han	t	2026-08-06 07:07:16.974907+00
59195e7c-6b9f-4afa-b9f8-5fcdf0f7c477	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	kya hua	t	2026-08-06 07:07:38.956818+00
0dc6f8af-ed56-4217-9c1a-d366debb7c9f	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	yes	t	2026-08-06 07:08:06.805446+00
e9a19d9c-46e5-4c3e-9e94-ef3d6034c412	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	aur	t	2026-08-06 07:08:09.521827+00
85f37299-13cf-48bc-9530-b6d26b25829e	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	kya	t	2026-08-06 07:08:11.780016+00
ff781da1-e995-4d2b-b542-a30193613912	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	hall	t	2026-08-06 07:08:13.056981+00
d69baace-310f-4b1a-b99d-5a4d7fc0decf	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	hai	t	2026-08-06 07:08:14.166524+00
5d406b28-8d85-437a-8956-e4a65e5503ff	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	Test toast — can you see this pop up?	t	2026-08-06 07:16:39.356865+00
bd6616ef-168a-4829-a937-93575fdf4a7c	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	yes	t	2026-08-06 07:19:02.818716+00
6d1c1579-5a6a-4623-a92f-8e936532fe1b	b3e94172-8013-4cdc-b429-33dd88309863	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	Assalamu alaikum!	t	2026-08-06 07:24:32.900763+00
c3426442-be6f-4bf0-81a2-32c576ae1d26	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	b3e94172-8013-4cdc-b429-33dd88309863	Walaikum assalam!	f	2026-08-06 07:24:33.144561+00
77f12fc5-27bf-4db9-835e-a2d0b0f25b66	f20698bd-7049-4b40-8d92-c62216637198	b53dcfda-741c-4278-a232-6c0f18ad2805	Assalamu alaikum!	t	2026-08-06 07:25:03.44963+00
3f3aa3ad-261e-4bf3-b8cc-e89301bba833	b53dcfda-741c-4278-a232-6c0f18ad2805	f20698bd-7049-4b40-8d92-c62216637198	Walaikum assalam!	f	2026-08-06 07:25:04.374129+00
be00f5ee-daae-40c1-bac9-db5667873588	30a21658-542f-4803-a13c-651be1e25909	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	Assalamu alaikum!	t	2026-08-06 07:25:46.091515+00
40c9fac6-92d8-4436-950c-2a1af718e610	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	30a21658-542f-4803-a13c-651be1e25909	Walaikum assalam!	f	2026-08-06 07:25:46.342553+00
55e265a2-3254-45a1-b8c2-58143434912d	d91dd487-28c3-4f03-8206-3d7bc12e0765	b4163d69-9347-4fb5-8edf-0a58dedfd768	Assalamu alaikum!	t	2026-08-06 07:27:15.197458+00
2a59db3b-7716-4fcc-a58e-71efd1389d90	b4163d69-9347-4fb5-8edf-0a58dedfd768	d91dd487-28c3-4f03-8206-3d7bc12e0765	Walaikum assalam!	f	2026-08-06 07:27:15.423916+00
944cab75-2f7e-41b1-93d1-2476c67fb2c9	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	hello	t	2026-08-06 07:24:01.003963+00
1f230a91-a986-41c8-a6ad-702236a73e5c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	Toast test — click me to open chat	t	2026-08-06 07:28:09.925439+00
58d172e1-70ab-431b-9e5c-b148b88a7b1e	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	hello	t	2026-08-06 07:29:50.372768+00
363e4361-9ab4-4b8c-a683-35feb640ebb3	7ea9daf4-0016-43c4-b811-70ec6b60254d	c3b43f87-73b1-435c-94a0-c45939b5ee02	Assalamu alaikum!	t	2026-08-06 07:39:38.165226+00
28153ea8-dc5f-4d46-91fb-50cf66418f86	c3b43f87-73b1-435c-94a0-c45939b5ee02	7ea9daf4-0016-43c4-b811-70ec6b60254d	Walaikum assalam!	f	2026-08-06 07:39:38.530872+00
24817782-6d2c-4903-94d9-51897b849bd6	77a4ff3b-0afa-4776-8504-a026984e3b14	0a0ca69a-734a-464d-846d-03905795c51c	Assalamu alaikum!	t	2026-08-06 07:40:10.792662+00
535bde6b-8340-4e69-a0d8-fefafa9db110	0a0ca69a-734a-464d-846d-03905795c51c	77a4ff3b-0afa-4776-8504-a026984e3b14	Walaikum assalam!	f	2026-08-06 07:40:11.078681+00
7f71e9a6-15b7-404e-a150-8005859188af	215f7372-6d92-40ec-9f9a-1879debb080d	0270429b-5a36-466a-82f5-0dbe02c49821	Assalamu alaikum!	t	2026-08-06 07:40:54.480777+00
460dedcd-f197-49b2-bd90-524bb3ec4f0d	0270429b-5a36-466a-82f5-0dbe02c49821	215f7372-6d92-40ec-9f9a-1879debb080d	Walaikum assalam!	f	2026-08-06 07:40:54.723276+00
\.


--
-- Data for Name: Notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Notifications" ("NotificationId", "UserId", "Title", "Message", "IsRead", "CreatedOn", "RefUserId") FROM stdin;
99c6c597-ae53-4aef-949d-253cedd5e8ba	f6d46263-407d-429f-aabc-f9e3c7b6aed3	New message	User sent you a message	f	2026-08-06 06:31:49.093011+00	\N
83c6cd83-9a00-4dc3-b201-b72231aa1ae5	4758c076-09d2-42d8-88cc-cce435637c32	New message	User sent you a message	t	2026-08-06 06:31:48.827765+00	\N
729b6ec7-da4b-4d51-a505-4664bee2e742	5ad80524-52fe-43f5-b245-2a7ae49a92cf	New message	User sent you a message	f	2026-08-06 06:31:59.545758+00	\N
9c8043b9-f8a8-4391-80c9-ab25473ba582	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	New message	User sent you a message	t	2026-08-06 06:31:59.307232+00	\N
97180685-f8eb-44cb-9f18-e0783bc5219d	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	New message	User sent you a message	f	2026-08-06 06:32:23.022773+00	\N
69cd3bfd-35cf-4c16-add2-f0af3851d124	d31b3330-980a-4d38-bf4d-c221a5033bda	New message	User sent you a message	t	2026-08-06 06:32:22.597113+00	\N
04896d42-4738-4bb8-a16b-36e548322038	e81e56cc-db91-4ddb-b1e8-530510958e6c	New message	User sent you a message	f	2026-08-06 06:33:17.493783+00	\N
7d630544-a818-4fe0-9a66-c1cc3dd79799	25634a36-337f-4d14-a96d-1a843df8614e	New message	User sent you a message	t	2026-08-06 06:33:17.249964+00	\N
749451a8-ebd7-4512-a3ba-e9e42c588808	730aab59-18e5-4343-8ea5-20d21d417f9a	New message	User sent you a message	f	2026-08-06 06:33:54.444487+00	\N
a2363561-9634-4205-8419-2711edd6264f	b23ee7a2-7e56-495e-96b8-f1253aeaea36	New message	User sent you a message	t	2026-08-06 06:33:54.205443+00	\N
25d0a6cc-ae45-4d34-bcf8-8522b694c378	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	New message	User sent you a message	f	2026-08-06 06:35:35.501805+00	\N
ec30734b-849d-4bd0-895b-86e2144aa699	bba02b1e-aae7-4873-9983-7a8196db808b	New message	User sent you a message	t	2026-08-06 06:35:35.726485+00	\N
0d6c46d4-9a79-4ff5-be0a-49b7cc8f91f2	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:03:16.776076+00	\N
94dea25e-0ccb-4b2e-a071-0cdd2c8250dc	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:04:23.356778+00	\N
4d610fc8-91d7-4e7b-83b6-a5ac5cc53012	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:04:48.317542+00	\N
ceaa40fd-0f6b-4d28-8569-26f1bee95578	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 06:57:45.075306+00	\N
b4c61061-6717-4874-87e3-d8890abd76ef	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:01:58.96467+00	\N
2d3d41dc-5a3d-4450-9dea-7b59ec530da1	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:04:13.708255+00	\N
564df7af-7006-4668-b92c-cc4308af2222	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:04:28.451368+00	\N
c8b92936-6102-42fc-957c-8f194a7130be	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:04:37.586194+00	\N
672b5968-2f0b-4c41-aad9-f4549ba9aa3a	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:06:00.118647+00	\N
f442e16f-c40a-4d2c-bab8-8327d519cc25	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:06:22.387504+00	\N
e27139b3-c834-40ea-bc44-3c98b6cdfb33	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:08:06.827557+00	\N
5c8a8960-2f28-4be2-9f39-9776e10a7e5b	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:08:09.530834+00	\N
95a7f7e0-87c4-4a49-ab8a-a355d4a4c60f	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:08:11.787811+00	\N
e33d2421-f6f4-41ae-8cfd-8f6d4e333377	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:08:13.091746+00	\N
c0df6492-aa38-4a9f-a3eb-71f4efec0d17	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	t	2026-08-06 07:08:14.17637+00	\N
24ef362d-28e0-4b62-afc6-70167e2e7bf9	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:07:16.980519+00	\N
fe866a9d-cef8-4363-8a97-c6dd10030db7	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:07:38.973404+00	\N
629cb9ef-5a72-40dd-820d-3e8639a0ad6b	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	New message	User sent you a message	f	2026-08-06 07:19:02.826199+00	\N
d2380436-24aa-429b-8fb4-62f6f622a9c4	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	t	2026-08-06 07:16:39.365084+00	\N
ab4bbd84-6f65-4c62-9ee4-f61062aaacc4	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	f	2026-08-06 07:24:01.034735+00	\N
a727a6c3-617f-444e-b5a1-61e2b6d2de8b	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	Interest	User is interested in your profile	f	2026-08-06 07:24:25.321809+00	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8
bae62c4d-f174-4d74-89a0-c709cb7065a0	b3e94172-8013-4cdc-b429-33dd88309863	New message	User sent you a message	f	2026-08-06 07:24:33.213853+00	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b
18f99ebf-d100-42e0-84fb-a34ea501befc	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	Interest	User is interested in your profile	t	2026-08-06 07:24:31.867644+00	b3e94172-8013-4cdc-b429-33dd88309863
bdc593da-25c3-4872-85ae-95300e1def93	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	New message	User sent you a message	t	2026-08-06 07:24:32.967741+00	b3e94172-8013-4cdc-b429-33dd88309863
05353318-d545-4fd4-893e-55541be5a2d8	cf8b1225-10c8-42b4-81a9-6dc603b4b753	Interest	User is interested in your profile	f	2026-08-06 07:24:59.243918+00	ddcd3ad5-423b-436e-b921-4322d3397be4
c87c522c-e712-4c28-bc26-edf72d04a39a	f20698bd-7049-4b40-8d92-c62216637198	New message	User sent you a message	f	2026-08-06 07:25:04.620013+00	b53dcfda-741c-4278-a232-6c0f18ad2805
5168790d-c9e7-4163-be40-2d3b02ecbd2f	b53dcfda-741c-4278-a232-6c0f18ad2805	Interest	User is interested in your profile	t	2026-08-06 07:25:01.917674+00	f20698bd-7049-4b40-8d92-c62216637198
b9df4235-f45b-4840-b4ce-ae320a7cc3be	b53dcfda-741c-4278-a232-6c0f18ad2805	New message	User sent you a message	t	2026-08-06 07:25:03.572168+00	f20698bd-7049-4b40-8d92-c62216637198
1edeb2e6-75a9-45e4-8c86-53c33e37b059	30a21658-542f-4803-a13c-651be1e25909	New message	User sent you a message	f	2026-08-06 07:25:46.412889+00	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d
d8a8dc61-e2e6-41f8-913a-242ae8394d7e	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	Interest	User is interested in your profile	t	2026-08-06 07:25:45.335083+00	30a21658-542f-4803-a13c-651be1e25909
6d93c698-91bf-49dc-ad40-c61daa9655ec	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	New message	User sent you a message	t	2026-08-06 07:25:46.155765+00	30a21658-542f-4803-a13c-651be1e25909
ec8f385b-74b0-4722-8706-9df9b6921fa0	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	Interest	User is interested in your profile	f	2026-08-06 07:25:49.660957+00	19d0db83-6560-4103-ac51-6d11e51c4d76
10659108-b9ac-4c06-951e-52a8b670afbb	367fdce2-dc07-4945-af3f-22a1305b03e0	Interest	User is interested in your profile	f	2026-08-06 07:27:08.333883+00	7eb32340-5dc9-4180-ae5f-626b2090eb41
8ade1f38-6731-4261-a39d-906ea3bdbd46	d91dd487-28c3-4f03-8206-3d7bc12e0765	New message	User sent you a message	f	2026-08-06 07:27:15.550949+00	b4163d69-9347-4fb5-8edf-0a58dedfd768
f49826db-f4f0-4cd9-98a8-239e61adcba5	b4163d69-9347-4fb5-8edf-0a58dedfd768	Interest	User is interested in your profile	t	2026-08-06 07:27:14.495763+00	d91dd487-28c3-4f03-8206-3d7bc12e0765
6ef398d3-1574-48d0-890c-5470dc4aff65	b4163d69-9347-4fb5-8edf-0a58dedfd768	New message	User sent you a message	t	2026-08-06 07:27:15.258509+00	d91dd487-28c3-4f03-8206-3d7bc12e0765
8b44babd-e983-4939-85f4-d2251114c063	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	f	2026-08-06 07:28:09.931648+00	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358
f398dd95-b7e7-4c97-a9a6-f90fd155de16	886d75e0-e090-4177-a6d8-570db8b1208c	New message	Aaquib sent you a message	f	2026-08-06 07:29:50.387737+00	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358
80fb0cad-7d06-4880-9145-093217a5c1f9	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	Interest	User is interested in your profile	f	2026-08-06 07:39:33.54014+00	3bd0bf00-d276-46c2-ae5b-11870c818ec5
2972fdd8-97eb-4ad3-8352-07c8f5d6528b	7ea9daf4-0016-43c4-b811-70ec6b60254d	New message	User sent you a message	f	2026-08-06 07:39:38.662305+00	c3b43f87-73b1-435c-94a0-c45939b5ee02
cd27c86e-bafe-4f88-8068-b39651a874c6	c3b43f87-73b1-435c-94a0-c45939b5ee02	Interest	User is interested in your profile	t	2026-08-06 07:39:37.043465+00	7ea9daf4-0016-43c4-b811-70ec6b60254d
b72152b2-eb92-4baf-aa3b-1f1a38b29c54	c3b43f87-73b1-435c-94a0-c45939b5ee02	New message	User sent you a message	t	2026-08-06 07:39:38.313757+00	7ea9daf4-0016-43c4-b811-70ec6b60254d
7028907a-5eeb-4b76-b178-f3c25000079e	cf11c185-cff1-4c4c-a254-63c9cae16950	Interest	User is interested in your profile	f	2026-08-06 07:40:06.436927+00	c118f901-1a69-4866-98b8-677f315742a1
4e783c1e-da39-49fa-8125-0481f8a1309c	77a4ff3b-0afa-4776-8504-a026984e3b14	New message	User sent you a message	f	2026-08-06 07:40:11.158845+00	0a0ca69a-734a-464d-846d-03905795c51c
046eee50-83bf-471e-82dd-19a3341ae964	0a0ca69a-734a-464d-846d-03905795c51c	Interest	User is interested in your profile	t	2026-08-06 07:40:09.961807+00	77a4ff3b-0afa-4776-8504-a026984e3b14
c20cbbd2-f2b8-4eeb-9d57-b322e7da9e3c	0a0ca69a-734a-464d-846d-03905795c51c	New message	User sent you a message	t	2026-08-06 07:40:10.875724+00	77a4ff3b-0afa-4776-8504-a026984e3b14
e0b3181b-63a1-4e2c-adb9-a827df8f7ff8	9a619129-5447-45a7-b1a9-45ca14708e7b	Interest	User is interested in your profile	f	2026-08-06 07:40:43.455606+00	087c71fc-5bd8-4fca-b1fc-0eb50342aeee
0ea3bf6c-cad4-4a65-bf90-973c780b5158	215f7372-6d92-40ec-9f9a-1879debb080d	New message	User sent you a message	f	2026-08-06 07:40:54.786092+00	0270429b-5a36-466a-82f5-0dbe02c49821
f9f80cbd-9827-43cd-9531-2dc2469b6272	0270429b-5a36-466a-82f5-0dbe02c49821	Interest	User is interested in your profile	t	2026-08-06 07:40:53.786866+00	215f7372-6d92-40ec-9f9a-1879debb080d
ca643bc8-d1a1-4759-8f7c-529eb085b85c	0270429b-5a36-466a-82f5-0dbe02c49821	New message	User sent you a message	t	2026-08-06 07:40:54.549243+00	215f7372-6d92-40ec-9f9a-1879debb080d
\.


--
-- Data for Name: OTPRequests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OTPRequests" ("OTPRequestId", "UserId", "Phone", "OTPHash", "IsVerified", "ExpiresOn", "CreatedOn") FROM stdin;
daf567eb-6767-4d3f-923d-878e010262fa	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$jGsA4qsc/pT2HJCqR5QzjemelA7na9OCc2WBbAS8MD4bOLMAaQDDe	t	2026-08-05 10:27:05.479309+00	2026-08-05 10:22:05.479309+00
7ca812aa-78ad-40f1-9daf-0c29716bfcce	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$5CFtMUW8LSNJFvsK1VVBbOhDrM0DD3/zKGGylnG87Ydz2nFXjABQK	f	2026-08-05 04:07:44.381881+00	2026-08-05 04:02:44.381881+00
f93ce6e7-2b23-4c17-acea-480dbf369426	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$dN2XZYEsWvrj/XBZ5895L.mvKOamjDFKhD5MZ3i1y1Gab51sbSCoG	t	2026-08-05 04:07:50.336493+00	2026-08-05 04:02:50.336493+00
5e16b250-978d-42eb-b3c3-763097c95047	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$SZnTq0BBCVZ8k55TZw2EJek3N7Om8wWBA4OM/t/uXarqWXw5KNpqC	f	2026-08-05 04:08:15.97559+00	2026-08-05 04:03:15.97559+00
ef38ef33-cc7b-433d-aada-3aebd281951a	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$EFjx/MNmCaO0SY3uCCSlgO3fbsiCmWt5q3UQ0H9hw9jVCbmIM3gKu	t	2026-08-05 06:56:07.892933+00	2026-08-05 06:51:07.892933+00
b08cb5d1-4f06-46f1-add0-f8ed4c113b46	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$Hn4NfdbmhDiGOnroD5Um2OG6N6rlTsGyGk.gWY/JLEK0UjaXZz0eS	t	2026-08-05 07:01:51.339281+00	2026-08-05 06:56:51.339281+00
00db0899-81d5-4d45-bf24-022f9f31e980	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$vhbSkrMkTtRa41A.h6qY4uaGGffaS0RU5N6XOJkmTnovoz2RlBlI6	t	2026-08-05 07:02:59.5902+00	2026-08-05 06:57:59.5902+00
70597e11-cc78-47cf-a241-da571d0cfe92	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$982Gb.j/TiVttfB8I7kwC..oP/5buR7p67c6X1STU15YW40adWTmm	t	2026-08-05 07:04:20.505518+00	2026-08-05 06:59:20.505518+00
4e3e9097-c1af-4109-b544-9dc179279ad6	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$.CmJi5.g7WaN.rnqMWhMGu8lu5/TbAwX/GLHEKeX94n5TsuDLAlhK	t	2026-08-05 07:05:19.078679+00	2026-08-05 07:00:19.078679+00
699a9ef3-952e-4832-ae86-8db5c6e05964	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$Cvvp9uuVD6KEVhH2Lksi/uNAViVWGFiMgQ5U4E/Xr8DJ4Ac45jPY2	t	2026-08-05 07:06:22.793434+00	2026-08-05 07:01:22.793434+00
a9e5a6e7-f042-4562-82ee-97e263834c0a	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$UnTSJQbILdj4uqmqKKFf8Oe/QM4/9O42EhUFlHIxtTAZ4JzE2nRpW	t	2026-08-05 07:07:22.481741+00	2026-08-05 07:02:22.481741+00
52ea862e-647e-4bc0-8d6e-7a61c9c5168d	8f3769a0-51a7-4bb1-93b0-836742c705b2	+919812345678	$2b$10$zXD.NG.ANrZVpnpf6aztkO3MrVvoz9uH8RhKAeueILi8iuU4LoZi2	t	2026-08-05 07:09:05.668744+00	2026-08-05 07:04:05.668744+00
951789b0-3547-4046-9574-80bd746af6fc	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$p/BGQza2IaBEHdrO8QHfl.YGsAYbn6cQBEDCvlBZU41tHfsDUqX8G	f	2026-08-05 07:27:04.714752+00	2026-08-05 07:22:04.714752+00
2ef95abe-26db-4205-96f5-cd187116a557	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$ioAg/pl/FAfM7Vy7iQ2LbO/nRRMMo8PGto.snetLvEAar.N22pGkS	t	2026-08-05 07:27:17.089932+00	2026-08-05 07:22:17.089932+00
63774a79-78aa-43f5-b994-c30725e95f2f	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$ozvN6qhOo8D.bEtKNY7PWeMeWCKXSa7mJP8M5stpboU9ZHVAzrsk.	f	2026-08-05 07:27:41.947682+00	2026-08-05 07:22:41.947682+00
d78af163-30f5-42c5-b222-2dc6c120ff3c	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$rJa3Kme2G0y45wJO7gTKWOYWxbveF9WJmjOF7aXH5/dP6/T7zvE6u	f	2026-08-05 07:27:43.932024+00	2026-08-05 07:22:43.932024+00
6cbf26b2-245a-478b-aaad-1666f371217f	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$i9cceBTWE8CzAKlEjajeUODxZSC3606Wf5TSH1lO83pPc3QqhDhF.	f	2026-08-05 07:27:45.038742+00	2026-08-05 07:22:45.038742+00
60292c7a-8336-45a0-a629-d6bb5cf12aed	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$AqH8ZXENMlhX2YJMTFezyejk58mtz17D.CBh6QvWg3aUtPadI9NhS	f	2026-08-05 07:27:46.416039+00	2026-08-05 07:22:46.416039+00
515b3c83-8457-408a-830e-63f129d8b888	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$rO6H7MlJZ0b0dDcp3JTemehmZNgPQu9ZlGq.Bbv2Jm3jRr3wIoMYW	f	2026-08-05 07:27:48.549921+00	2026-08-05 07:22:48.549921+00
9a79dfb7-6409-430b-80de-5e59244c7eab	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$7fZan0dTK/Ax7V6CwxI4o.nX0oBxeoRqL3e5VzC2shSJs6GdEvgRy	f	2026-08-05 07:27:49.472522+00	2026-08-05 07:22:49.472522+00
8fb01a70-720a-4a35-b5fb-60e4581c1008	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$HpYBFMGnu.xFrY9XlGT.I.SiDeH233OF0WUKePrwECNihileN3bWW	f	2026-08-05 07:27:50.694784+00	2026-08-05 07:22:50.694784+00
084e1fa6-35ff-4021-8cb1-75eca8f0312e	46f8f2e6-f83f-4a03-9c6c-684a91372144	aaquib4u@gmail.com	$2b$10$sFdCJQMTGbzX.Tgw79rPkuzUOD3eS8uXPtFHac5d63Za8HGwsUhqe	t	2026-08-05 07:28:00.867406+00	2026-08-05 07:23:00.867406+00
2f666ce9-79fc-4575-9921-0f34b429eafe	6b185805-10cb-4f1a-9e15-3168dc691745	+9198msfwie6f	$2b$10$u2RtERRp/Iy9frgXuQ1RO.AukJNrojTSfy2BlahaP6IHsh40w4UDC	f	2026-08-05 09:50:17.338755+00	2026-08-05 09:45:17.338755+00
22e9d1d6-85cc-4f25-b97f-5ee8a101d56a	6b185805-10cb-4f1a-9e15-3168dc691745	+9198msfwie6f	$2b$10$Tu98SnXW.leGSgpwPgv9zeF6U3q3aj1Y9FHOIPSb0RpOL87ZuTZsy	t	2026-08-05 09:50:17.639166+00	2026-08-05 09:45:17.639166+00
3327b6c9-180c-47f1-81d9-31d65a655a40	b78a2599-3f86-49da-9570-4d094ab240e7	+9198msfwin6d	$2b$10$Yu6QMj66k.p23Z5R/rBYN.l2MgD.DGFAVVcWTG4sy/xI/c6oA77WC	f	2026-08-05 09:50:29.480268+00	2026-08-05 09:45:29.480268+00
4e140f1f-f5a5-46b1-bd6f-d0ffb6535327	b78a2599-3f86-49da-9570-4d094ab240e7	+9198msfwin6d	$2b$10$NaNB7gRe7rxSXRblhKeTi.Ih25VDs0tLwo.NXvkiz5HSVgnNcSgCu	t	2026-08-05 09:50:29.779713+00	2026-08-05 09:45:29.779713+00
c5529e3e-09ea-4a7b-86e4-ce7eaac65b17	4c4b64db-a7b1-40cf-98cb-357738726bc7	+9198msfwj7k3	$2b$10$WzpIl9Xn0UT4sohOkV7S6eWqQmQIU605N2vfz/O4ndJKiPuFzlwkG	f	2026-08-05 09:50:55.00845+00	2026-08-05 09:45:55.00845+00
e754914e-47c0-4b57-a4c6-d677218c57ab	4c4b64db-a7b1-40cf-98cb-357738726bc7	+9198msfwj7k3	$2b$10$SXyR6dxu75KjaZ2a/q8N/.QCv3NzW3VVCGD85qRpOttPpIFqWwFb2	t	2026-08-05 09:50:55.347905+00	2026-08-05 09:45:55.347905+00
37d51662-09a2-452c-91a8-581c19d97804	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$JQqkTrcs.pr5M2CnSltr9eKd8AMPajCW8h9jNhQQ8Rq.MUgb5OovG	t	2026-08-05 09:53:51.602756+00	2026-08-05 09:48:51.602756+00
4a7cd925-5e44-42bb-b4bf-f9ae9fff57b6	46f8f2e6-f83f-4a03-9c6c-684a91372144	aaquib4u@gmail.com	$2b$10$lQxPjAi0ViqykGpSVo3FeOEtPhSwuODCfujIPilxbcpyE7erWz/2m	t	2026-08-05 10:18:48.630763+00	2026-08-05 10:13:48.630763+00
f6b1fd7a-aefa-4fee-8c89-c9e563487351	60f50480-cbe7-45b2-b94a-462ddc882514	+9198msfxzsij	$2b$10$qjQgSwALNurGVOmbA.CgKeN79uqiYiLjj2.zGUfTxR.6.AKYHLE9G	t	2026-08-05 10:31:46.336797+00	2026-08-05 10:26:46.336797+00
778fe328-fc75-4257-be96-fd68b2a659ef	5b90a2de-8e41-493d-8311-e21b2e27a452	+9198msfxzzwn	$2b$10$zwqvZmj3tppWlvzHKSQC/OIoxn48h99Wu4ibIfMedKwWzre8nnHYe	t	2026-08-05 10:31:55.758878+00	2026-08-05 10:26:55.758878+00
786eeac0-baaa-4742-adcf-84bb1b38cf0e	a36f9544-213a-4594-887d-680b70dd32fb	+9198msfy0234	$2b$10$mEWbCn.ZIM4U0NUmxTZ.1uY5z1vVga.n9jRkgPU7TbBmINal/xqRK	f	2026-08-05 10:32:01.343839+00	2026-08-05 10:27:01.343839+00
e7cdad85-846e-45bf-9878-b531602f5380	a36f9544-213a-4594-887d-680b70dd32fb	+9198msfy0234	$2b$10$1yFM98dVJzc7sP1xI2OrE.Mq8/uME7kw4KCY7i34qF9SK7YSzipv2	t	2026-08-05 10:32:01.636891+00	2026-08-05 10:27:01.636891+00
09675839-b722-45c6-bf51-d9b0ff09f385	46f8f2e6-f83f-4a03-9c6c-684a91372144	aaquib4u@gmail.com	$2b$10$A3QOp3zwGNqxWeF.vqv5UOi2qibTxxzTdPrsw0a58s6mcahjctAfq	t	2026-08-05 11:00:45.120156+00	2026-08-05 10:55:45.120156+00
d77e67be-d488-44ac-8aa3-8584de9eafe0	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$gsEawmtgIAIf0C8geinpFODQGlE7Fo0HiKJE3INj3RuwIikFy25za	t	2026-08-05 11:02:30.538891+00	2026-08-05 10:57:30.538891+00
70d86ee3-6e43-435b-9716-439c857d379f	b9a9e0e7-72fd-4eef-9c0b-4ee5c0158432	8004362634 	$2b$10$eK05d4dKgfkvYi.ZIYnjSOUaAP/3Zsbn9dcwE7hoqTlmsD79.UN5.	t	2026-08-05 11:04:37.932842+00	2026-08-05 10:59:37.932842+00
dfdcd7c6-8b57-4955-8d14-fe11602ea0dd	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$LPTvLi4euSbZ8OFxSO0q0eIrOQauMmYw4oHonMG0JfAqdhmemo5yy	t	2026-08-05 11:08:07.420947+00	2026-08-05 11:03:07.420947+00
60c2f2d8-4ba4-413c-a363-f75356a54d4f	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$sLlDkjFDT.pBRN0.7Juj/.8Kf7A4qI22KvinnjIEprXKnspIFn2U2	t	2026-08-05 11:09:46.155455+00	2026-08-05 11:04:46.155455+00
e0b79fb4-e96e-4c4a-ad1b-6e09bdbc2a57	bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	+9197msfznc78	$2b$10$gGVXEzQDz6iJHvrfP16NGOCsqtdEyzhvTZnZxobKXXRV/6EuU2Z6m	t	2026-08-05 11:18:05.336626+00	2026-08-05 11:13:05.336626+00
ab89bf88-24fb-4976-81b5-19f8c1dcf0b1	624934b7-aa0d-4f5f-9273-5698f83ac494	+9197msfznniw	$2b$10$rQDfoAbYafLECz7byHIwNOy53S5115UU7rkNS4mIUQCK9jfVLJm2y	t	2026-08-05 11:18:19.498272+00	2026-08-05 11:13:19.498272+00
63c33835-b2d4-43b6-a113-70b8d07911fc	2b1e1113-1628-49d1-be26-eff461ad7395	+9197msfznud0	$2b$10$d8RVIJZilBgMJwjFdqUMpuuTrbplsE7CV/N7gbELn3iGqdRJX3T3C	t	2026-08-05 11:18:27.896711+00	2026-08-05 11:13:27.896711+00
568f7493-13af-4131-866e-08dcf2d2cdea	c87d0759-ca5d-45db-b827-62210ce3b125	+9197msg07k44	$2b$10$OWJ2wnD60yY4sH7PDaMm8.qm1m9dMsDeQed9Q08szM/lowDSFsvyS	t	2026-08-05 11:33:49.115751+00	2026-08-05 11:28:49.115751+00
d9a18389-7663-40cc-9652-ef398de23b6c	fb7f5234-b6df-4a37-99c3-1adeae58416c	+9197msg07uct	$2b$10$iOispA2I/kwQHLXELQcynefF2ICaxNywY1uIGms7odLwydmpTQyIG	t	2026-08-05 11:34:03.205644+00	2026-08-05 11:29:03.205644+00
737a0983-49a9-416d-9bde-002aee8a9997	36abc252-b881-46f8-add5-7549fcf1c02c	+9197msg08e73	$2b$10$JoDK9BvRBq4E7.HlgzQRTO1G9kbp9eyB7lBnl9eRkM23jXWu/mtjy	t	2026-08-05 11:34:28.354839+00	2026-08-05 11:29:28.354839+00
d8e5be32-e623-490b-8b68-d599bdd343db	318ed88a-c7bf-4ab7-b73a-85007e92a400	+9197msg36e58	$2b$10$5y34sBr5KpAGN/PgMrtVLOXF0TxislhmHrnNmIBVZBj9MdL/dJ.cW	t	2026-08-05 12:56:53.135046+00	2026-08-05 12:51:53.135046+00
ede6c811-08fb-4499-bcff-9c520d5ca18e	61c7677e-2d35-423c-9088-77f26fd210ec	+9197msg36tua	$2b$10$UNW26bEkTaqAqij8qGgUquA1B61Ez4E/6osZwfuTlVtHQUcweJNTO	t	2026-08-05 12:57:13.400781+00	2026-08-05 12:52:13.400781+00
4014d22f-b3b3-4146-accd-7c3f685c872e	ef29ab34-0926-4d68-b3a8-f9972bb2a232	+9197msg37cgf	$2b$10$l9DAHi2lT8bh9e015/N6jO9ASz6b4miIMZk2TdGb3c1AeVT48Moky	t	2026-08-05 12:57:37.057887+00	2026-08-05 12:52:37.057887+00
9f541219-daae-48e8-8479-62e06a47c81c	dc416aae-d920-4b18-a151-fd516b79bc27	+9197msg37p24	$2b$10$E7H1ZxIw20iOBjuNu//Ea.ASatZpMnjSeXm/fPiFUU5xQif7oq336	t	2026-08-05 12:57:53.422205+00	2026-08-05 12:52:53.422205+00
ded77168-a60f-4040-9a29-bce1fbda3814	ba861ecb-15ed-4eb9-a10e-3162b7d25a5c	+9198msg37s1n	$2b$10$ZDU9Qhb9P8p2cEr2hT/du.NDPW06t9t2pTXmy0lSQyXeuKM/rf3om	f	2026-08-05 12:58:02.556754+00	2026-08-05 12:53:02.556754+00
ca603ed9-c720-4243-9053-e1a3fc54d27a	ba861ecb-15ed-4eb9-a10e-3162b7d25a5c	+9198msg37s1n	$2b$10$JMqlC3G/S1YsCpyI8wgLIueOdb70Ks1HXHo4Uug6zcf/RJK0E4MRC	t	2026-08-05 12:58:03.239989+00	2026-08-05 12:53:03.239989+00
2da749cf-9a53-48c0-8726-65ca117f4d1a	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	+9198msg37z4m	$2b$10$KUx1QYvZkLVB0LUrJu1xhuUlE2864uTIdwlkEh9NgZcwy/Dp72pAi	t	2026-08-05 12:58:06.213435+00	2026-08-05 12:53:06.213435+00
c6379289-bd45-4d69-8247-4bf682bdec3a	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$Ax6hZCIaaiObjsp4IfhlcOMS2GNLzaM6gp/Dc24BcGPwhvWtsA52K	t	2026-08-05 13:06:29.225745+00	2026-08-05 13:01:29.225745+00
5ee8c29b-b5d8-442f-9475-2aecf100f492	571b5cef-8904-4a2b-bbeb-aae3a5dab145	+919977665544	$2b$10$8yUviVU1pdpQAG6wbydUZ.kXG6kcH2g/hesmPofSx3MnkWuRixh.C	t	2026-08-05 13:10:10.172759+00	2026-08-05 13:05:10.172759+00
32ddf0ea-844b-42d0-a4c3-19d5a0f9c9c7	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$XjEOQ6cI5c0Kok/D.MGr4.K2zPYiszAoFn7Y5Xx10dV62YEYRhwNe	t	2026-08-05 13:10:32.077718+00	2026-08-05 13:05:32.077718+00
3a5be1e8-0a7d-4214-93b9-897a68eb9909	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$j9P5jhwCICaYnHKViNsRKOZfIxT9iVYY6TZV2a2q/LoyW8iNeIkLC	t	2026-08-05 13:18:35.661745+00	2026-08-05 13:13:35.661745+00
054731cb-59af-4c10-ad22-b56e76be935b	1993fb25-6147-4b5d-bb36-88f756254fd6	+9196msg8ly3t	$2b$10$MIjRZgXRT1Rqs5cW4YiWf.0IJMKTtOXSOaKpYd5D5/NrYgnoq9k/y	t	2026-08-05 15:28:55.97102+00	2026-08-05 15:23:55.97102+00
eb87a50a-0ccc-47a9-8cfb-54f58f5ef1a1	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	+9195msg8ly3t	$2b$10$Z5st.KHxG3YbN7zBjGASee8ATysy3Dt8phnnO2i5cZ/U5vpQ0Dcvu	t	2026-08-05 15:28:56.404683+00	2026-08-05 15:23:56.404683+00
ffd63893-5b1e-40df-b8c4-ad4e88632c18	c8a549c1-0fe0-4e7f-af9e-56cc61372088	+9196msg8ma4h	$2b$10$ptKnuS/1PjSUjiFMcX2nUuEf99Zi6lTv/bN4SA8LTW6pBCWAAWZ3q	t	2026-08-05 15:29:11.394089+00	2026-08-05 15:24:11.394089+00
4a249f01-53d2-4249-93fc-1064eb93a4db	efcd6ed2-c765-4041-9feb-cd72f820ee45	+9195msg8ma4h	$2b$10$diXysObTVGMQqSLSgym1ceRAPtGSLBZKabrkA0Akkyqei5x6qnr56	t	2026-08-05 15:29:11.781249+00	2026-08-05 15:24:11.781249+00
17e2b38c-2e69-456d-b03d-c393ffc2a0f2	9d68a437-4f37-4213-822f-c5babaf79822	+9198msg8mcnl	$2b$10$kVO7HSRSSF.P5Mx/g4qoD.SBI4LJr5b8yQ9VUv9q1OegjAB8wirGO	f	2026-08-05 15:29:16.410629+00	2026-08-05 15:24:16.410629+00
a237b1bd-0e64-4558-9ed7-6968710c3b00	9d68a437-4f37-4213-822f-c5babaf79822	+9198msg8mcnl	$2b$10$H/mfkZLAbe/F9DifkPZ.SuVsedeFFYPtgeBpqTz4uGTFSBRyFjBma	t	2026-08-05 15:29:16.652632+00	2026-08-05 15:24:16.652632+00
6fc6fbc8-3ecf-4d4c-acbc-11d21820b78c	b0422680-a14b-46b5-aa9d-d9d226b3a071	+9197msg8mez9	$2b$10$0DUarQqkzrMdmLThxIujvOPnjAOtbPQ/Q0wUC5jG4Z7q9dPwCktLG	t	2026-08-05 15:29:17.680638+00	2026-08-05 15:24:17.680638+00
10e8fbb1-1f4b-4300-901a-de6a25086277	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	+9198msg8mg41	$2b$10$m.nR.G07s7vyK/5bd5os0e3Rk/MDgnltPiSQZf2rTJHvW4y6RsK7C	t	2026-08-05 15:29:19.107153+00	2026-08-05 15:24:19.107153+00
fc57fe77-b9fb-4b2f-bf14-9b4a62380a06	d45844b4-81d5-448a-9e5b-549832b07407	+9198msg8mpxd	$2b$10$8nTLoZInVq6t5IKL9Xwzpu/9cf8HayFjhUMn6hm76K1HMCayfeNg2	t	2026-08-05 15:29:32.167675+00	2026-08-05 15:24:32.167675+00
49233737-0705-45db-89c4-fb496583acb5	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	+9196msg8msn8	$2b$10$YTClrpW/0.MSZNMyophrNePeVNwe9T8lf16.BB31vnrsWUA70irkG	t	2026-08-05 15:29:35.334807+00	2026-08-05 15:24:35.334807+00
3b6eb0e0-ace1-4fc8-b80d-9df16a687e27	e576df13-6cd8-44a2-be61-44cb945bc25a	+9195msg8msn8	$2b$10$/XdziAqHVNVCcGiF.BQ0SeIzk24I7m1vWz/3c8RaJB4liOhOBVRtK	t	2026-08-05 15:29:35.748895+00	2026-08-05 15:24:35.748895+00
2a1408b8-72c1-46a6-aa13-752fb96a6254	190b3097-f5a8-4ffa-b684-b8c6e77e4121	+9198msg8v32f	$2b$10$SFLQ.F.u/iLBP9JSfp7KuOp7zRjtLvarV01/BZjQwQvTdp3obQTeC	f	2026-08-05 15:36:10.465718+00	2026-08-05 15:31:10.465718+00
6773610c-beeb-4c16-b4e8-eecf989e3caa	190b3097-f5a8-4ffa-b684-b8c6e77e4121	+9198msg8v32f	$2b$10$KRQx21aCPAkongRIyXkIFOCRA/rZs6kKymjeekXZG5c9hPQ6LjQxK	t	2026-08-05 15:36:10.751543+00	2026-08-05 15:31:10.751543+00
622e0302-4bdd-4648-a958-c836968c5f26	98b38f18-ee4b-459f-b9cd-ddaf62d1f6da	+9197msg8vaiw	$2b$10$8rl5wYS5vUs.KLaGEq2KH.FWIuji9pHzUs7LkwV7IjO1JqJqj/EVy	t	2026-08-05 15:36:12.318781+00	2026-08-05 15:31:12.318781+00
1325a3d2-9b09-42c3-8f4e-0d60b583e479	05ae4bc0-b60c-4abd-b963-794677dcf06c	+9196msg8vt6v	$2b$10$qIUZ1zcQGCI9/CnIvyuq/O0vnh1Ky47tnPfJE1H9Zs0cKVTDq8nFW	t	2026-08-05 15:36:37.336437+00	2026-08-05 15:31:37.336437+00
1bdc33bd-8ccc-4d46-a84f-1fd69bda9ff0	59296eac-cc9d-44d1-913d-a5ef3365343c	+9195msg8vt6v	$2b$10$umneclWt9vhFl/TkW8qnw.aF8mfZFgKbu78doz0QcW.ttfArQJsT2	t	2026-08-05 15:36:38.716916+00	2026-08-05 15:31:38.716916+00
f6b60236-06e5-4bc8-9017-e98ca580f0ab	44edbe9e-2762-4722-bac2-b9731acd35b7	+9196msg8wbd9	$2b$10$HO6eU1mKJfuwcuG44fDIv.Ayezcls3/aeaeWbSC.A5a33S6tWukXy	t	2026-08-05 15:36:59.570751+00	2026-08-05 15:31:59.570751+00
ee901d76-93bb-46b5-8039-934bc109c0f7	fbd4b51b-493b-429d-a938-94354ce49c63	+9195msg8wbd9	$2b$10$uAG1bgTbudux.lmxC1XIiuoSZ7TmYyTd8W/LiGI6iO7K5A6NIQE9u	t	2026-08-05 15:37:00.003126+00	2026-08-05 15:32:00.003126+00
a3e19f68-c575-4231-ae5d-49748e16af31	8412df15-3a96-45f4-b129-f82489d85111	+9198msg8wivz	$2b$10$p4jJjCRyz4qG8IuSnW7.NOi7pUNiC0oPajaIoR1DjiQq4o2kGXvqG	f	2026-08-05 15:37:12.713345+00	2026-08-05 15:32:12.713345+00
9e8ba548-a1d9-4852-a73e-fae349615cf3	8412df15-3a96-45f4-b129-f82489d85111	+9198msg8wivz	$2b$10$1YfLQwFEUU.YsN/rQXN85.j.xocfw6jVcOBFbJbX44k1jQzTW4EVC	t	2026-08-05 15:37:13.144774+00	2026-08-05 15:32:13.144774+00
7948c837-6d8c-48cc-9f32-8a4003da9e68	7ef79457-71f5-4e8c-bb17-fee5ba9da51d	+9197msg8wmnr	$2b$10$Ny6DT2jCuwuWwPEL3g8QWuG6iPpLsYGfb/bLX29F7tTHVya15kmUG	t	2026-08-05 15:37:14.402235+00	2026-08-05 15:32:14.402235+00
9af0ea46-6ade-4e3b-8534-383041cde19c	a8ba3347-742a-4523-aed8-77c774142345	+9196msg8wpcw	$2b$10$9Ky0LKNbWBgv.1ziokoqc.pSQ48XqjAWM4YcxhW5KM6eiTbAOJMky	t	2026-08-05 15:37:17.767317+00	2026-08-05 15:32:17.767317+00
06e6e90d-0fa5-42a6-bf79-3c82eb8ff44c	3d8c7d31-67c4-4023-b401-4ac046cf56ac	+9195msg8wpcw	$2b$10$ORC5sdtMl8sI8df.cJhrbOQaIo/5IplFhxglHQHzSCABEGYI9PfWi	t	2026-08-05 15:37:18.261414+00	2026-08-05 15:32:18.261414+00
892a98c8-0686-42e2-8b82-73721ae2937c	fd039e52-629b-489a-b445-3003be85cb8d	+9198msg8ws3m	$2b$10$vJNQ0ewYTvxZvuEJhKbRi.ELcLbIJsVfJafkMRK6J1zSDjmfVgY6G	t	2026-08-05 15:37:21.575236+00	2026-08-05 15:32:21.575236+00
252ddafb-1d96-4b13-bb0c-92b33f36381e	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$FumRSV.AqUJ/n6hzE7DN5O2F3bBiG9s96v7MdYhVkjf6hwBIPXEIS	t	2026-08-05 15:54:02.392866+00	2026-08-05 15:49:02.392866+00
2db0f5fe-e5cc-44bd-b19e-fa6fcb712b42	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$lPcghHlkf6LhBhCuPm2N1u3j6PfqmbVincWGap.a8CUh2Qnvea/n6	t	2026-08-05 16:33:22.189198+00	2026-08-05 16:28:22.189198+00
dc8c2434-ac98-4ad7-b626-62fb75080281	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$jRduvycPWeenGlYj8oXwuODePnzsOOJfY..ozOh4i/HhMFZSyH4z6	t	2026-08-05 17:25:07.711765+00	2026-08-05 17:20:07.711765+00
0f984cb2-d83a-46df-af28-69643039de71	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$M8M6WqbaJvKijPd4ixrG0e7octVP/7eJEyEKxeYmUMBYwEnmvECTW	t	2026-08-05 17:40:09.977281+00	2026-08-05 17:35:09.977281+00
84566b1d-60fd-4ade-9d1a-4cfbb26518fc	46f8f2e6-f83f-4a03-9c6c-684a91372144	aaquib4u@gmail.com	$2b$10$DpV5Ri5/ZQ17kADxQeLlROc63fPVBE5ov32AxfV31fUIfvqf1C7pG	t	2026-08-06 02:20:31.846753+00	2026-08-06 02:15:31.846753+00
59f31c67-351e-47e8-85d6-1c27bb7f96eb	886d75e0-e090-4177-a6d8-570db8b1208c	8004362634	$2b$10$2jjQ/OVm.2xBZDcgbjLCAuSYbXanaAGdElyXTwCYq0E7wVs/4R5Pq	t	2026-08-06 02:18:24.350238+00	2026-08-06 02:13:24.350238+00
45a8f488-8d4a-4e63-b1a7-e43267fb5c46	6a62dd3b-10b2-44fa-aed4-320d1685025f	8004362634	$2b$10$iaj8uE5jbqd0VdMYfB7XOOVHDtrNQ3PCCak6Mm.trhVy5E8O/BkBi	t	2026-08-06 02:23:52.5388+00	2026-08-06 02:18:52.5388+00
2575b758-701e-496d-bd51-31e6091cb089	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$Cy5NCpXIQx1/QXJN5J2UouCxc8q.K6iUC6B7qr6cWyxQp4URHT6UC	t	2026-08-06 02:24:21.456429+00	2026-08-06 02:19:21.456429+00
f5029304-2a7c-4ae9-a934-7140f3e11be8	e2fd25fb-510b-4af5-a453-84ab5a69cf21	+9194msgwe8a0	$2b$10$lGotrSuBW1l0HxuiBdKcqu6FEyV1vDuEjiWjEfHjqsgmmO9P0TPi.	t	2026-08-06 02:34:46.740317+00	2026-08-06 02:29:46.740317+00
408ef1c9-04de-4387-939e-a4b861731562	f1d17cc9-15ee-4758-846e-e01e49b8779a	+9193msgwe8a0	$2b$10$NMyt6UP1Hwut9OqBGrS29.UEciRn.omWH6oAArw/wDjrJ5dW1Q1ai	t	2026-08-06 02:34:47.166647+00	2026-08-06 02:29:47.166647+00
a1867311-7e10-4bc0-8b57-7f61d928f07a	8b6fae7c-974a-4d6e-9221-f37cf6a97469	+9194msgwef9o	$2b$10$5QcvkQkaB.lCa7sNZL85hOAeywFt7pzWDBlXt5YIBxsDFRlIamiSm	t	2026-08-06 02:34:55.721735+00	2026-08-06 02:29:55.721735+00
5b936712-afe0-4419-a447-5686a75f623f	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	+9193msgwef9o	$2b$10$IleCI0VTJR6fXnfwDQvcTOj5tySyBSCjp42uAf9nURdmGZRuCp9E.	t	2026-08-06 02:34:56.139786+00	2026-08-06 02:29:56.139786+00
2189bb3f-157d-4b0e-b0f6-38f646d323c0	3f591c6a-5509-45f9-a2e5-050be735735a	+9194msgwevf2	$2b$10$SqskbUoH7SxfzRaz4Jm81OSphOqXfURc9Ff80tJPXoUAZmaWPlPoW	t	2026-08-06 02:35:16.661729+00	2026-08-06 02:30:16.661729+00
4e0f3dc0-b4d0-42ea-92d1-86c262222f7f	f5a61371-a191-4bfe-9659-1a05b788696b	+9193msgwevf2	$2b$10$bm8tsfXV.qbThh2p8fd4oeJRK.e.DAQDQXW3xSJw2rK8slVl0Uf8G	t	2026-08-06 02:35:17.112196+00	2026-08-06 02:30:17.112196+00
ef4d9ebf-ff37-4d82-aed9-05f89ece751e	6a38eeb9-c8f8-4c02-874a-f365364bd4ff	+9198msgwf2vt	$2b$10$TY7oJoNWb.3NmXQms.VFZ.wr6t54OMAfepW.S17Ygy46Oi5qfpG.m	f	2026-08-06 02:35:28.572275+00	2026-08-06 02:30:28.572275+00
c8813292-5390-4447-ba00-e9bbe3e2528b	6a38eeb9-c8f8-4c02-874a-f365364bd4ff	+9198msgwf2vt	$2b$10$0vm7czWWJC2YV.ZspP6vJuKtr5kyIFrXN3n0LEm.jqI8w2MC3hh8O	t	2026-08-06 02:35:28.824605+00	2026-08-06 02:30:28.824605+00
0166abe5-2b70-47e8-b624-6bd8beb7d6e7	6c982b06-1aca-4977-b319-191e16fc4de6	+9194msgwf5lh	$2b$10$e3Jg8ilM14L.hqNFq0tz9uNWbBb3dgPwV.Yjn0LOCdbS9YeSRUvim	t	2026-08-06 02:35:29.792385+00	2026-08-06 02:30:29.792385+00
b746d78e-9703-42ff-8a7d-bee80b175d58	15628c01-d0a0-422c-95b2-dcc978ad6fa1	+9193msgwf5lh	$2b$10$jICr/t/AhQjWEcE.2I69YOW3/qrB9NQ5wVF.bSZIkEygYpCXrNZAe	t	2026-08-06 02:35:30.222711+00	2026-08-06 02:30:30.222711+00
95659f46-d1ce-4b80-82c0-70ea04c527f8	2d150870-1d4e-42e0-863c-0bad5782141e	+9196msgwf87c	$2b$10$kn1JidOrTQ.SGQNDgBnXH.dqedr9O2pu0Yp7uWvRmYFznokUNSFNC	t	2026-08-06 02:35:33.248747+00	2026-08-06 02:30:33.248747+00
c7ff3263-7fef-4a7f-93ed-5cdb1963411e	d4e10fc0-e272-4867-81cd-567a0e84cfdf	+9195msgwf87c	$2b$10$XmjADUGVWUVx3ap6BCkAfelXSWTBK/e0H.Bzz3y9VXTeggQKFr7Hi	t	2026-08-06 02:35:33.668919+00	2026-08-06 02:30:33.668919+00
c497f049-1612-4fb2-a043-a7f3f7691f95	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	+9198msgwfayi	$2b$10$MGi9h93phft9hk/gqs.6gesG5BDxdtD1lNhosqwMtT8bwdbB/NCJq	t	2026-08-06 02:35:36.830665+00	2026-08-06 02:30:36.830665+00
ced027d4-b572-41e4-9bb2-fc1a01927688	5aa1f3bc-0de4-4093-ac1e-3859b13929d2	+9197msgwfct3	$2b$10$cfU8auYTqaffaCi/SHG9NOKaz2JwRQx4iPCxcKxz8tNtsGLECD6pq	t	2026-08-06 02:35:39.257448+00	2026-08-06 02:30:39.257448+00
0d571dd1-24ad-48e8-809a-72ac386379e9	36615d5a-0131-4c21-98e3-956ceca31d48	+919988776655	$2b$10$DQ8WoLy4UE6y2GWNGrqUaO1uPYONDM2sBZD10hHl9dw7OaNvKUJrW	t	2026-08-06 02:36:46.578758+00	2026-08-06 02:31:46.578758+00
ceb0557a-9973-4146-9f6c-a2342c5cf533	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$R4gLFOglxFXze3HAqKIlZeFGsViypgZXi4z.LiC10ilZOtVnk5TfS	t	2026-08-06 06:08:35.918769+00	2026-08-06 06:03:35.918769+00
eccd0922-c7d2-425c-93f4-008e8a6c713a	97ad09c8-7854-4467-b96b-ceb2b390c0ce	notanemail	$2b$10$v6peHxE6Ipy7cuNIW5LLJe4awNZDXwHF3pH1ouoOZ98aE6SK1ZfGu	t	2026-08-06 06:32:27.30588+00	2026-08-06 06:27:27.30588+00
e90920eb-ba38-441e-9bca-7da8b6ce02dc	1e57d93c-53e2-4f0b-92e0-944de0c43daa	9876543210	$2b$10$BWftnFEWhluZdFvcA1CtOuf3577XkTKrQKgrrojqDQqXQT7s56gU2	t	2026-08-06 06:35:13.270072+00	2026-08-06 06:30:13.270072+00
d7761fb6-38b0-4ed6-a553-c2637ede1c2c	f6d46263-407d-429f-aabc-f9e3c7b6aed3	+9192msh51gg1	$2b$10$q/5srG4Ii0X3bN7QxIFYiu2zY1mnCztMHaoh1nfiMQQ.IAGMxw/VW	t	2026-08-06 06:36:47.243929+00	2026-08-06 06:31:47.243929+00
24cf2974-589f-45e5-966a-eb7a31c4f255	4758c076-09d2-42d8-88cc-cce435637c32	+9191msh51gg1	$2b$10$4yCyTK6Kz1Dr/F5IDL7kVue7QavRKIO3/C2/XR.TTFDH0VP7fYJbO	t	2026-08-06 06:36:47.67399+00	2026-08-06 06:31:47.67399+00
ece99135-4564-4324-8ab5-54a84c7629e5	59361f8d-559c-4874-9324-4d19418db3ea	+9190msh51gg1	$2b$10$uFAJYzryO6WZ/PsAnxoev.pSXUdRGagAQpteHFjstkezrDOKIylsu	t	2026-08-06 06:36:48.328492+00	2026-08-06 06:31:48.328492+00
63df579f-b430-4b99-835b-2efed93a84db	5ad80524-52fe-43f5-b245-2a7ae49a92cf	+9192msh51oko	$2b$10$JuckdmTR39jClkQ7Kcw8RuWO.ZTGO5Ro4./Kz6v68O4csnag0//Im	t	2026-08-06 06:36:57.821515+00	2026-08-06 06:31:57.821515+00
0dd1c3e9-1e63-47ca-bc43-920f6ee4c2b9	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	+9191msh51oko	$2b$10$xhEJA9arrFm/QZ00UoAT9.KcZGV6wtpMqU.T0nqwN5QuSqkeYMcwC	t	2026-08-06 06:36:58.241283+00	2026-08-06 06:31:58.241283+00
75080848-bbb2-4ba5-8c51-f933fdb596cd	3a87cada-81bd-4de7-89dd-d9d1150bfada	+9190msh51oko	$2b$10$5kT.IQ7MPIPFi9MAQLa68.7nXTJQTyUXGG1S/X5T8I8aXD0LSfDJy	t	2026-08-06 06:36:58.851178+00	2026-08-06 06:31:58.851178+00
59569955-ac46-45ca-86bd-e497a3210d86	6914b9da-19a1-48d7-bccb-a39a08216f7c	+9192msh51vm4	$2b$10$O7Wpq1oRTa5NX4O0SmXnLuEcGsEmVwmwXoOg57vYyfEpbGOFJACGq	t	2026-08-06 06:37:06.918365+00	2026-08-06 06:32:06.918365+00
dd75a3d8-1c63-4a82-bd32-773453af3de2	12387821-8e7e-402f-9291-8f1fbadbce1e	+9191msh51vm4	$2b$10$ahnke.B1SueP3w3WIMUTLOmLv98DnyVd7Qg4aBaCWuntLztB0GoKO	t	2026-08-06 06:37:07.353483+00	2026-08-06 06:32:07.353483+00
94ed1caa-3822-4c8f-9046-b02835a90620	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	+9192msh5267a	$2b$10$oMQXjj1ArjUYP.2/dlMk1ukXx6BmyDe7DN/ItHKrcVTxDVJo7gBPe	t	2026-08-06 06:37:20.737491+00	2026-08-06 06:32:20.737491+00
7f17719c-9882-4368-97ee-ba663b04b76a	d31b3330-980a-4d38-bf4d-c221a5033bda	+9191msh5267a	$2b$10$Jw4BJ7QloPy1isue1avzhOIMY5b9Fq4pmkIt92QABTLEq1YmouggG	t	2026-08-06 06:37:21.27421+00	2026-08-06 06:32:21.27421+00
5d93ec22-d8f7-41c5-802e-1a676260979b	3d9b43f7-0071-4d41-90e4-b911c4447dae	+9190msh5267a	$2b$10$dhuKKD8DY15NUpgTUMMqtOjBK3ONL0oa5Wm.3a788Xfp9dSF0gAZK	t	2026-08-06 06:37:21.936417+00	2026-08-06 06:32:21.936417+00
94c67dab-49b1-4c41-bf2a-440f3ca6b65c	2a224da9-7f89-435d-bb73-bf545c2d6bdf	+9198msh52900	$2b$10$MXdR5S0KIccOc.tW2S1HCubVYzronh2zlvrZ/BXNCujZpJTRQk91q	f	2026-08-06 06:37:27.169668+00	2026-08-06 06:32:27.169668+00
dcac747a-3e38-4bcd-80ef-5877023ebac5	2a224da9-7f89-435d-bb73-bf545c2d6bdf	+9198msh52900	$2b$10$KgvLxOgK2QFBjOJIybBUmuZOyJIb2IzJHerh/naQn1uQulwVKdllW	t	2026-08-06 06:37:27.535749+00	2026-08-06 06:32:27.535749+00
48e0d4ad-2f28-43d1-9f88-4551410eea3e	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	+9196msh52cex	$2b$10$kpxeKqr/ZpjxBAWG4W7pT.I.O6YmSTCAPBsi30zTopPdZ/yAb7azm	t	2026-08-06 06:37:28.660588+00	2026-08-06 06:32:28.660588+00
4ff93cb3-dc0e-4110-acaf-f9655e12c13c	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	+9195msh52cex	$2b$10$9nIx/VUtM5VDMhNdpCju2.wOM2bnSye.dVWgyHydc6rYxzY4jRZEq	t	2026-08-06 06:37:29.046743+00	2026-08-06 06:32:29.046743+00
01e1fa8d-a82f-4412-b9f1-e4b0ae3f046e	679a9cbd-c4bc-4326-a754-e6d09a55b010	+9194msh52f08	$2b$10$EjmCksngu6OEhWPVhGCNMua1QyM/kyNEA8vmAl40o0DQSvBaqlUjO	t	2026-08-06 06:37:32.033741+00	2026-08-06 06:32:32.033741+00
fdff7328-c06b-45a7-9935-69729aa7b0a0	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	+9193msh52f08	$2b$10$.gs/Nv7OXjmvbeQiPRVuMemnHjN8Ww.RMC2feeK3w2pNrTvCypL5q	t	2026-08-06 06:37:32.430827+00	2026-08-06 06:32:32.430827+00
b2b7eda5-4007-4a56-bca9-b927ab1919ec	3033d43d-8034-498f-b48d-5c549e8f97fb	+9198msh52hht	$2b$10$bzu/IWDWReG3vQ61bxsQJu78PHjqGiRVdRJ0fHYYUmrSozFx/TCCe	t	2026-08-06 06:37:35.214808+00	2026-08-06 06:32:35.214808+00
18ba2422-390a-4fe3-90a5-8cb0dfb889a8	3c27e34d-8df3-456a-8b12-079170f1f55b	+9197msh52jd3	$2b$10$8pheqLqq5S/dMUQ4VrytS.vFEunOKXHWo5xP4zU.r0XU05i95VFxS	t	2026-08-06 06:37:37.640969+00	2026-08-06 06:32:37.640969+00
a3540e46-2bd7-4489-a528-62795d46d930	d1ef1fb4-c2d5-468d-8a4f-d1123278f72b	+9198msh538x0	$2b$10$RDDleTTkpzXoz4yMqOUWte4wGhxze/E2aMPQKuwAMzup3CuG77IbW	f	2026-08-06 06:38:12.863469+00	2026-08-06 06:33:12.863469+00
d367f7f7-0732-47e3-9eca-dd1b60b9a4e5	d1ef1fb4-c2d5-468d-8a4f-d1123278f72b	+9198msh538x0	$2b$10$BRCP0pxI/ZyrqVN8OoUhMeGPAYX2UPJKmupFWwIiyfEIhvEUTp1lO	t	2026-08-06 06:38:13.304464+00	2026-08-06 06:33:13.304464+00
587061dd-95d5-4762-b62b-f35f810b1694	e81e56cc-db91-4ddb-b1e8-530510958e6c	+9192msh53bth	$2b$10$jKtZcT12c11aELGU5ByvaOA01lda0dpXVQlxmvyEMtYM9OSxrhz4G	t	2026-08-06 06:38:14.705848+00	2026-08-06 06:33:14.705848+00
7d8c34f1-7253-43c0-a675-27fda944f93b	25634a36-337f-4d14-a96d-1a843df8614e	+9191msh53bth	$2b$10$9XL/eE9kF7bITXdQ3gNpieohI8Ao1kilCoSb1udpOmm5QT15uQecC	t	2026-08-06 06:38:15.298166+00	2026-08-06 06:33:15.298166+00
654c02a8-d7e1-4407-8283-2ee61903a9fe	6003b134-d829-420c-acd5-b3f86ffbbc22	+9190msh53bth	$2b$10$vC3pmcO31L15IiQKlzx56e1QV2RtckJUvNPFyNI101eGqoZfNpSxS	t	2026-08-06 06:38:16.595569+00	2026-08-06 06:33:16.595569+00
e466ca09-43e6-4535-aacc-6e6fe15ff452	1c16cafc-57a6-4651-b25f-a364716b322e	+9196msh53eua	$2b$10$EzD1eSzi7/1WSjsPvSDH0uqevnAjSbEmM8z0PCr3s4jFv6urzVNfW	t	2026-08-06 06:38:18.409821+00	2026-08-06 06:33:18.409821+00
2286a6b0-d255-41c1-992d-9190be2f0336	eebc8df0-9557-4dbe-9644-ebe4a13b931c	+9195msh53eua	$2b$10$/Yl4izG1S9hNhcGzyQ/pZOA1dE1pQJfW9xKA1QTKruRyElYEh1YWa	t	2026-08-06 06:38:18.811725+00	2026-08-06 06:33:18.811725+00
42292885-8c4c-4a8d-9dce-1e0ac37e2ce1	649308eb-cc8e-4702-b6be-f823419073cc	notarealemail	$2b$10$Hk/6fRxfo6ybXaY.hTFyhOW/R0fSYgp.WmXyvzDrnlfkTHWpX/d.6	f	2026-08-06 06:38:21.248232+00	2026-08-06 06:33:21.248232+00
cea59039-cdd9-4f1e-b052-3df2a12d36c8	6df70e40-bb74-457a-a687-5e470514447b	+9194msh53htb	$2b$10$tqvwOpxoQmjVKrt/2K/Tke6cfbviOCZ6aNAwSz7XeVLxbu5SPtd1G	t	2026-08-06 06:38:22.466452+00	2026-08-06 06:33:22.466452+00
eab042c6-ac38-4d03-bb6f-6b658eccbbec	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	+9193msh53htb	$2b$10$UVqgLWOYHGxe6adwNk.iyeDjgBeapBNzp.BJpb3P.taSySZGsXzCW	t	2026-08-06 06:38:23.020089+00	2026-08-06 06:33:23.020089+00
a1f9e03c-6bcf-4562-aee7-76a2b6b67b9a	5fd98325-1ea1-44ab-904c-b7d9c64df81a	+9198msh53l9e	$2b$10$TOKUwLjlB7RyqS2fzZtH9OR3bI.NM/DinzFtaqsQyAFZ3JwuBfk4.	t	2026-08-06 06:38:26.80039+00	2026-08-06 06:33:26.80039+00
fd1f5a0e-2ba4-4675-819e-037fdfee7e9a	f87a94fc-f840-4b86-a2c5-1c32001d8a05	+9197msh53ngj	$2b$10$SzHiRKTnrNqY2CPF.WNa3OhzH2ASD7fwP9JNTntu96kdubyiwfNH.	t	2026-08-06 06:38:29.59626+00	2026-08-06 06:33:29.59626+00
08d3737a-7553-4233-852a-e95195f45b49	649308eb-cc8e-4702-b6be-f823419073cc	notarealemail	$2b$10$TVVT3SZAFO8ozJAqyn6JfuF24uOSjZWZGBPFTpoI8x7VGZqdS8Jam	f	2026-08-06 06:38:33.882076+00	2026-08-06 06:33:33.882076+00
070dcfb1-7a60-456b-94b3-9ced71c6791d	a9cd0b33-31db-4738-bc7c-a1b7158adf4a	+9198msh53zdg	$2b$10$WRKDu.NoHqf9SasSAoPzZu6KWiQ0Yn0LKGk/VFKbob7K6UU2lauiy	f	2026-08-06 06:38:47.243145+00	2026-08-06 06:33:47.243145+00
47764de0-dacd-454b-b609-272f317a2e96	a9cd0b33-31db-4738-bc7c-a1b7158adf4a	+9198msh53zdg	$2b$10$LMGZFmBnO0DXfW9KD.rr5.aAmMy5xAs9ckoK2HXhbi8zL45Oh6Pi6	t	2026-08-06 06:38:47.519103+00	2026-08-06 06:33:47.519103+00
88af2862-fbdc-475a-a863-db9a7194a59a	287fea1f-a616-4b7f-82f8-fc0886dceda0	+9194msh5421i	$2b$10$fJwnf2AR0.3PuN4YkRiNRedCLfyrTFk33RuBTC4sIBkcT7Uz3sFdG	t	2026-08-06 06:38:48.492035+00	2026-08-06 06:33:48.492035+00
e13a66bc-7148-4f9b-b7ba-899c31ce2bdc	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	+9193msh5421i	$2b$10$OleNWVAtBxSwAPeBByzouO0OlsyFRVMcOyuTrGgyHfc7wd3KoWI92	t	2026-08-06 06:38:48.906628+00	2026-08-06 06:33:48.906628+00
0b3e3d90-698d-4519-8e38-87f2c4345ae7	730aab59-18e5-4343-8ea5-20d21d417f9a	+9192msh544q1	$2b$10$7IMokXzlF2KOpKTXmhgJpuzYi.gqwDPSC2wJxGc9VIB19YD1v16gW	t	2026-08-06 06:38:52.03549+00	2026-08-06 06:33:52.03549+00
99b6cac7-73e1-4069-9a4b-673f93169a21	b23ee7a2-7e56-495e-96b8-f1253aeaea36	+9191msh544q1	$2b$10$8tm8GNTtL5ZI4hVt2WLlc.jyuqq3gt.DJrYiruHinuXVB9zxfBCda	t	2026-08-06 06:38:52.567195+00	2026-08-06 06:33:52.567195+00
bfc03b15-aaa2-4ef8-a3aa-1cbb550ecb01	421ca638-b359-4990-8854-982f64dc2726	+9190msh544q1	$2b$10$nQ1.bOIJrCHotY3NdADj5uzRbpIeAMCWyDgr.mc7NJj9Bw0PY6gTO	t	2026-08-06 06:38:53.621279+00	2026-08-06 06:33:53.621279+00
934200d1-9954-43fd-83a1-bb593f2d8824	7294e7cd-2388-4a10-9e3a-31f532b748ee	+9196msh547eb	$2b$10$..y46nb6b7auUrBZHhz0cOTZpYGLoS9JSMh.HlQA43yeoVUBF.bha	t	2026-08-06 06:38:55.471856+00	2026-08-06 06:33:55.471856+00
8e441551-3961-4935-99ce-07ac6427b886	d7c3fa7c-c268-4e5c-acec-0450571fdb18	+9195msh547eb	$2b$10$yZk0k811aQDJw5cSGN8C7OWyHqcG7zBX.NR1wZ7F9TttwD6qnaZfu	t	2026-08-06 06:38:55.898795+00	2026-08-06 06:33:55.898795+00
b89d15d2-858e-48b8-96b2-e5f6a0aa1d76	efe874e3-dc4c-4942-a44b-98f2a856525a	+9198msh54abt	$2b$10$H1ezJgq7I0G8KDaTI5vR4ejlSduoLIEFYAcFkHOns5EYPVC2Ezz7G	t	2026-08-06 06:38:59.256535+00	2026-08-06 06:33:59.256535+00
96dc220d-3077-4876-bc51-03716f4ea448	ccef9aeb-4e3c-4923-bb15-f364e42fa1ac	+9197msh54c54	$2b$10$QwNbOIged.Ssl3C/qJsyB.PMTwby.eNK4iz19Odd74vXyW5PTeZu.	t	2026-08-06 06:39:01.678777+00	2026-08-06 06:34:01.678777+00
16b412bf-bb5f-4146-966f-6957ef9b6dfd	649308eb-cc8e-4702-b6be-f823419073cc	notarealemail	$2b$10$6DTofL98TlgzEwn1yeceSubg5/ka/huq8kTqyH3F5CFcNkllQOWkm	t	2026-08-06 06:38:47.388389+00	2026-08-06 06:33:47.388389+00
d795e7c6-56d2-40bc-9a90-186913505423	bba02b1e-aae7-4873-9983-7a8196db808b	+918988776655	$2b$10$AwuGcm/yGrUDue/FtleDR.FHLGOi6m519OvQyXk5hJPLZghm0.Sj.	t	2026-08-06 06:40:34.413411+00	2026-08-06 06:35:34.413411+00
a5ff7733-994c-40f1-a6f3-88cba7662736	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	+918788776655	$2b$10$DxdxS4qAj7RwC16BAlgr5.n3TzFLepGuEvLAd0bT3i65WmlbSEEja	t	2026-08-06 06:40:34.824631+00	2026-08-06 06:35:34.824631+00
eedd4328-7f3e-4eda-bdc4-47b32f8fa5d9	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$fM/zH4.gm/5EKiynfACez.slYOhsZ1.Et0OoqD3vMAYqSTb7s.wAu	t	2026-08-06 06:53:01.919986+00	2026-08-06 06:48:01.919986+00
701594df-09da-468b-b594-89ef81bec12a	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$xfG.u/B73Uy9K6CA.ajKsek7Rx9jglrdKsk8tjBN2X2aqM7dTe1Y2	t	2026-08-06 07:02:44.790424+00	2026-08-06 06:57:44.790424+00
456c8bbe-1fc4-41a5-afe5-72c9ac388d52	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$GBJ7txp1H8rlJmlPgUrdCeQNoDzuyFPRv2CMfl9S1UZeNS5Ye72m6	t	2026-08-06 07:06:13.903645+00	2026-08-06 07:01:13.903645+00
e189283d-49cd-4a83-b99c-abd97da7bf59	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$blbwKSl/rCSqnxoAl.k4TeRC4Z4PFalEfBZ.ikpNDGoD6DWdjNsH.	t	2026-08-06 07:21:38.937306+00	2026-08-06 07:16:38.937306+00
0eb56fa4-d2a4-4e8f-8972-67d86d5c7596	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$qBt1CD7gOffw.kDcbVoIoealX16DyJmbsi2niVqOSksNj9Z1LlSsq	t	2026-08-06 07:21:39.54544+00	2026-08-06 07:16:39.54544+00
bfe5b674-545d-4205-80f2-a55eb14a8290	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$DGCsn7J1H5T1pK4lGKZ/HeVmMsySClF3abgmvIlX0lNXwmsi8oR0u	t	2026-08-06 07:23:08.550812+00	2026-08-06 07:18:08.550812+00
98faf3ad-cf60-47fa-88cd-e83af47250f8	58e3af63-5f33-49a0-9089-42509c07464a	+9198msh6wzva	$2b$10$q1haQ1cBx7CPngQgRcssd.lO7J66QcPAgHkZRwTVgm4A5H.RSq0E.	f	2026-08-06 07:29:21.473118+00	2026-08-06 07:24:21.473118+00
f933648b-f87c-4864-8563-5e64980da9a0	58e3af63-5f33-49a0-9089-42509c07464a	+9198msh6wzva	$2b$10$9Tw6L5DSPG9692WTekFKBupUH4Y1AR4zfA/1XLFdmetpan005cK8e	t	2026-08-06 07:29:21.829247+00	2026-08-06 07:24:21.829247+00
777e6c52-5b77-41fb-beba-bc2f89f07913	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	+9196msh6x3d9	$2b$10$VkEPMph9PRNJCljKjnCY2OKkSnzQvKmB2u/YfpBc7aF0D3DggWOQe	t	2026-08-06 07:29:22.950233+00	2026-08-06 07:24:22.950233+00
ee51ff24-5811-4408-9215-fbcd966cc820	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	+9195msh6x3d9	$2b$10$gdXgMOxvZ.raYQKRMPzMxOoKXnwDLgIADJfd.Qvr7mGcaMncc4Grq	t	2026-08-06 07:29:23.373539+00	2026-08-06 07:24:23.373539+00
cd350b81-b564-4325-b6a3-1dcaa28fbbdb	7607d532-01cb-4685-93d0-019c266c06ca	+9194msh6x6ml	$2b$10$uZJ/ah9MBmHC3nSaySAfs.ahRTYv3BaWgxRYSYKnbZpFYzj5wbZYq	t	2026-08-06 07:29:27.103347+00	2026-08-06 07:24:27.103347+00
c44736fc-43ed-4a27-b4ee-35e4600fc7fc	150f70a6-62b8-44b8-95bb-3e78bbd916be	+9193msh6x6ml	$2b$10$ppuHG4qhCypUBfFEUqAQe.2o8br3bOhYtn1f95Az2Jl7XUouxBD4q	t	2026-08-06 07:29:27.580547+00	2026-08-06 07:24:27.580547+00
2053fc9d-a019-46ce-ae23-ff886f4024b7	b3e94172-8013-4cdc-b429-33dd88309863	+9192msh6x9hq	$2b$10$P8nrQXpa70FBm23ioMWhSeK9g.V2jWViS8mS/LnxTnNj/H4zUL2Sm	t	2026-08-06 07:29:30.982522+00	2026-08-06 07:24:30.982522+00
24e0d940-c4e2-4d34-8acf-6752536ab709	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	+9191msh6x9hq	$2b$10$lKQ5TaU3EeAoIhzpK4xngOiXjf9WOMyPh4S.j8XhLOPevGnHm31ru	t	2026-08-06 07:29:31.425022+00	2026-08-06 07:24:31.425022+00
553462e4-8853-470c-9369-9e1191e8840b	f0288664-74a6-4047-9db1-a266f0bd5811	+9190msh6x9hq	$2b$10$.f1jDVivmfLISaSJR/6iSORVTnsajywYmxB2meZmfMz12BRIN30cm	t	2026-08-06 07:29:32.459037+00	2026-08-06 07:24:32.459037+00
f5b3dd7d-d5b6-40ac-9109-91abe94833b2	639ff8c2-a929-4dbd-9f14-e19826bf1da3	+9197msh6xc3p	$2b$10$xMXGPrIzYz8XqtGpxmo84.Bl.ZRhKPp53jbZqOEVLCsAxyJQowQuy	t	2026-08-06 07:29:34.214196+00	2026-08-06 07:24:34.214196+00
657c3395-886f-4231-bb19-aba21e14b466	744043a1-ee52-4e5d-a5d7-91221762e13a	+9198msh6xdai	$2b$10$yBWiAXOgICGcff4.eOgf0eomyXSQcDu1Q/F3zBypqHcvZFn5gS2xK	t	2026-08-06 07:29:35.805399+00	2026-08-06 07:24:35.805399+00
56861583-2a63-4ab4-93b7-12dda529b091	86061e0a-d9e9-4fd4-91cc-f4113ffece92	+9194msh6xo0q	$2b$10$nqfCUaAts4B7M4cVTV1dFuOps6TNKO3IoIHsV07BNwLdlcXknjb8u	t	2026-08-06 07:29:49.814075+00	2026-08-06 07:24:49.814075+00
125a152b-9466-4a09-b023-42e50a30e22b	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	+9193msh6xo0q	$2b$10$U2DvH16WWFCxA35c0pDZuO4QahpLQItsNeHrLqI4Wx3xa6Z3zp9OW	t	2026-08-06 07:29:50.277598+00	2026-08-06 07:24:50.277598+00
b24ef449-0bf6-44aa-b15c-22a24140986d	af87f426-9540-4a3f-9796-61a215efc6c1	+9198msh6xraz	$2b$10$9pNmM..pZyGo3Kp9.8t/cOYkKF4YxrRXQfYOBcPQVlIfe7Lf0QGPW	f	2026-08-06 07:29:55.824911+00	2026-08-06 07:24:55.824911+00
9af4cbc3-662d-4eab-afdc-bbc8a61a07e7	af87f426-9540-4a3f-9796-61a215efc6c1	+9198msh6xraz	$2b$10$F4HrLtTAUBZPjaVGcv05RuwZPKryS6mOV2JtI0CP6F2qV9lX5whSG	t	2026-08-06 07:29:56.093529+00	2026-08-06 07:24:56.093529+00
649d5521-405a-4375-aef0-39ed377a2dff	ddcd3ad5-423b-436e-b921-4322d3397be4	+9196msh6xts0	$2b$10$18zyYs8hWuFR0.xHPh.u.OafOAqK8Frv.DWSrsimMt4v8.PtIfeJ2	t	2026-08-06 07:29:57.138862+00	2026-08-06 07:24:57.138862+00
48bdeaed-fcdd-4eb1-9fa5-5124672dbccd	cf8b1225-10c8-42b4-81a9-6dc603b4b753	+9195msh6xts0	$2b$10$.dFYVWiFZyqYXAW/MOuJa.VuAIz3Ai/gg1o.jHU/jW9b5AI8/rUnC	t	2026-08-06 07:29:57.603681+00	2026-08-06 07:24:57.603681+00
2ceb302b-f53c-4ac1-8dc8-f8179bc045b4	f20698bd-7049-4b40-8d92-c62216637198	+9192msh6xwrz	$2b$10$lxDePN7wb6JH14Pkty02dubxtsdiFUGCNmUVuAcNvFUgv2wrF279.	t	2026-08-06 07:30:01.019754+00	2026-08-06 07:25:01.019754+00
b8c12c08-86d2-4d7f-aa27-dadc98539353	b53dcfda-741c-4278-a232-6c0f18ad2805	+9191msh6xwrz	$2b$10$49fEHJkD8BSiFUdU9ObgAu953vYBwMzsHAl00qzH2GMjOwmqx24P2	t	2026-08-06 07:30:01.478123+00	2026-08-06 07:25:01.478123+00
2b9f6bdb-5f26-4bab-813d-55922dfdf86d	5461fdf8-9481-4066-8c0b-5470b4184463	+9190msh6xwrz	$2b$10$AVVnLx0arfbP86B6DqplBe6/wC8Z3QVGYpuneefa4oPzNwjHx1x.i	t	2026-08-06 07:30:02.373204+00	2026-08-06 07:25:02.373204+00
a14a2848-3133-4e62-9227-6ce8ec3ef502	d1ced440-d263-4434-a49f-2817345f0c27	+9198msh6y0cc	$2b$10$BJr/IHRY3jBzKYNdFfZAzeTTHMYDIf7f77JGKxLw3NohNTkfUDFDy	t	2026-08-06 07:30:05.700317+00	2026-08-06 07:25:05.700317+00
7715bed6-835b-4096-a312-d847f3a601e4	56e227be-5f34-465e-b71c-9fb4ecd94d98	+9197msh6y275	$2b$10$gPHm8qQVLeYYRsgrmekC2ePTasLjg1WyTKuWpRx2Wga9H2xbLhcTO	t	2026-08-06 07:30:08.220762+00	2026-08-06 07:25:08.220762+00
e28d2769-d13c-44cd-b0bf-3cd1ae635860	5380e05f-af41-420b-a86b-6661ba12fa65	+9194msh6yagx	$2b$10$m1B.Q77W5tW.EljxV7vmAuxsSYAuZkhjsoo2wUOlmdeyFNj2dby9m	t	2026-08-06 07:30:19.130115+00	2026-08-06 07:25:19.130115+00
76c0db43-37ed-48fe-9287-ff4358239612	c7329ca3-ba0b-44cb-a3b5-35291cad9718	+9193msh6yagx	$2b$10$xSngXtvQo8EyeAGeGSItBu6laN2QDv4shCVY8v7PO7QZo284m7Uea	t	2026-08-06 07:30:19.775034+00	2026-08-06 07:25:19.775034+00
0fd94841-26b2-44f8-a2be-8cb1b632d7f6	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	+9194msh6yrcd	$2b$10$85Z285ePM1yBOWajN6xOwuGda83yZYUX.RSYpL5e.tAXpRfXtYyHW	t	2026-08-06 07:30:40.640288+00	2026-08-06 07:25:40.640288+00
e15e6ffa-a2c3-4907-b129-883449967f6c	80208c67-25c3-4c79-8fd5-90b2d0440bba	+9193msh6yrcd	$2b$10$PO43AlIGbbDsHmGu4h4VB.hUXGWHEmK7CHePX0BglUEmtZYwT5KkC	t	2026-08-06 07:30:41.115145+00	2026-08-06 07:25:41.115145+00
079c5d36-38f9-467c-b085-0bc87f69c2aa	30a21658-542f-4803-a13c-651be1e25909	+9192msh6yu91	$2b$10$MVnP0XhSiWxqrGozhhfb7eK7mGueKFkdgLTeE2sRwRO6YBYOndnk2	t	2026-08-06 07:30:44.441867+00	2026-08-06 07:25:44.441867+00
cf168295-fe9f-4a47-aef1-bcfaf13a214a	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	+9191msh6yu91	$2b$10$KIZUIS4Cqsc9told5F4vfuCbBTLmfgq4nAVkS5s5dgBFcrgKn4d9O	t	2026-08-06 07:30:44.884615+00	2026-08-06 07:25:44.884615+00
c3764d90-35a3-49fd-874f-8039a158b168	03877811-6a4b-474a-9eb7-14e02ce491fc	+9190msh6yu91	$2b$10$d9lY.qaAh6xS0585OfcgR.l6sPm66uSsjUGlJml6hPPGqPARipLAO	t	2026-08-06 07:30:45.682219+00	2026-08-06 07:25:45.682219+00
7e69a29e-6565-44af-b709-0f88a4867c31	19d0db83-6560-4103-ac51-6d11e51c4d76	+9196msh6ywkg	$2b$10$Avbc6x/duAJmRGjsIJS3Yu.1dUD36Y/saHBmpbVewAdmRZnf.q0gK	t	2026-08-06 07:30:47.410678+00	2026-08-06 07:25:47.410678+00
b249fb3f-b142-4c4c-a006-16783d8f6d6d	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	+9195msh6ywkg	$2b$10$N3uO2HUjrAPT.9mIuZIu4OV6JipA6Zik7gh35RWmZH6Hc89rg49pS	t	2026-08-06 07:30:47.95775+00	2026-08-06 07:25:47.95775+00
7f9b3052-52ef-4e4f-83c0-306c878132a4	071354b7-e831-47f6-ac76-b927e48c0d23	+9198msh6yzph	$2b$10$Z.uzpGvsbNcWvwx6QqkNXey8t2zTNp2uVmRmf12b8IN0QVv2ZD7Qa	f	2026-08-06 07:30:53.35555+00	2026-08-06 07:25:53.35555+00
ac80794b-7e9b-4a90-b7bb-d4c4d9e1ef57	071354b7-e831-47f6-ac76-b927e48c0d23	+9198msh6yzph	$2b$10$yjEDFh9.1GcKsUWNE2/2tOcMUo./N2d10mNKO4NRJj3Oapwy0L9Vm	t	2026-08-06 07:30:53.619146+00	2026-08-06 07:25:53.619146+00
19014732-5aa8-451d-ad1b-051f55e25aab	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	+9198msh6z24r	$2b$10$zx0JjDezE/d3EN2pQO3C5uaICgOjMTro8XsKmm6r.xOzb4VFj1lEO	t	2026-08-06 07:30:54.572097+00	2026-08-06 07:25:54.572097+00
e7f87b1b-daf6-41ed-a364-260d038cbc7e	6a4d9674-6d2a-4be1-ab4c-213a45492132	+9197msh6z40o	$2b$10$ceYJVggd9R91Mgq7S4cK/uudt72nk3E8lHFssyLa6xxkbK/B1yade	t	2026-08-06 07:30:57.04751+00	2026-08-06 07:25:57.04751+00
6706c1e8-b3dd-4b66-89d3-baf4b002d1e3	afa30051-73b4-41e7-8b44-fe64122d74c6	+9194msh6zbqe	$2b$10$BhH4EsO1suD3T7riGvfcnO/Xhclo42GVxP06AVUUKJNYeFu70Jqvu	t	2026-08-06 07:31:07.245281+00	2026-08-06 07:26:07.245281+00
e6e040ce-daae-48b9-b037-44f1fd99a8bf	519b53fe-56c8-48ce-bd17-3e3bef8aef71	+9193msh6zbqe	$2b$10$yUwwwc9okpOdpJHFnBJ0e.TBkA.9MCb4JvFl45Ob0jMcq8swsN9ne	t	2026-08-06 07:31:07.731321+00	2026-08-06 07:26:07.731321+00
2ef0294f-c774-4f51-a4a5-ed38fcb1a0e2	8dce8e30-e3b1-4588-816e-60891d8a3202	+9194msh708vs	$2b$10$L4VLZpbfv2P6StVZ6QRkwenzi67zRiy535CtqjvJhH8WUZUlgLt56	t	2026-08-06 07:31:50.103015+00	2026-08-06 07:26:50.103015+00
cca27a43-cd5a-41f3-adb2-518180c9c5a4	a7d3612d-d0e9-4807-bdef-60f52458154c	+9193msh708vs	$2b$10$VoruzdZETCucG39r3/Z7/.wceOkYsEwFhJONqRFZmogjAWmJruIim	t	2026-08-06 07:31:50.537347+00	2026-08-06 07:26:50.537347+00
787989f3-a9c2-431d-b5fc-ff56c7cb3afd	eaf120d8-bd47-43fc-aa4b-975400c5f579	+9194msh70inh	$2b$10$UzkuowqTnTGk/JMGcQ/SRes0H5zQLbWLdSDp5bdXFrihpHetGo1Tm	t	2026-08-06 07:32:02.875954+00	2026-08-06 07:27:02.875954+00
139e4413-036b-44c0-b401-d7dceb7da048	355ba637-df1c-4775-8a5b-96c70b9a957a	+9193msh70inh	$2b$10$YcEfV5DbPNQb7zSx2/r4teEFBrR6hmm.tMX6bhJBRhME5hXZNcLta	t	2026-08-06 07:32:03.422109+00	2026-08-06 07:27:03.422109+00
09977cfc-8b13-4e8a-b4b9-418d574ee0d9	7eb32340-5dc9-4180-ae5f-626b2090eb41	+9196msh70lmv	$2b$10$CYkttAgvm2eKrNHsmb2s3eZT4..OX3/QyWXWmi5mCTmfg0To315gu	t	2026-08-06 07:32:06.541837+00	2026-08-06 07:27:06.541837+00
daa0915c-f707-4cb5-89d7-e5573bf873e7	367fdce2-dc07-4945-af3f-22a1305b03e0	+9195msh70lmv	$2b$10$nB4vfReXSm8AKLdCNp6rC.UqNjKjcbSKFEz0cXQSIRru4qh1wtOka	t	2026-08-06 07:32:06.957291+00	2026-08-06 07:27:06.957291+00
fc069a46-a621-4345-8d44-c1f2bea0bd86	f7f6622a-e693-48e5-a4c4-e3bb66f119b6	+9198msh70of5	$2b$10$R67WZohGfbfxIGBtVxVpCeVqyO9RLgyywZh/zvj/HENQC4yDBgu02	f	2026-08-06 07:32:12.043837+00	2026-08-06 07:27:12.043837+00
1db09d8b-c98e-48da-8492-040769ab1658	f7f6622a-e693-48e5-a4c4-e3bb66f119b6	+9198msh70of5	$2b$10$x77cw4a8XLnBavV9yxg.7uB9QUrGFCdgURUMAddjsGB40JWq/kzmK	t	2026-08-06 07:32:12.294474+00	2026-08-06 07:27:12.294474+00
23ddc166-9e8e-4b62-b0b6-6b718beb2c00	d91dd487-28c3-4f03-8206-3d7bc12e0765	+9192msh70qyd	$2b$10$B2u/mCsisYzuYkRrVZRUN.9.JZA5R0KN6FjSk2tzRmmThK3S21iTG	t	2026-08-06 07:32:13.492605+00	2026-08-06 07:27:13.492605+00
d8ee21d5-7a25-4e81-8ba8-251b50b0c7bf	b4163d69-9347-4fb5-8edf-0a58dedfd768	+9191msh70qyd	$2b$10$dS4vDd07Zf9ytRgbbzFWwOX3jNsMn19ln7/5aScnPR8s3g2rAyNj.	t	2026-08-06 07:32:14.040088+00	2026-08-06 07:27:14.040088+00
6ae59006-75a4-419d-ada4-1d8df2408a8e	7e3edba5-5360-4010-85d2-cc7e9e008b1d	+9190msh70qyd	$2b$10$u.PwgIn1ce5P9CEbTpvrSetnbRwlylL2DzQE2whwareLapUehgfFy	t	2026-08-06 07:32:14.824313+00	2026-08-06 07:27:14.824313+00
f6beecf5-9afc-469f-9976-6f4652512b0c	b521ee31-dd05-4b61-8902-a7d8e3359c87	+9198msh70tc1	$2b$10$DgCb.0mXcD3ipsI/1yJP/uuM/0YmkTnH3vYFLEt8As9bv9wvMDHY2	t	2026-08-06 07:32:16.773559+00	2026-08-06 07:27:16.773559+00
f51bd052-1503-483a-87eb-6597f23117c0	3b777f71-d8a8-4d5e-a3a5-9dbc0057b9ac	+9197msh70wht	$2b$10$hdazMEWbOPIqpGLrkgMHv.TEwL7HqenDi5NP/Wy0kEhXsfV2zzI9i	t	2026-08-06 07:32:20.820835+00	2026-08-06 07:27:20.820835+00
410aea49-6ad9-44ea-83ad-0d95567fb5d7	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	+918004362634	$2b$10$dMFNRwQPROSzEw7mhSTXluFA/jtlSYzjr8K11Ncj2fOlWCHM2dH0e	t	2026-08-06 07:33:09.528745+00	2026-08-06 07:28:09.528745+00
2af3022d-d12c-4e28-9e68-7841645ffa5e	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$E/eQJMYoLvDwI5IvbafVIeDDBzGIXoVUMdR72eyqBYUFRfKbRBxhy	t	2026-08-06 07:33:10.103648+00	2026-08-06 07:28:10.103648+00
2139bfda-e6fc-4999-b058-5e6fcd5f9719	08eb3e44-465f-45eb-965b-b6f56418ecdf	+9188msh7fja7	$2b$10$9ugsXgAert2DV7j2eZb/TuGrcmM1jZyFpL263/jOQBvxewjZw64b2	t	2026-08-06 07:43:43.511754+00	2026-08-06 07:38:43.511754+00
8d6c9cb8-c73b-4579-8464-8da39eba51a6	116d7e4c-e0b2-4591-ac73-e8918aaf3d91	+9188msh7fpyv	$2b$10$D8ha3QYYlyyjrTUE/LPTNemtApYs7LKGTYgsH7mYqlniMm3MyOlTK	t	2026-08-06 07:43:52.124189+00	2026-08-06 07:38:52.124189+00
2a1f3660-42a1-4df2-8d57-c934d24056d6	2f3e926f-0cbc-487f-bf08-9e1521cd4775	+9188msh7g6ld	$2b$10$kjrtZEGTNP/8tnIFYYDy2.W8Auu/TEyVRBN3aSLJxUP.z.3Lhi7fq	t	2026-08-06 07:44:13.638417+00	2026-08-06 07:39:13.638417+00
2f15fe00-415b-4eb2-9e2b-5d507a0e2e9b	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	+9194msh7gemf	$2b$10$qOBj6.ErNta9rAHpy/NRlu8vt.nXnjFREPJ4XvwXa7tjI2dq1cO52	t	2026-08-06 07:44:24.139204+00	2026-08-06 07:39:24.139204+00
6091c7e4-6082-411a-8f0b-49c40dd2a7a6	88e672cf-f466-4a22-b7c7-fabe8b127ee3	+9193msh7gemf	$2b$10$0YU/h8l3OFVcCh5iDuWyWesqgNMERte1YAZDHffOTGFjNPbpB3MZu	t	2026-08-06 07:44:24.657336+00	2026-08-06 07:39:24.657336+00
80b64728-c0b8-4696-8c11-82bfd2768658	1df93849-4a6e-4842-807d-e5df6c457760	+9198msh7ghuq	$2b$10$mMq7p8Fjz6ufyk283pi8/OOq29x7HV28iaxPRuyvEXgPjLHeETkCi	t	2026-08-06 07:44:28.196644+00	2026-08-06 07:39:28.196644+00
96260fd4-e719-4953-8907-63af13a2e67f	3bd0bf00-d276-46c2-ae5b-11870c818ec5	+9196msh7gk7k	$2b$10$ZcXrtdEEi44modsvPu3sK.l81tZVvPyFRHqyBQYWP0LWXThjRfea.	t	2026-08-06 07:44:31.406539+00	2026-08-06 07:39:31.406539+00
cfe95555-aaf5-4807-a82e-5ef12e99675d	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	+9195msh7gk7k	$2b$10$xLshogTvJRKW60kExSO2bOBSsnxCNuqT8NMdoutWwjmw3Jh0MZOUO	t	2026-08-06 07:44:31.999744+00	2026-08-06 07:39:31.999744+00
be65c5c0-604f-474a-baf5-33e4c6222fef	7ea9daf4-0016-43c4-b811-70ec6b60254d	+9192msh7gnje	$2b$10$mOvpCxAWd7q25Crpr3EXQeAJforO7CEgSWYk4aBACjT/r//Ra1nPm	t	2026-08-06 07:44:35.796407+00	2026-08-06 07:39:35.796407+00
5a901ee3-de99-4438-aac0-53494eff6c84	c3b43f87-73b1-435c-94a0-c45939b5ee02	+9191msh7gnje	$2b$10$y/04eg5MBO4dk5Uqtf8z3.9ZKE1BiPnq57oTJlYdyHbyhcWYtLhEK	t	2026-08-06 07:44:36.416841+00	2026-08-06 07:39:36.416841+00
37596cf4-866c-433a-90c2-f6796e5fe5b2	34f33792-5b04-4538-821b-d889040be905	+9190msh7gnje	$2b$10$TwBBxSPWGxPgHzwZcR5Jy.s0E93EKdD8163MbWXwIhk8uGxhsgDva	t	2026-08-06 07:44:37.429569+00	2026-08-06 07:39:37.429569+00
f5d21281-59e9-45b7-9791-4d82a208940f	75ba8615-b5a8-4bb7-85c6-4e028e1f3359	+9198msh7gquh	$2b$10$8N3uN.VxZL0GN2JI3yfcauoazpQ6yrN7KEM68WBdKlBiBSg47kzoO	f	2026-08-06 07:44:41.786841+00	2026-08-06 07:39:41.786841+00
67746fe6-22f2-47cc-96d0-f0a0ce46effb	75ba8615-b5a8-4bb7-85c6-4e028e1f3359	+9198msh7gquh	$2b$10$mf6ZZKAK4CRanhTVBpXiwesgz1eoXKTt/P1RQFfrLPeWItEwFjPi6	t	2026-08-06 07:44:42.035761+00	2026-08-06 07:39:42.035761+00
23d79a5b-fe79-499d-8680-900629439bb5	ca5f760e-7b1d-46d9-b000-1d6041f494a5	+9188msh7gtbd	$2b$10$riSucM41LLoUM4z.zBWUguWP62Z8jTongCmxzrKa0Wu4sieKGkmCW	t	2026-08-06 07:44:43.145962+00	2026-08-06 07:39:43.145962+00
e5711328-a9ae-4b1a-8de2-f7e8af99c632	d95d19dd-5d82-4068-83c6-3683294a76df	+9197msh7guqf	$2b$10$AHfDmI5jyO92kcrvhxRbPuODRqVhTLN2sgJpgTqlOVN1eZ7.0G.qu	t	2026-08-06 07:44:44.928893+00	2026-08-06 07:39:44.928893+00
466a8fae-2de6-4bd9-936c-8bb69de6b7e4	010bb5b8-d47d-43d9-87e1-4cb2e927b635	+9188msh7h557	$2b$10$kxJUT0pE.NA.LXCaW6jwOunnXiB3PxnaY1iCRXz1Qmni0iNpJcrX2	t	2026-08-06 07:44:58.356909+00	2026-08-06 07:39:58.356909+00
7e90c4d3-2689-4bca-bb51-b044b2e1149e	89f81735-a971-4f31-be35-afce72c93bfc	+9194msh7h6dr	$2b$10$NdgLgRDAugUQlR0Op//0DeM7HpzD.pGYZZwxZqo.0dvu.9g2QrTli	t	2026-08-06 07:44:59.9882+00	2026-08-06 07:39:59.9882+00
5673dff5-dd47-4164-8ccb-a4325e26e5a3	6e792cb8-9a1f-4c40-a825-985a1dd5b706	+9193msh7h6dr	$2b$10$MIZ4vDxq3VSQeMg3L1f9YeqsJ2gkvjOw1i7t4tUYXWCoko9ArgDE6	t	2026-08-06 07:45:00.463721+00	2026-08-06 07:40:00.463721+00
28599c09-3b01-4ff6-8e9b-65152bcffe97	c118f901-1a69-4866-98b8-677f315742a1	+9196msh7h9pf	$2b$10$LsJRwEqOdvt1womZdodZ2.RipzeC7I0vMcQ8tUePPn9kkcR3eq15W	t	2026-08-06 07:45:04.440412+00	2026-08-06 07:40:04.440412+00
e3e69b89-2eb8-4b60-937c-858af26fefab	cf11c185-cff1-4c4c-a254-63c9cae16950	+9195msh7h9pf	$2b$10$o9iD9jv4AmcGczGdwoRolO0yrYVhdTnT8nEc/S9PTJ1QLK1ciH122	t	2026-08-06 07:45:04.842916+00	2026-08-06 07:40:04.842916+00
32650b0a-6204-44da-9611-220df35f3dc5	77a4ff3b-0afa-4776-8504-a026984e3b14	+9192msh7hdcv	$2b$10$SDtsgVeQqrQ44v8Bayhq7.Jvo4OI7R7i9zt.HaQC6k1XMkiymka7W	t	2026-08-06 07:45:09.10487+00	2026-08-06 07:40:09.10487+00
c81987f8-338f-42f6-9f77-0a36effa1af8	0a0ca69a-734a-464d-846d-03905795c51c	+9191msh7hdcv	$2b$10$l6VUR5lx2GFPceJiCMmXpus2Et9ckXVXKt5.zsB9hBhtKaKg3ozR2	t	2026-08-06 07:45:09.617898+00	2026-08-06 07:40:09.617898+00
028f2f01-a27e-4e59-b11f-d2109e29768f	7c008e59-0297-4961-9f2e-33ffde5fa520	+9190msh7hdcv	$2b$10$lQ7foIYGxwpw4snDmksMaeN2VEyZ0nH9NOPic73K5osR6l4IFpIZS	t	2026-08-06 07:45:10.328493+00	2026-08-06 07:40:10.328493+00
53114731-1e73-4a44-9d6e-98160a54767b	36163d7d-711d-4a3e-bc45-31eaeba1d21b	+9198msh7hfuj	$2b$10$0fNzNZZuKOzZuj8ArqwBwupSWJcOja0Bs1Pg4.VSDdfvi4ygmvuc.	f	2026-08-06 07:45:14.454744+00	2026-08-06 07:40:14.454744+00
950d3d19-86d7-42a7-a41a-84c672a9da03	36163d7d-711d-4a3e-bc45-31eaeba1d21b	+9198msh7hfuj	$2b$10$D0HJWwkvi99OquX24vLEreNdZmQEWNFmtRV4PhOkH98B6xwG0N/KS	t	2026-08-06 07:45:14.75893+00	2026-08-06 07:40:14.75893+00
c07a03ee-0fd1-4f52-80a6-dcef4c970ac5	68dc303d-4fe0-423a-a6cb-9383ff75a1da	+9198msh7hilz	$2b$10$/BxUbv.1HVzD2/li5kewOOhU0anZBaFYsYHZR2nW/udewvhguy5/u	t	2026-08-06 07:45:15.819892+00	2026-08-06 07:40:15.819892+00
dc121327-e14d-457c-9563-9c5c7abaa08d	778e0a0e-af86-42de-bc86-f9ce5f47c98e	+9197msh7hkkz	$2b$10$RuawytlcilmMfAPivDHLPu3XLkAzGRHRXW2afqtIyG.qLGySt5UPq	t	2026-08-06 07:45:18.536602+00	2026-08-06 07:40:18.536602+00
081d7ce5-9ffe-410a-b8fa-e3bfd7d9afdb	605f37bc-fb38-43e6-b3bc-11412f4a1724	+9188msh7hzxu	$2b$10$N3uxAZVrsHNi3VSXyDB8yepjWlcPLynyHvq4Nf55/eeVeuojrG4Le	t	2026-08-06 07:45:38.51801+00	2026-08-06 07:40:38.51801+00
7574b9fb-b8e2-43ca-82a3-9167717244d4	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	+9196msh7i1lj	$2b$10$P2CNBmsS/zC6U1IIlRGvO./5BaS5AJqMVUEPOBOUpt.m/WifZkyTe	t	2026-08-06 07:45:40.643791+00	2026-08-06 07:40:40.643791+00
f3f4364e-b44a-4c21-ae88-3b3ca858327a	9a619129-5447-45a7-b1a9-45ca14708e7b	+9195msh7i1lj	$2b$10$I1tlj/0NJ5Nworo9bi2EA.R4ICgqS6E5E38fVx7czcXjeR24HSrFW	t	2026-08-06 07:45:41.222762+00	2026-08-06 07:40:41.222762+00
4664a68d-cd1d-46af-9925-5f382eddbb30	7c916865-cac4-42be-a99b-c45e15e6845e	+9194msh7i5i1	$2b$10$kGoEumdy/3SUi0nRBq8cHeNMn/aItASrWKaCLV8p1XEEnduT4R6hS	t	2026-08-06 07:45:45.607231+00	2026-08-06 07:40:45.607231+00
959e8623-ed42-4be0-bc5d-8d27c89d176f	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	+9193msh7i5i1	$2b$10$bwvUtFdHR4zZ82lDBZah5exC1u9hGUgHqfZZc2YtYpow5qOGQ3eWK	t	2026-08-06 07:45:46.035294+00	2026-08-06 07:40:46.035294+00
ce7d8d1e-cff1-401a-bb7e-2793abc1ae84	4c071db4-45a4-4caa-8fa7-8c1c783785e2	+9198msh7i8da	$2b$10$jyh6zRKPaz3yNajdglveFu16hABAMtGnBfvaTz/vAvuT7T28.QdOC	f	2026-08-06 07:45:51.723746+00	2026-08-06 07:40:51.723746+00
20ceb561-7de1-4ee7-aabe-dc1fa3b33049	4c071db4-45a4-4caa-8fa7-8c1c783785e2	+9198msh7i8da	$2b$10$GuR9QAImo7vz26qSgf7pN.KLDxMKzXaUkfx6irgCMxJ84P16EI.6S	t	2026-08-06 07:45:51.974819+00	2026-08-06 07:40:51.974819+00
6c3821f9-d03c-45b7-93be-643bf9981596	215f7372-6d92-40ec-9f9a-1879debb080d	+9192msh7ibc6	$2b$10$floxjeBVtrJfEJuAMSeY3O31s3Kxte.TJWppwbnP17PrQHVi6vij6	t	2026-08-06 07:45:52.99178+00	2026-08-06 07:40:52.99178+00
1c21f9e2-a493-4b3f-97aa-0b73f8d6b654	0270429b-5a36-466a-82f5-0dbe02c49821	+9191msh7ibc6	$2b$10$/mFVKhBCCcO5cx7UGbdynOop6BjbSDGmjs51Jt2Kx9Ap6yuwzXb7a	t	2026-08-06 07:45:53.441764+00	2026-08-06 07:40:53.441764+00
31a051ec-9c76-453a-a09e-d0f97cd94a08	a4d79652-4ef8-40be-b7ab-ca04aaee390d	+9190msh7ibc6	$2b$10$BnmSPx4wq0iastdEF0InL.cBdHoxtTEmmuD8ZQ0eSOicmhX28RTBG	t	2026-08-06 07:45:54.104935+00	2026-08-06 07:40:54.104935+00
26fc78ae-7304-4530-b29e-e53c462f203a	68347b75-b32a-4bb4-9189-76fd0c9d4947	+9198msh7idha	$2b$10$/Wes.Go94.Enam/dFYGcde/74VYicxR8VduxoiOB0iK6/btEIViDy	t	2026-08-06 07:45:55.822518+00	2026-08-06 07:40:55.822518+00
d655dee8-4ebf-4c7b-84c1-77c5b58a128d	c82e6b63-ac48-40f4-b8f3-0be99df54466	+9197msh7ifdc	$2b$10$2kikqB.wrldhqO0CgeucnOcbRK3jGUFdDddJFyJaxMps2cwdtyQvK	t	2026-08-06 07:45:58.230347+00	2026-08-06 07:40:58.230347+00
1745d14b-6c5a-4b57-9729-9b455d655d21	886d75e0-e090-4177-a6d8-570db8b1208c	7007708213	$2b$10$EDcE1NkYPODr3FpzVu3A4OtFnKWeMmeS/UfqVTC7/xcxBUeO5CEP6	t	2026-08-06 07:47:04.609158+00	2026-08-06 07:42:04.609158+00
\.


--
-- Data for Name: PrivacySettings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PrivacySettings" ("UserId", "PhotoVisibility", "ContactVisibility", "ProfileVisibleTo", "ShowOnlineStatus", "UpdatedOn") FROM stdin;
318ed88a-c7bf-4ab7-b73a-85007e92a400	premium_only	matches_only	everyone	t	2026-08-05 12:51:54.95768+00
61c7677e-2d35-423c-9088-77f26fd210ec	premium_only	matches_only	everyone	t	2026-08-05 12:52:15.128491+00
ef29ab34-0926-4d68-b3a8-f9972bb2a232	premium_only	matches_only	everyone	t	2026-08-05 12:52:38.402521+00
dc416aae-d920-4b18-a151-fd516b79bc27	premium_only	matches_only	everyone	t	2026-08-05 12:52:54.703793+00
36615d5a-0131-4c21-98e3-956ceca31d48	premium_only	matches_only	everyone	t	2026-08-05 13:01:29.846564+00
b0422680-a14b-46b5-aa9d-d9d226b3a071	premium_only	matches_only	everyone	t	2026-08-05 15:24:18.397502+00
98b38f18-ee4b-459f-b9cd-ddaf62d1f6da	premium_only	matches_only	everyone	t	2026-08-05 15:31:18.253835+00
7ef79457-71f5-4e8c-bb17-fee5ba9da51d	premium_only	matches_only	everyone	t	2026-08-05 15:32:15.404901+00
5aa1f3bc-0de4-4093-ac1e-3859b13929d2	premium_only	matches_only	everyone	t	2026-08-06 02:30:39.987156+00
3c27e34d-8df3-456a-8b12-079170f1f55b	premium_only	matches_only	everyone	t	2026-08-06 06:32:38.392493+00
f87a94fc-f840-4b86-a2c5-1c32001d8a05	premium_only	matches_only	everyone	t	2026-08-06 06:33:30.284514+00
ccef9aeb-4e3c-4923-bb15-f364e42fa1ac	premium_only	matches_only	everyone	t	2026-08-06 06:34:03.426725+00
639ff8c2-a929-4dbd-9f14-e19826bf1da3	premium_only	matches_only	everyone	t	2026-08-06 07:24:34.955022+00
56e227be-5f34-465e-b71c-9fb4ecd94d98	premium_only	matches_only	everyone	t	2026-08-06 07:25:09.392914+00
6a4d9674-6d2a-4be1-ab4c-213a45492132	premium_only	matches_only	everyone	t	2026-08-06 07:25:57.907781+00
3b777f71-d8a8-4d5e-a3a5-9dbc0057b9ac	premium_only	matches_only	everyone	t	2026-08-06 07:27:21.585293+00
d95d19dd-5d82-4068-83c6-3683294a76df	premium_only	matches_only	everyone	t	2026-08-06 07:39:45.853495+00
778e0a0e-af86-42de-bc86-f9ce5f47c98e	premium_only	matches_only	everyone	t	2026-08-06 07:40:19.705589+00
c82e6b63-ac48-40f4-b8f3-0be99df54466	premium_only	matches_only	everyone	t	2026-08-06 07:40:59.107561+00
\.


--
-- Data for Name: ProfileViews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProfileViews" ("ViewId", "ViewerUserId", "ViewedUserId", "ViewedOn") FROM stdin;
1d27c8c7-c71a-4347-8454-0877bef8c853	1993fb25-6147-4b5d-bb36-88f756254fd6	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	2026-08-05 15:23:58.210191+00
17d53325-737e-4428-8d31-1e709383b7c2	1993fb25-6147-4b5d-bb36-88f756254fd6	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	2026-08-05 15:23:58.643032+00
ab58cb96-d4ef-49ae-a3b4-e6b173e3ae3d	c8a549c1-0fe0-4e7f-af9e-56cc61372088	efcd6ed2-c765-4041-9feb-cd72f820ee45	2026-08-05 15:24:13.467445+00
2a061988-700f-472e-9bce-2bdc180d01ec	c8a549c1-0fe0-4e7f-af9e-56cc61372088	efcd6ed2-c765-4041-9feb-cd72f820ee45	2026-08-05 15:24:13.875305+00
7b306676-b2d7-4d4d-8ea9-10a8ad663fd8	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	e576df13-6cd8-44a2-be61-44cb945bc25a	2026-08-05 15:24:37.705013+00
d83c2fdf-b4d0-4db1-8c3e-1141d32f1dd2	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	e576df13-6cd8-44a2-be61-44cb945bc25a	2026-08-05 15:31:01.331761+00
c110ad36-0442-47c7-8386-20d797767ffb	44edbe9e-2762-4722-bac2-b9731acd35b7	fbd4b51b-493b-429d-a938-94354ce49c63	2026-08-05 15:32:02.594376+00
57b91afc-0885-48b2-b1f7-a6af5e0d1341	44edbe9e-2762-4722-bac2-b9731acd35b7	fbd4b51b-493b-429d-a938-94354ce49c63	2026-08-05 15:32:03.167573+00
2fab80c9-4dc7-4d69-95f7-9e8b0ed6eaa1	a8ba3347-742a-4523-aed8-77c774142345	3d8c7d31-67c4-4023-b401-4ac046cf56ac	2026-08-05 15:32:20.027878+00
d522b707-6d81-4bb0-938b-027cf3433a2b	a8ba3347-742a-4523-aed8-77c774142345	3d8c7d31-67c4-4023-b401-4ac046cf56ac	2026-08-05 15:32:20.485114+00
621a85fe-e1a7-46ef-b614-b9b4f639689e	36615d5a-0131-4c21-98e3-956ceca31d48	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 15:49:03.733649+00
0b6ac83b-10f7-4ec7-b22e-1c6aafc0544c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 17:21:50.039753+00
8e7fd10c-cdd2-4773-844e-a61a0f7d8a5d	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	fd039e52-629b-489a-b445-3003be85cb8d	2026-08-05 17:32:09.191768+00
bd46c1e8-10e8-4b5a-8ffe-7fbc92a4f7f9	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	d45844b4-81d5-448a-9e5b-549832b07407	2026-08-05 18:20:02.730013+00
08ec9405-58cf-4b60-86f4-465ff9cbce44	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-05 18:20:37.469051+00
db7f8bf0-c435-48f5-99d4-97dd064a8694	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-05 18:21:55.81265+00
26733fe4-da57-42d0-be0d-1700f7b347ea	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	2026-08-05 18:23:59.928471+00
904d0940-3b90-4e6a-bda3-048fc1318939	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	2026-08-05 18:25:27.900396+00
50599f8c-52a2-4869-bd90-d7aeb6e0769e	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	5b90a2de-8e41-493d-8311-e21b2e27a452	2026-08-05 18:48:38.460044+00
03d8bc7f-61ae-4ad0-bea0-0290e71a5e0d	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-05 18:49:56.957262+00
684c33cd-d5e0-4557-8902-6603858ed1df	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-06 02:25:41.3104+00
da8c51a7-e8b9-4ba9-965c-91abd831cff0	e2fd25fb-510b-4af5-a453-84ab5a69cf21	f1d17cc9-15ee-4758-846e-e01e49b8779a	2026-08-06 02:29:49.028281+00
ffdf2308-e88c-44bd-bfa2-11a30dd2469f	8b6fae7c-974a-4d6e-9221-f37cf6a97469	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	2026-08-06 02:29:58.026757+00
181a70de-8b6b-433c-a471-689fd93ea5ab	3f591c6a-5509-45f9-a2e5-050be735735a	f5a61371-a191-4bfe-9659-1a05b788696b	2026-08-06 02:30:19.382766+00
3558697a-ffae-4cac-9f21-13cc72180949	6c982b06-1aca-4977-b319-191e16fc4de6	15628c01-d0a0-422c-95b2-dcc978ad6fa1	2026-08-06 02:30:32.387437+00
73bec641-8140-4930-9168-9da4fdcc2b88	2d150870-1d4e-42e0-863c-0bad5782141e	d4e10fc0-e272-4867-81cd-567a0e84cfdf	2026-08-06 02:30:35.569908+00
f7b35b71-6fd3-4143-a06f-76ac2914ba3a	2d150870-1d4e-42e0-863c-0bad5782141e	d4e10fc0-e272-4867-81cd-567a0e84cfdf	2026-08-06 02:30:36.045718+00
dd02d9f2-8358-4998-8857-54ca854b7ef2	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	2026-08-06 06:32:30.833045+00
774ffd88-b381-49be-9a8f-864f815c1546	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	2026-08-06 06:32:31.261339+00
c61626d9-8cf2-4e99-90a6-bc2e66827ad5	679a9cbd-c4bc-4326-a754-e6d09a55b010	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	2026-08-06 06:32:34.440043+00
e0fb0bc3-d87c-44bb-a568-0d7b7c220306	1c16cafc-57a6-4651-b25f-a364716b322e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	2026-08-06 06:33:21.062332+00
1749f45a-c2b8-4eeb-9506-8b876a248439	1c16cafc-57a6-4651-b25f-a364716b322e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	2026-08-06 06:33:21.547661+00
9a7bd60a-1684-474e-92d1-ddb954c3b0d2	6df70e40-bb74-457a-a687-5e470514447b	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	2026-08-06 06:33:26.02774+00
c0fc476c-8183-4512-a53f-1af798d26370	287fea1f-a616-4b7f-82f8-fc0886dceda0	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	2026-08-06 06:33:51.211984+00
8ba9794b-3973-41ec-bed7-c5b8eb66d769	7294e7cd-2388-4a10-9e3a-31f532b748ee	d7c3fa7c-c268-4e5c-acec-0450571fdb18	2026-08-06 06:33:58.069778+00
6ba6309c-6d42-4aa2-97bf-4b42d3bc16f9	7294e7cd-2388-4a10-9e3a-31f532b748ee	d7c3fa7c-c268-4e5c-acec-0450571fdb18	2026-08-06 06:33:58.499327+00
5916ff0b-0fdf-4c20-8206-1abd1a016c10	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-06 06:48:37.852755+00
64d77e7f-934f-4bda-9067-4e36a7c04852	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	2026-08-06 06:53:46.223805+00
9eccecb6-5b85-49ab-9dfd-1bed03f7f37b	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	886d75e0-e090-4177-a6d8-570db8b1208c	2026-08-06 06:53:48.43064+00
a202fe57-a8d5-43e6-9e5a-a8d8401b9ce2	886d75e0-e090-4177-a6d8-570db8b1208c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	2026-08-06 06:57:45.16321+00
c43a767b-bbbf-47b7-9161-776278af9378	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	2026-08-06 07:24:25.86344+00
dd80bc0d-c0c4-46ba-b98c-d231676a5ae2	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	2026-08-06 07:24:26.375755+00
a7f18f9d-a3a4-4749-b5a1-7c37838fa428	7607d532-01cb-4685-93d0-019c266c06ca	150f70a6-62b8-44b8-95bb-3e78bbd916be	2026-08-06 07:24:30.04718+00
45f5ef6b-eb6b-40f7-b6f0-306eb414bd56	86061e0a-d9e9-4fd4-91cc-f4113ffece92	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	2026-08-06 07:24:53.11276+00
ca48f05b-0068-42bf-8fce-06eb93b2dcf1	ddcd3ad5-423b-436e-b921-4322d3397be4	cf8b1225-10c8-42b4-81a9-6dc603b4b753	2026-08-06 07:24:59.809146+00
e4c72411-2ca5-4fa7-a941-148e1bb6e099	ddcd3ad5-423b-436e-b921-4322d3397be4	cf8b1225-10c8-42b4-81a9-6dc603b4b753	2026-08-06 07:25:00.269565+00
5f66228d-2a56-4e78-9f14-29ad4698085a	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	80208c67-25c3-4c79-8fd5-90b2d0440bba	2026-08-06 07:25:43.541781+00
f137f4b2-f3ab-4112-90ee-86217ba5fc7b	19d0db83-6560-4103-ac51-6d11e51c4d76	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	2026-08-06 07:25:50.172983+00
5d9b8ea7-6db2-4a35-ba21-34cdf3324c11	19d0db83-6560-4103-ac51-6d11e51c4d76	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	2026-08-06 07:25:50.69577+00
d9bac778-2611-45c4-b134-2df37207bebe	afa30051-73b4-41e7-8b44-fe64122d74c6	519b53fe-56c8-48ce-bd17-3e3bef8aef71	2026-08-06 07:26:10.105952+00
f4c5699f-e453-4071-8d0b-7aa1291d9bcb	8dce8e30-e3b1-4588-816e-60891d8a3202	a7d3612d-d0e9-4807-bdef-60f52458154c	2026-08-06 07:26:53.090968+00
80dc0a3b-38fa-4ce1-8ab3-35cf4ce9aec8	eaf120d8-bd47-43fc-aa4b-975400c5f579	355ba637-df1c-4775-8a5b-96c70b9a957a	2026-08-06 07:27:05.714079+00
770a010a-ea77-4365-ac89-d2c78b597cc5	7eb32340-5dc9-4180-ae5f-626b2090eb41	367fdce2-dc07-4945-af3f-22a1305b03e0	2026-08-06 07:27:08.849759+00
bd275b39-b2d4-4c8a-853a-18f0b48e2b42	7eb32340-5dc9-4180-ae5f-626b2090eb41	367fdce2-dc07-4945-af3f-22a1305b03e0	2026-08-06 07:27:09.405757+00
042df48d-f8a7-4daf-8fe4-1935ac586da1	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	88e672cf-f466-4a22-b7c7-fabe8b127ee3	2026-08-06 07:39:27.335818+00
7b30d587-02f8-4122-85cc-bfa9fbce2273	3bd0bf00-d276-46c2-ae5b-11870c818ec5	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	2026-08-06 07:39:34.070181+00
04397351-00a6-4b43-a57f-9b2050545373	3bd0bf00-d276-46c2-ae5b-11870c818ec5	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	2026-08-06 07:39:34.745751+00
79714478-c50d-4b21-9f0b-4cb3211e5538	89f81735-a971-4f31-be35-afce72c93bfc	6e792cb8-9a1f-4c40-a825-985a1dd5b706	2026-08-06 07:40:03.379829+00
332e31c8-f09b-489d-8650-f955c81c7f61	c118f901-1a69-4866-98b8-677f315742a1	cf11c185-cff1-4c4c-a254-63c9cae16950	2026-08-06 07:40:07.559053+00
c70a6ca8-176f-4111-9124-f9943790e9e1	c118f901-1a69-4866-98b8-677f315742a1	cf11c185-cff1-4c4c-a254-63c9cae16950	2026-08-06 07:40:08.227769+00
b54ab068-d909-42e7-bf23-580c7ec736c3	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	9a619129-5447-45a7-b1a9-45ca14708e7b	2026-08-06 07:40:44.19789+00
2ac4639b-a878-4f7d-af95-4393bfc1faa2	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	9a619129-5447-45a7-b1a9-45ca14708e7b	2026-08-06 07:40:44.711128+00
5d738579-18f8-4a51-9796-504677978025	7c916865-cac4-42be-a99b-c45e15e6845e	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	2026-08-06 07:40:48.342834+00
\.


--
-- Data for Name: Reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Reports" ("ReportId", "ReporterUserId", "ReportedUserId", "Reason", "Description", "Status", "ReviewedBy", "ReviewedOn", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: SuccessStories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SuccessStories" ("StoryId", "UserId1", "UserId2", "Testimonial", "PhotoUrl", "MarriageDate", "IsPublished", "ApprovedBy", "CreatedOn") FROM stdin;
\.


--
-- Data for Name: UserEducation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserEducation" ("EducationId", "UserId", "Qualification", "College", "University", "PassingYear", "EducationType") FROM stdin;
ce4060a0-9c4d-4dd8-aead-c4f8c49ebb9e	60f50480-cbe7-45b2-b94a-462ddc882514	B.Tech	IIT	IIT Delhi	2017	Full-time
8e54d1ed-8a15-4111-a409-69cd0b02ed99	5b90a2de-8e41-493d-8311-e21b2e27a452	B.Tech	IIT	IIT Delhi	2017	Full-time
ca1fd65f-c3d7-4a44-bf50-e5c97073fcd3	36615d5a-0131-4c21-98e3-956ceca31d48	MA	LU	Lucknow University	2020	full_time
d639bc66-69e2-472e-89b0-26d799c177a8	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	B.Tech	IIT	IIT Delhi	2017	Full-time
b1188fec-dcd7-4aa6-93d4-07cca63928c5	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	B.Sc	\N	\N	\N	\N
6a3228ad-59ce-41ac-b5a3-9d78c7f556df	efcd6ed2-c765-4041-9feb-cd72f820ee45	B.Sc	\N	\N	\N	\N
85d71705-2955-436f-b8cb-390228beb563	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	B.Tech	IIT	IIT Delhi	2017	Full-time
94be0f7a-fceb-4140-b6df-1612febd5f2c	d45844b4-81d5-448a-9e5b-549832b07407	B.Tech	IIT	IIT Delhi	2017	Full-time
a246c683-8d1b-4709-b43e-674dd1b22ba3	e576df13-6cd8-44a2-be61-44cb945bc25a	B.Sc	\N	\N	\N	\N
d548b69c-7d8d-41f6-bacf-365f69bd1922	59296eac-cc9d-44d1-913d-a5ef3365343c	B.Sc	\N	\N	\N	\N
86c8c1bd-622b-4d6b-9e63-5feb4de6bfee	fbd4b51b-493b-429d-a938-94354ce49c63	B.Sc	\N	\N	\N	\N
a84e4265-db6d-4688-bd04-46a1deea2376	3d8c7d31-67c4-4023-b401-4ac046cf56ac	B.Sc	\N	\N	\N	\N
4e5889bc-0752-4362-8fb9-60065d724fbd	fd039e52-629b-489a-b445-3003be85cb8d	B.Tech	IIT	IIT Delhi	2017	Full-time
e06e6455-fadd-4734-bec7-23170f064c86	886d75e0-e090-4177-a6d8-570db8b1208c	Bachelor's Degree	Integral University	Integral University	2010	full_time
2424b349-aa1f-4541-b874-b43c135bad02	d4e10fc0-e272-4867-81cd-567a0e84cfdf	B.Sc	\N	\N	\N	\N
0972b6cc-562d-42ee-8b0e-30fdf8783372	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	B.Tech	IIT	IIT Delhi	2017	Full-time
99934b95-51de-438a-8749-c25dd351b450	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	Bachelor's Degree	MGM	Integral	2009	full_time
0aee83fc-0efc-41c6-874e-94408f5d36ed	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	B.Sc	\N	\N	\N	\N
97a65b20-1d15-48a3-bbd9-833692de2275	3033d43d-8034-498f-b48d-5c549e8f97fb	B.Tech	IIT	IIT Delhi	2017	Full-time
a606d7f5-de8c-47a4-b533-aab4f91eb77e	eebc8df0-9557-4dbe-9644-ebe4a13b931c	B.Sc	\N	\N	\N	\N
dd9ead2b-cafd-43c6-b2ad-164d783184b1	5fd98325-1ea1-44ab-904c-b7d9c64df81a	B.Tech	IIT	IIT Delhi	2017	Full-time
4ef85f8a-2e69-49a7-b9a1-fa311f64b200	d7c3fa7c-c268-4e5c-acec-0450571fdb18	B.Sc	\N	\N	\N	\N
e8dc7599-b12c-49e3-99e8-e1590c853772	efe874e3-dc4c-4942-a44b-98f2a856525a	B.Tech	IIT	IIT Delhi	2017	Full-time
ce037ee2-45bd-4caf-a33d-231d94ded5d9	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	B.Sc	\N	\N	\N	\N
78009fbd-dede-4e39-9022-9e9a14b84696	744043a1-ee52-4e5d-a5d7-91221762e13a	B.Tech	IIT	IIT Delhi	2017	Full-time
7737a194-2c79-42ad-9444-7799156d33f0	cf8b1225-10c8-42b4-81a9-6dc603b4b753	B.Sc	\N	\N	\N	\N
775d9cb8-9ad4-4633-9350-10991fe5fb82	d1ced440-d263-4434-a49f-2817345f0c27	B.Tech	IIT	IIT Delhi	2017	Full-time
bf3b0225-d8a0-4edc-a607-c79fbd84458c	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	B.Sc	\N	\N	\N	\N
e4945f00-1ee2-4806-a180-6c430a6a889a	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	B.Tech	IIT	IIT Delhi	2017	Full-time
cbb7f858-c8b1-45c6-99b9-83b03e020aa4	367fdce2-dc07-4945-af3f-22a1305b03e0	B.Sc	\N	\N	\N	\N
55a723e5-1026-4a91-99fe-9f60d737fbee	b521ee31-dd05-4b61-8902-a7d8e3359c87	B.Tech	IIT	IIT Delhi	2017	Full-time
49e4af53-9c17-41d0-af48-56691c7a975d	1df93849-4a6e-4842-807d-e5df6c457760	B.Tech	IIT	IIT Delhi	2017	Full-time
eac20136-9cf5-49b4-a9d8-5023911f2977	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	B.Sc	\N	\N	\N	\N
0ee00967-f81a-4eaa-9c42-528cc0230055	cf11c185-cff1-4c4c-a254-63c9cae16950	B.Sc	\N	\N	\N	\N
e509cb06-26ef-4f3e-9896-362cf50f7fe9	68dc303d-4fe0-423a-a6cb-9383ff75a1da	B.Tech	IIT	IIT Delhi	2017	Full-time
8aad0d29-974b-41cc-8937-3c1124e47361	9a619129-5447-45a7-b1a9-45ca14708e7b	B.Sc	\N	\N	\N	\N
a2e31d5e-950e-4918-9df9-4ad985720b38	68347b75-b32a-4bb4-9189-76fd0c9d4947	B.Tech	IIT	IIT Delhi	2017	Full-time
\.


--
-- Data for Name: UserFamilyDetails; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserFamilyDetails" ("FamilyId", "UserId", "FamilyType", "FamilyStatus", "FatherName", "FatherOccupation", "MotherName", "MotherOccupation", "Brothers", "Sisters") FROM stdin;
493d2160-dd7f-4bc7-b60a-e8ff09991e73	60f50480-cbe7-45b2-b94a-462ddc882514	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
31d5d1c2-804d-4ff4-8cab-05b9a8fd3f51	5b90a2de-8e41-493d-8311-e21b2e27a452	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
394ee5a9-abc8-4203-b347-106cb20dc1da	36615d5a-0131-4c21-98e3-956ceca31d48	Nuclear	Middle class	Imran	Retired	Saira	Homemaker	1	1
c76c0f02-7f2b-4fdc-8667-23aaa1d11814	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
5cfe5015-304c-43e9-b66a-5b28b286403d	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
fe8673d8-f669-40e2-998c-e4d0b55343da	d45844b4-81d5-448a-9e5b-549832b07407	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
cbe8e44b-1197-476b-93fb-b4c9936669ac	fd039e52-629b-489a-b445-3003be85cb8d	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
9f9c465f-9ecf-42eb-84c3-a472cdb27e88	886d75e0-e090-4177-a6d8-570db8b1208c	nuclear	middle_class	Izhar	Businessman	Quraisha Bano	House Wife	5	4
8ddbed91-c9f1-4a13-928e-62997e21094d	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
012c08e1-b22f-4973-ad3c-83b4baa241ac	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	nuclear	middle_class	Javed	Advocate	Lubna beg	home maker	1	0
78f4a0d0-8001-4dff-a5ca-323fa757e9d1	3033d43d-8034-498f-b48d-5c549e8f97fb	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
365f36e9-88b1-4715-bd04-1f4c7a4188ce	5fd98325-1ea1-44ab-904c-b7d9c64df81a	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
bb537ab6-90d1-452d-87cc-c634bfa5484a	efe874e3-dc4c-4942-a44b-98f2a856525a	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
ccde97ca-8ebd-44b4-93d6-7b635155c304	744043a1-ee52-4e5d-a5d7-91221762e13a	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
c25f4446-bfd0-4fc6-8094-ccf09cbf9f63	d1ced440-d263-4434-a49f-2817345f0c27	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
6e453b06-0520-40bd-a773-59096673bab7	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
c1c6ae73-c82f-437d-9790-90ce13efb9f9	b521ee31-dd05-4b61-8902-a7d8e3359c87	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
8f534399-eb44-4f6d-b962-54ac0080dee5	1df93849-4a6e-4842-807d-e5df6c457760	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
0ab4c56c-64bb-4971-b513-2de64e876081	68dc303d-4fe0-423a-a6cb-9383ff75a1da	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
6046c17d-6e50-47a5-b17b-f7c68f01748a	68347b75-b32a-4bb4-9189-76fd0c9d4947	Joint	Middle class	Ahmed	Business	Fatima	Homemaker	1	2
\.


--
-- Data for Name: UserLifestyle; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserLifestyle" ("LifestyleId", "UserId", "Diet", "Smoking", "Drinking", "Hobbies", "LanguagesKnown") FROM stdin;
78acaec5-1299-4511-86e0-c0fb96ef6d4a	60f50480-cbe7-45b2-b94a-462ddc882514	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
597e2a5c-158f-428e-92a0-3abe65d33743	5b90a2de-8e41-493d-8311-e21b2e27a452	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
ca81b81e-ee09-41b9-8522-b5918064adcf	36615d5a-0131-4c21-98e3-956ceca31d48	non_vegetarian	f	f	Cooking, reading	Hindi, Urdu, English
0b7e0462-7e48-4aa1-9758-ffc7c0e95047	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
58cab436-9f24-4dad-a496-08041280906a	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
f05a1e15-78fb-4a9c-a546-1512847f914c	d45844b4-81d5-448a-9e5b-549832b07407	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
6e0d907f-994d-4d65-b1e9-83d9b0413d1d	fd039e52-629b-489a-b445-3003be85cb8d	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
90f221b6-d31c-468e-89b1-b8c49b934c00	886d75e0-e090-4177-a6d8-570db8b1208c	non_vegetarian	t	f		
5533cb15-7dbb-45d0-a5a0-2c4a36c2cd51	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
39f38ca6-de26-42e9-b18f-b360f919d848	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	non_vegetarian	f	f	traveling	Urdu
d9b3fd54-91ba-4dd6-a659-ca541fb0cd6b	3033d43d-8034-498f-b48d-5c549e8f97fb	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
ab935278-ae5a-4215-bb6e-18e344f27970	5fd98325-1ea1-44ab-904c-b7d9c64df81a	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
139f4d16-3ae9-460b-b8fb-5727b3634d93	efe874e3-dc4c-4942-a44b-98f2a856525a	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
6ccdc3bc-d33f-492d-a96a-c3b7d4dccd39	744043a1-ee52-4e5d-a5d7-91221762e13a	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
607d9d55-7749-4be4-b10d-ab86a03d77cd	d1ced440-d263-4434-a49f-2817345f0c27	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
520f48d2-203d-4f34-b5b7-2db03ae8f70a	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
6ced5a62-7b6a-4b39-9d55-2dc32824058f	b521ee31-dd05-4b61-8902-a7d8e3359c87	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
d67faff1-bcaf-4204-bb6f-0e6f34c5109f	1df93849-4a6e-4842-807d-e5df6c457760	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
8161b5fc-2445-4de5-a4c0-0e0692ec7c79	68dc303d-4fe0-423a-a6cb-9383ff75a1da	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
ff8b8f57-6cf7-465b-bd59-9b2e26fde32b	68347b75-b32a-4bb4-9189-76fd0c9d4947	non_vegetarian	f	f	Reading, cricket, travel	Hindi, English, Urdu
\.


--
-- Data for Name: UserLocation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserLocation" ("LocationId", "UserId", "Country", "State", "City", "Address", "Pincode") FROM stdin;
500cc047-e31c-4abe-81ba-bdc1ca9be425	60f50480-cbe7-45b2-b94a-462ddc882514	India	UP	Lucknow	123 Main St	226001
4a33a96f-d034-4e15-bea3-869e498baf34	5b90a2de-8e41-493d-8311-e21b2e27a452	India	UP	Lucknow	123 Main St	226001
e9c110b1-2f48-4d59-99af-474cdb4e8fae	36615d5a-0131-4c21-98e3-956ceca31d48	India	UP	Lucknow	45 Green Park	226016
6facebe9-ea8f-4631-ad9d-e5d61f8916de	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	India	UP	Lucknow	123 Main St	226001
83d0f433-6dfa-427d-ab58-b29efb20a739	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	India	UP	Lucknow	\N	\N
3862beab-e784-46ad-ace1-7e0b9d98a2c3	efcd6ed2-c765-4041-9feb-cd72f820ee45	India	UP	Lucknow	\N	\N
3adc2900-87cc-4536-8568-612f0761aa07	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	India	UP	Lucknow	123 Main St	226001
937412a9-e216-4bcb-bc97-3163f6227152	d45844b4-81d5-448a-9e5b-549832b07407	India	UP	Lucknow	123 Main St	226001
7fe06fc3-cc32-4a2f-844b-e486e40ba697	e576df13-6cd8-44a2-be61-44cb945bc25a	India	UP	Lucknow	\N	\N
ba92e5e2-f901-432d-94e1-5723238a2baf	fbd4b51b-493b-429d-a938-94354ce49c63	India	UP	Lucknow	\N	\N
9160bb97-d384-460f-bd98-16350440b0f4	3d8c7d31-67c4-4023-b401-4ac046cf56ac	India	UP	Lucknow	\N	\N
a03717be-a31a-4808-a5db-4a7bbcd9c31e	fd039e52-629b-489a-b445-3003be85cb8d	India	UP	Lucknow	123 Main St	226001
76897e03-56de-4526-aa9a-147c5d4af135	886d75e0-e090-4177-a6d8-570db8b1208c	India	Uttar Pradesh	Lucknow	209 Sitey Vihar Dubagga	226003
7f871c0a-e86d-4d59-a8ed-eccced634519	f1d17cc9-15ee-4758-846e-e01e49b8779a	India	UP	Lucknow	\N	\N
c23da38f-6a9b-4d6e-84fe-6742e9d51889	e2fd25fb-510b-4af5-a453-84ab5a69cf21	India	UP	Lucknow	\N	\N
0137d396-c0e4-462a-bbb3-acbd2f9452b7	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	India	UP	Lucknow	\N	\N
87d40278-da23-477d-a046-0c935912816a	8b6fae7c-974a-4d6e-9221-f37cf6a97469	India	UP	Lucknow	\N	\N
ab2d7d38-cd8b-4313-b0fe-24f708758105	f5a61371-a191-4bfe-9659-1a05b788696b	India	UP	Lucknow	\N	\N
e25318fb-0204-44d5-9549-d4048ed670be	3f591c6a-5509-45f9-a2e5-050be735735a	India	UP	Lucknow	\N	\N
5864f078-3f5b-4227-a7c6-0c2fd8bbdbf7	15628c01-d0a0-422c-95b2-dcc978ad6fa1	India	UP	Lucknow	\N	\N
4859834a-bf2f-4dc5-b0f3-706bf4b49bc8	6c982b06-1aca-4977-b319-191e16fc4de6	India	UP	Lucknow	\N	\N
4e6090a4-b186-4776-bcf8-cc3ad7066cfe	d4e10fc0-e272-4867-81cd-567a0e84cfdf	India	UP	Lucknow	\N	\N
f01d1549-670e-42b4-8dac-c62bd9878779	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	India	UP	Lucknow	123 Main St	226001
79cc9168-7182-4fbf-9a32-adc7d3adf583	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	India	Uttar Pradesh	LUCKNOW	444/812 Bajrangi lal inter college vali gali	226003
613e6aa4-3654-4117-ab90-81b6a038711b	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	India	UP	Lucknow	\N	\N
59eedbaa-fede-483c-becf-0dafc1255684	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	India	UP	Lucknow	\N	\N
c6aafabd-9c43-4e5a-9544-6f73ecdb540a	679a9cbd-c4bc-4326-a754-e6d09a55b010	India	UP	Lucknow	\N	\N
8cfd02cb-f4d4-443a-b2c9-ff21380869b0	3033d43d-8034-498f-b48d-5c549e8f97fb	India	UP	Lucknow	123 Main St	226001
89e5aadd-5b6a-4036-8246-6565a0feba57	eebc8df0-9557-4dbe-9644-ebe4a13b931c	India	UP	Lucknow	\N	\N
e9e2bc6a-8f61-4e6d-a401-2c7fa4892281	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	India	UP	Lucknow	\N	\N
c59b0ad1-b042-4901-92d8-bf09eb5356ce	6df70e40-bb74-457a-a687-5e470514447b	India	UP	Lucknow	\N	\N
5dac6190-b5ed-452f-83b7-109a8415be31	5fd98325-1ea1-44ab-904c-b7d9c64df81a	India	UP	Lucknow	123 Main St	226001
c967acad-2f8e-42f0-a50e-5f134b4d44c8	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	India	UP	Lucknow	\N	\N
df55247d-7f00-4301-97d9-bf1292e8187a	287fea1f-a616-4b7f-82f8-fc0886dceda0	India	UP	Lucknow	\N	\N
7cd73b17-7763-43b9-a68c-44f4154f0ea9	d7c3fa7c-c268-4e5c-acec-0450571fdb18	India	UP	Lucknow	\N	\N
7ae22b7b-c7f8-4a95-8b32-d370d092b3b2	efe874e3-dc4c-4942-a44b-98f2a856525a	India	UP	Lucknow	123 Main St	226001
59020a5e-1b24-4ac9-9293-dabb72f6bb10	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	India	UP	Lucknow	\N	\N
d60263d1-2913-415f-a3e4-438262b21bab	150f70a6-62b8-44b8-95bb-3e78bbd916be	India	UP	Lucknow	\N	\N
a4b1ddf5-820b-40c1-b277-11649d8e2431	7607d532-01cb-4685-93d0-019c266c06ca	India	UP	Lucknow	\N	\N
51039df2-f6ee-4200-b2aa-997c44ea7c71	744043a1-ee52-4e5d-a5d7-91221762e13a	India	UP	Lucknow	123 Main St	226001
456aecd4-39e0-4f0e-a1e3-7118824122be	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	India	UP	Lucknow	\N	\N
287d6d41-0ddc-402d-a529-41052617c701	86061e0a-d9e9-4fd4-91cc-f4113ffece92	India	UP	Lucknow	\N	\N
0462cbc0-1182-42df-a6dd-6deb641485c9	cf8b1225-10c8-42b4-81a9-6dc603b4b753	India	UP	Lucknow	\N	\N
be6a9769-f17d-4984-860c-3f4c93c640da	d1ced440-d263-4434-a49f-2817345f0c27	India	UP	Lucknow	123 Main St	226001
53895103-8e76-4acf-bd7a-2ecce08792ad	c7329ca3-ba0b-44cb-a3b5-35291cad9718	India	UP	Lucknow	\N	\N
4e3a0f6f-021e-4f3f-ba23-de53c4c83d20	5380e05f-af41-420b-a86b-6661ba12fa65	India	UP	Lucknow	\N	\N
90051759-97b6-4448-a979-c5cb80a6ce8d	80208c67-25c3-4c79-8fd5-90b2d0440bba	India	UP	Lucknow	\N	\N
b33eb96c-c810-49d1-99cd-0b98f6d1c419	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	India	UP	Lucknow	\N	\N
efe774d9-7425-48a2-b9da-2471f98cd61c	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	India	UP	Lucknow	\N	\N
e43dea81-a5b5-424a-b22c-85175a032d11	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	India	UP	Lucknow	123 Main St	226001
eeb5edc9-fdd0-4651-8391-d52dc8766641	519b53fe-56c8-48ce-bd17-3e3bef8aef71	India	UP	Lucknow	\N	\N
85d6cefc-ed4f-4669-a63d-82f7808aba75	afa30051-73b4-41e7-8b44-fe64122d74c6	India	UP	Lucknow	\N	\N
87983335-55d4-483a-bb34-bafd94342595	a7d3612d-d0e9-4807-bdef-60f52458154c	India	UP	Lucknow	\N	\N
7bad4564-13bc-4628-a812-8c9c9925cea4	8dce8e30-e3b1-4588-816e-60891d8a3202	India	UP	Lucknow	\N	\N
f83bd48c-2936-4121-860f-d316501121f4	355ba637-df1c-4775-8a5b-96c70b9a957a	India	UP	Lucknow	\N	\N
37cbb582-a69e-43c3-9692-2eb782fe661c	eaf120d8-bd47-43fc-aa4b-975400c5f579	India	UP	Lucknow	\N	\N
6a0f0c0f-cba3-41be-8845-53b78b8d5526	367fdce2-dc07-4945-af3f-22a1305b03e0	India	UP	Lucknow	\N	\N
def809c0-d84e-43bc-bcc4-ac46853a02de	b521ee31-dd05-4b61-8902-a7d8e3359c87	India	UP	Lucknow	123 Main St	226001
a4e5a359-4de6-4221-adde-6872248c1dc9	88e672cf-f466-4a22-b7c7-fabe8b127ee3	India	UP	Lucknow	\N	\N
1fc6ee29-7d12-41f4-b3c9-0c4c5ca43788	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	India	UP	Lucknow	\N	\N
24306f79-7e1b-4533-bd66-e84ec6e70719	1df93849-4a6e-4842-807d-e5df6c457760	India	UP	Lucknow	123 Main St	226001
5cb12b51-1bb3-4f6a-9e24-432c0c22bc80	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	India	UP	Lucknow	\N	\N
e2c2418a-903a-412b-9260-0072231ee1e7	6e792cb8-9a1f-4c40-a825-985a1dd5b706	India	UP	Lucknow	\N	\N
d18ddf1c-e3b4-4819-ab9e-8a5341623365	89f81735-a971-4f31-be35-afce72c93bfc	India	UP	Lucknow	\N	\N
b019facd-bb77-4efd-8f1a-192b6dac3271	cf11c185-cff1-4c4c-a254-63c9cae16950	India	UP	Lucknow	\N	\N
1b521d6e-8c64-441a-89c0-991d4eafed34	68dc303d-4fe0-423a-a6cb-9383ff75a1da	India	UP	Lucknow	123 Main St	226001
97ec3f15-40f8-4534-9fd7-dff2c5552704	9a619129-5447-45a7-b1a9-45ca14708e7b	India	UP	Lucknow	\N	\N
c58947dc-7b85-4fb8-9b54-76fce17b6240	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	India	UP	Lucknow	\N	\N
c8b3c57b-49b9-4208-9bce-b66489dfd6bc	7c916865-cac4-42be-a99b-c45e15e6845e	India	UP	Lucknow	\N	\N
301e043a-e894-4723-a35a-652fbba8a19e	68347b75-b32a-4bb4-9189-76fd0c9d4947	India	UP	Lucknow	123 Main St	226001
\.


--
-- Data for Name: UserOccupation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserOccupation" ("OccupationId", "UserId", "Occupation", "CompanyName", "Designation", "AnnualIncome", "WorkLocation") FROM stdin;
e6f77f22-90d2-411f-a462-9a1cfee27558	60f50480-cbe7-45b2-b94a-462ddc882514	Engineer	TechCorp	SDE	1200000.00	Lucknow
5dae2684-6479-48bb-956b-5c9288b2b46d	5b90a2de-8e41-493d-8311-e21b2e27a452	Engineer	TechCorp	SDE	1200000.00	Lucknow
201af8fc-2f6b-4d4e-9599-f0cbbbf7fc8c	36615d5a-0131-4c21-98e3-956ceca31d48	Teacher	Sunrise School	Lecturer	600000.00	Lucknow
4d69b0ae-0cab-4b1a-bca4-2ddb421c2e05	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	Engineer	TechCorp	SDE	1200000.00	Lucknow
19497a8d-a6e1-4f10-8b82-1d762be1cd8c	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	Analyst	Firm	\N	\N	\N
9a9cb646-7492-4232-8192-0b0f9aba0a52	efcd6ed2-c765-4041-9feb-cd72f820ee45	Analyst	Firm	\N	\N	\N
aff8dfef-21c5-4624-b1ae-5fa66d32fe07	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	Engineer	TechCorp	SDE	1200000.00	Lucknow
794b4940-50a3-4720-be0c-f77410d92fae	d45844b4-81d5-448a-9e5b-549832b07407	Engineer	TechCorp	SDE	1200000.00	Lucknow
d662b010-c1ce-4a37-85fb-b26781fb13a9	e576df13-6cd8-44a2-be61-44cb945bc25a	Analyst	Firm	\N	\N	\N
32eed137-b539-4dfb-ad72-fa4775aeac38	59296eac-cc9d-44d1-913d-a5ef3365343c	Analyst	Firm	\N	\N	\N
276e4e88-40ce-44b5-b5cb-adf2dd0dccba	fbd4b51b-493b-429d-a938-94354ce49c63	Analyst	Firm	\N	\N	\N
9883d96b-2839-4baa-9cc5-186ffa4693e4	3d8c7d31-67c4-4023-b401-4ac046cf56ac	Analyst	Firm	\N	\N	\N
84562661-c0e3-4441-b420-be7a0431bf87	fd039e52-629b-489a-b445-3003be85cb8d	Engineer	TechCorp	SDE	1200000.00	Lucknow
c6022879-cc39-4d8b-b964-183f433db5c7	886d75e0-e090-4177-a6d8-570db8b1208c	Software Engineer	Infosys		19.00	
ab260827-b3ba-4604-be37-54c27fd4a36b	d4e10fc0-e272-4867-81cd-567a0e84cfdf	Analyst	Firm	\N	\N	\N
912d6b6a-7305-4e00-878b-1a6ae8aaa085	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	Engineer	TechCorp	SDE	1200000.00	Lucknow
52baced2-c037-4e9b-8d6b-17c6e28d3ab8	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	Software Engineer		Tech lead	1200000.00	
55b0ca5f-296f-4dc9-abb9-5528a428abc1	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	Analyst	Firm	\N	\N	\N
9379d1be-0a55-4f80-a9e2-7890b8727ad2	3033d43d-8034-498f-b48d-5c549e8f97fb	Engineer	TechCorp	SDE	1200000.00	Lucknow
98a78b2c-9db0-44b2-9c49-4944c831f55a	eebc8df0-9557-4dbe-9644-ebe4a13b931c	Analyst	Firm	\N	\N	\N
dd3130e5-6919-42ae-ab32-1bac1785236e	5fd98325-1ea1-44ab-904c-b7d9c64df81a	Engineer	TechCorp	SDE	1200000.00	Lucknow
c26c3b19-2f15-48d9-a19b-8013f023a882	d7c3fa7c-c268-4e5c-acec-0450571fdb18	Analyst	Firm	\N	\N	\N
53995ec5-bfa2-4880-ad8e-b8acb17d301e	efe874e3-dc4c-4942-a44b-98f2a856525a	Engineer	TechCorp	SDE	1200000.00	Lucknow
e62c7928-1b3b-4834-a848-aa6ffa4bb94c	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	Analyst	Firm	\N	\N	\N
f5644c51-d690-42dc-9ffd-f25bd5d939a4	744043a1-ee52-4e5d-a5d7-91221762e13a	Engineer	TechCorp	SDE	1200000.00	Lucknow
0c598671-b2c0-4274-b659-954de2c06637	cf8b1225-10c8-42b4-81a9-6dc603b4b753	Analyst	Firm	\N	\N	\N
c9734e9a-a5fa-4a76-aa57-d7dbbd7a6223	d1ced440-d263-4434-a49f-2817345f0c27	Engineer	TechCorp	SDE	1200000.00	Lucknow
90377f5c-034a-4ddd-9bdb-bbd7a13e2d94	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	Analyst	Firm	\N	\N	\N
0838e22d-34f0-4a41-80da-60716bf7dd3c	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	Engineer	TechCorp	SDE	1200000.00	Lucknow
d4db721e-7741-4c40-8560-e6b8f122e126	367fdce2-dc07-4945-af3f-22a1305b03e0	Analyst	Firm	\N	\N	\N
96320a3a-49ce-4438-8fca-1c5c1add0e60	b521ee31-dd05-4b61-8902-a7d8e3359c87	Engineer	TechCorp	SDE	1200000.00	Lucknow
a04dddc0-f5d6-4c7d-8d35-c8084d414e50	1df93849-4a6e-4842-807d-e5df6c457760	Engineer	TechCorp	SDE	1200000.00	Lucknow
34663d37-89f5-4486-a2ca-46a4741cbd5a	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	Analyst	Firm	\N	\N	\N
a91c714a-d907-40bc-872a-d2e2acfd8760	cf11c185-cff1-4c4c-a254-63c9cae16950	Analyst	Firm	\N	\N	\N
cb7034f1-e266-43be-bf25-5e6db1b9ae6a	68dc303d-4fe0-423a-a6cb-9383ff75a1da	Engineer	TechCorp	SDE	1200000.00	Lucknow
ebadbf01-8cda-43d9-a000-e64cf378d18a	9a619129-5447-45a7-b1a9-45ca14708e7b	Analyst	Firm	\N	\N	\N
1009f035-d05a-4c1d-8ba5-0da6ec1645bc	68347b75-b32a-4bb4-9189-76fd0c9d4947	Engineer	TechCorp	SDE	1200000.00	Lucknow
\.


--
-- Data for Name: UserPhotos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserPhotos" ("PhotoId", "UserId", "PhotoUrl", "IsPrimary", "DisplayOrder", "IsApproved", "UploadedOn") FROM stdin;
d459e6e2-2f26-440f-9382-fe2803130ea9	bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	http://178.212.35.171:3001/uploads/25fffa29-6b8d-41d3-ad45-43ccc9ceb4df.png	t	0	f	2026-08-05 11:13:06.404757+00
c6df7c12-2bed-4253-af85-3cac65f497f7	bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	http://178.212.35.171:3001/uploads/c1c1f496-ea8c-429a-bdf0-013adc72c887.png	f	1	f	2026-08-05 11:13:06.765113+00
b086af41-7adf-4a48-97c2-a7798c9eec7e	624934b7-aa0d-4f5f-9273-5698f83ac494	http://178.212.35.171:3001/uploads/10b79177-46a5-4ba4-9489-9511a49077c9.png	t	0	f	2026-08-05 11:13:20.034784+00
65b18a5f-66f9-430a-8a15-e06ed4945061	624934b7-aa0d-4f5f-9273-5698f83ac494	http://178.212.35.171:3001/uploads/c5f3c88c-0223-48ee-91bb-ed8610cc7dfa.png	f	1	f	2026-08-05 11:13:20.168215+00
bbd933ec-6935-4bfb-97ec-8d130a89f320	2b1e1113-1628-49d1-be26-eff461ad7395	http://178.212.35.171:3001/uploads/f8a32246-17be-4b56-96c6-e1c1696bc274.png	t	0	f	2026-08-05 11:13:28.242461+00
82efe743-a0bc-4038-94b2-5989a226635e	36abc252-b881-46f8-add5-7549fcf1c02c	http://178.212.35.171:3001/uploads/169050aa-3c47-4778-9231-ff813bc985a7.png	t	0	f	2026-08-05 11:29:29.587222+00
ca213464-165d-4f4c-9f03-7bb2141ed859	36abc252-b881-46f8-add5-7549fcf1c02c	http://178.212.35.171:3001/uploads/6b58bdbb-3ce5-487c-8b35-012d659eae1f.png	f	1	f	2026-08-05 11:29:29.754254+00
989c680e-495f-433f-b9c4-ea9bf4ca49e3	571b5cef-8904-4a2b-bbeb-aae3a5dab145	http://178.212.35.171:3001/uploads/27e02587-6386-4d0a-974b-dd2dceb731f6.png	t	0	f	2026-08-05 13:05:10.756027+00
727db0e2-51e2-43d5-8333-87058ebf1ba4	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	http://178.212.35.171:3001/uploads/a313c5d4-982b-4f0f-9b14-faad3c5503db.jpeg	t	0	f	2026-08-05 13:09:15.12184+00
315fddad-fbf4-45e8-9c60-a7a01ebf7f2b	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	http://178.212.35.171:3001/uploads/4e629cda-9b64-4f3e-ad3a-312a3286866c.jpeg	f	1	f	2026-08-05 13:10:08.496755+00
6b8febce-13df-4ca7-9b9f-f1c2ed5563f3	886d75e0-e090-4177-a6d8-570db8b1208c	http://178.212.35.171:3001/uploads/34085c6d-01e8-49d7-bb26-e926fd280da4.jpg	t	0	f	2026-08-05 17:45:55.755225+00
ec208c36-a540-47f0-9e68-87e3016a115a	886d75e0-e090-4177-a6d8-570db8b1208c	http://178.212.35.171:3001/uploads/c54fcdec-b69a-45af-a647-cc55ac29b1ab.jpg	f	1	f	2026-08-05 17:46:55.469084+00
\.


--
-- Data for Name: UserPreferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserPreferences" ("PreferenceId", "UserId", "MinAge", "MaxAge", "MinHeight", "MaxHeight", "Religion", "Caste", "Education", "Occupation", "Country", "State", "City") FROM stdin;
51666beb-062f-4700-b787-f0a11073e34d	60f50480-cbe7-45b2-b94a-462ddc882514	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
a01ce5b7-8a24-4c8d-ae06-c6b5f93f737d	5b90a2de-8e41-493d-8311-e21b2e27a452	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
db17d8b9-99d6-42e6-88ef-5010896d16b2	36615d5a-0131-4c21-98e3-956ceca31d48	25	32	5.50	6.20	["Muslim"]	["Sunni", "Shia"]	[]	[]	India	UP	Lucknow
fe7550c2-8f33-4309-a851-45b25a100434	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
0f71c655-232e-420a-aca2-63535e1c716f	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
64ffa281-0695-4122-b3be-cf23c8c5eace	efcd6ed2-c765-4041-9feb-cd72f820ee45	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
b7ea1373-5644-4769-a88e-5c40e3b229a8	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
b9c40330-0bf2-4dcf-94d7-e385012ccb6f	d45844b4-81d5-448a-9e5b-549832b07407	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
18b9187b-f1ac-43cb-9551-6ec0c7745325	e576df13-6cd8-44a2-be61-44cb945bc25a	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
02d5fb1a-0dc0-406b-8491-b11f23598f54	fbd4b51b-493b-429d-a938-94354ce49c63	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
0718a0a1-a877-40e7-9d55-651e4dc0367d	3d8c7d31-67c4-4023-b401-4ac046cf56ac	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
efd1fbe6-ac31-4e3b-9864-006ecb428568	fd039e52-629b-489a-b445-3003be85cb8d	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
671d8fce-d865-4dff-923a-e2378e47ae69	886d75e0-e090-4177-a6d8-570db8b1208c	20	34	160.00	170.00	["Islam"]	["Ansari"]	[]	[]			
5da51045-900c-4dbb-b324-9862722615bd	f1d17cc9-15ee-4758-846e-e01e49b8779a	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
77bcfd22-a14a-44e6-ad40-a3d07858a153	e2fd25fb-510b-4af5-a453-84ab5a69cf21	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
25a287f8-d9e0-49ca-9ea0-687909c013f5	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
b3b36e65-eecc-4c4c-b5f1-4821fe467ac5	8b6fae7c-974a-4d6e-9221-f37cf6a97469	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
592a4de2-e263-4efa-a2e5-f2100b8c86f0	f5a61371-a191-4bfe-9659-1a05b788696b	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
54846ec9-a215-4f94-8488-2e7944f99f0e	3f591c6a-5509-45f9-a2e5-050be735735a	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
0a41a22c-5e48-4cea-b448-ffd0a191f508	15628c01-d0a0-422c-95b2-dcc978ad6fa1	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
d1ae0024-ed56-44f3-8445-a2e00975a9e5	6c982b06-1aca-4977-b319-191e16fc4de6	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
22553a31-e2b0-410d-938d-b717eacb99dd	d4e10fc0-e272-4867-81cd-567a0e84cfdf	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
b364e259-d3ac-4bd0-9520-3ffd28da2892	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
402dd89b-4d2d-4adf-b6a8-f3733e4bdecd	9a619129-5447-45a7-b1a9-45ca14708e7b	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
e9ff8186-ee9b-4847-952d-fd658f982ec6	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	20	35	155.00	166.00	["islam"]	["beg"]	["8"]	["home maker"]	India	Uttar Pradesh	LUCKNOW
70eb0b80-01c7-456a-a7f0-20dfa374364e	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
d60ee832-9779-4d35-b203-3c9590ded1c2	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
c972caa6-4995-4e8c-b868-7b0f363d29f0	679a9cbd-c4bc-4326-a754-e6d09a55b010	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
5d404ebf-93d5-4878-8b0a-3e02ceea6a0e	3033d43d-8034-498f-b48d-5c549e8f97fb	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
7f9465d5-040c-402f-b4e5-05088844d139	eebc8df0-9557-4dbe-9644-ebe4a13b931c	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
16cd0cb7-4edc-481f-b67e-ac39c3e81571	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
be0975dd-accd-4995-a17a-0b066a4bb309	6df70e40-bb74-457a-a687-5e470514447b	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
121c927e-5a06-4043-9f7c-e706a7d0f429	5fd98325-1ea1-44ab-904c-b7d9c64df81a	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
44dddb58-dcb8-4162-926a-04e22bee484c	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
5eaef927-bdf8-43a4-a240-50d422357ea2	287fea1f-a616-4b7f-82f8-fc0886dceda0	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
5ba5d1fd-6fa0-4ea2-a57f-472d0d9964f5	d7c3fa7c-c268-4e5c-acec-0450571fdb18	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
58ae45ba-1cc2-461c-9d0e-175c8657855a	efe874e3-dc4c-4942-a44b-98f2a856525a	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
10b8a5ab-5e1a-4297-a00c-3aa9cce5189c	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
2a43a312-b7fd-4ed1-ae68-4feea5ab0c56	150f70a6-62b8-44b8-95bb-3e78bbd916be	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
9d60c09a-de1a-40ed-a46c-06fa1879a652	7607d532-01cb-4685-93d0-019c266c06ca	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
454d7ff6-6667-4e88-b772-67c372f19af7	744043a1-ee52-4e5d-a5d7-91221762e13a	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
265d7322-3522-4493-bb31-1e6380395da3	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
f7924c0b-0036-4056-b51e-2d803e3eeee6	86061e0a-d9e9-4fd4-91cc-f4113ffece92	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
5b9e6cf8-c5a1-45f6-9d33-c508588d7ac5	cf8b1225-10c8-42b4-81a9-6dc603b4b753	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
71a383a1-492e-4fe9-bde2-bafc07082316	d1ced440-d263-4434-a49f-2817345f0c27	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
edfe6142-712a-48b2-96df-0d86b227cddc	c7329ca3-ba0b-44cb-a3b5-35291cad9718	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
58800e90-516f-4a13-9744-d41bf83af5fc	5380e05f-af41-420b-a86b-6661ba12fa65	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
e6dd8c2f-87b2-4e02-ad5f-1b3736362d31	80208c67-25c3-4c79-8fd5-90b2d0440bba	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
c685b672-1213-44bc-965b-1cf38a5f07a2	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
4b28acfd-7b3c-4cbd-ac1f-ad888299c030	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
2b0fb0a3-c6a8-41ff-bacf-2b07d8f6f555	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
ede0364a-3ce4-4510-b87e-24efdc49531f	519b53fe-56c8-48ce-bd17-3e3bef8aef71	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
c88b97c9-3960-4241-95f4-ecb6e138a266	afa30051-73b4-41e7-8b44-fe64122d74c6	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
2524f224-696b-4964-8de8-75e4b1964ae3	a7d3612d-d0e9-4807-bdef-60f52458154c	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
f0e5b3d0-b9b2-49cf-ab91-174451f74ac7	8dce8e30-e3b1-4588-816e-60891d8a3202	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
4c4a8974-01db-4ab1-9751-78b822dcc17b	355ba637-df1c-4775-8a5b-96c70b9a957a	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
633247a8-5eca-406a-b789-38fb83e9d6d1	eaf120d8-bd47-43fc-aa4b-975400c5f579	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
eb35fa63-a274-4fd4-9ac9-a0dd9a3470d2	367fdce2-dc07-4945-af3f-22a1305b03e0	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
72d95862-f337-43f9-b292-efad7d958514	b521ee31-dd05-4b61-8902-a7d8e3359c87	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
af343484-3511-4b17-8536-11c6e5168976	88e672cf-f466-4a22-b7c7-fabe8b127ee3	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
a49af36d-ab1f-4264-935f-b4422c09a192	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
09e3e4f6-e473-482d-83ba-e1a9dce32ad5	1df93849-4a6e-4842-807d-e5df6c457760	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
960ef38c-f4b7-4dcc-af01-9f94afabaa2a	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
14ba8b09-4f32-4cd1-a46e-7189431646e4	6e792cb8-9a1f-4c40-a825-985a1dd5b706	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
bdae363a-d422-4eba-acec-d270656e6baa	89f81735-a971-4f31-be35-afce72c93bfc	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
b5980605-940e-4671-bd10-bb5745ed55e5	cf11c185-cff1-4c4c-a254-63c9cae16950	24	32	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
269c26af-7f4f-4e48-9d17-e82873b0212d	68dc303d-4fe0-423a-a6cb-9383ff75a1da	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
38fbe5ac-18a2-442e-bf18-92db24e94f1d	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	25	33	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	\N
b77d662d-bd7d-47b4-a0f6-8f237b1713ee	7c916865-cac4-42be-a99b-c45e15e6845e	23	30	\N	\N	["Muslim"]	\N	\N	\N	\N	\N	Lucknow
10bd5c02-9a67-471b-87b4-3ee03c933dc7	68347b75-b32a-4bb4-9189-76fd0c9d4947	22	28	5.20	6.10	["Muslim"]	["Sunni"]	\N	\N	India	UP	Lucknow
\.


--
-- Data for Name: UserProfiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserProfiles" ("ProfileId", "UserId", "Gender", "DateOfBirth", "Height", "Weight", "MaritalStatus", "Religion", "Caste", "SubCaste", "MotherTongue", "BloodGroup", "AboutMe", "ProfileCompletionPercent", "Visibility", "VerificationStatus", "CreatedOn", "UpdatedOn", "Sect", "IsBlueTickVerified", "PhotosBlurredByDefault") FROM stdin;
72e7b5a3-4b77-44e5-b97c-a19e5b9bca05	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-05 15:23:56.651855+00	2026-08-05 15:23:56.984078+00	\N	f	f
4623b0b2-cf09-449d-99c4-b3e931f74635	60f50480-cbe7-45b2-b94a-462ddc882514	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 10:26:46.872756+00	2026-08-05 10:26:48.224627+00	Hanafi	f	f
78496c3f-6e1a-42a8-ba91-104d34325931	efcd6ed2-c765-4041-9feb-cd72f820ee45	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-05 15:24:12.019179+00	2026-08-05 15:24:12.352759+00	\N	f	f
b2dad6fb-650b-4c85-b623-a11e5b3b8aff	5b90a2de-8e41-493d-8311-e21b2e27a452	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 10:26:56.209756+00	2026-08-05 10:26:57.329439+00	Hanafi	f	f
35ec34ba-4292-48a4-ad62-0cc406394e36	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 02:30:37.182759+00	2026-08-06 02:30:38.109907+00	Hanafi	f	f
17a16df7-f68d-4ec2-b862-e66d5034b297	efe874e3-dc4c-4942-a44b-98f2a856525a	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 06:33:59.548747+00	2026-08-06 06:34:00.491858+00	Hanafi	f	f
6d982fed-bbbc-46da-b046-17a807339781	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 15:24:19.398219+00	2026-08-05 15:24:22.035053+00	Hanafi	f	f
ee9177fd-c37f-4124-884b-798e6babb90d	886d75e0-e090-4177-a6d8-570db8b1208c	male	1989-02-03	172.00	80.00	never_married	Islam	Ansari		Urdu	B+		90	public	unverified	2026-08-05 17:41:48.781296+00	2026-08-05 17:44:54.895055+00	Sunni	f	f
c05c6a0c-0abe-4f14-aaa5-622b44e4e7ec	d45844b4-81d5-448a-9e5b-549832b07407	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 15:24:32.688963+00	2026-08-05 15:24:34.34741+00	Hanafi	f	f
6d473f77-0453-4746-bcca-2bba12b98450	e576df13-6cd8-44a2-be61-44cb945bc25a	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-05 15:24:36.013363+00	2026-08-05 15:24:36.358009+00	\N	f	f
7633670a-f4aa-4f5c-8ca2-a38c34519188	59296eac-cc9d-44d1-913d-a5ef3365343c	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	0	public	unverified	2026-08-05 15:31:39.921867+00	2026-08-05 15:31:39.921867+00	\N	f	f
170d8662-fa55-48db-98d2-53ed1bb3ee5f	fbd4b51b-493b-429d-a938-94354ce49c63	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-05 15:32:00.344181+00	2026-08-05 15:32:00.816743+00	\N	f	f
b1fec96e-3f16-4c94-936b-fecb8e9450bb	3d8c7d31-67c4-4023-b401-4ac046cf56ac	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-05 15:32:18.513275+00	2026-08-05 15:32:18.854915+00	\N	f	f
13eb4fed-30a8-4aca-8222-b033d931adf3	36615d5a-0131-4c21-98e3-956ceca31d48	female	1998-03-21	5.30	55.00	never_married	Muslim	Sunni	\N	Urdu	A+	Updated: teacher, love cooking & reading.	100	public	unverified	2026-08-05 10:57:31.160758+00	2026-08-05 11:06:52.621631+00	Hanafi	f	f
b351243f-b5f4-412a-957b-bbb8a7b847bc	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	male	1989-06-29	172.00	65.00	never_married	Islam	beg		urdu	O+	I am good 	100	public	unverified	2026-08-05 13:11:32.028753+00	2026-08-06 06:05:08.744751+00	Sunni	f	f
d3cc2d05-f446-4901-8e4d-b9bf146ecd4c	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 12:53:06.746959+00	2026-08-05 12:53:08.181939+00	Hanafi	f	f
e3d4ba8b-63c6-4684-95e9-81a1343a1d78	fd039e52-629b-489a-b445-3003be85cb8d	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-05 15:32:21.899203+00	2026-08-05 15:32:22.855404+00	Hanafi	f	f
509e640b-b55a-464f-bf04-b5ceb2dbef83	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 06:32:29.27741+00	2026-08-06 06:32:29.646755+00	\N	f	f
8c84e6fc-8561-4dd6-9854-f928c572ebbd	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:32:32.668781+00	2026-08-06 06:32:32.960685+00	\N	f	f
b9cb957a-f52c-4cd0-86cd-d4cbf4b9fd4c	679a9cbd-c4bc-4326-a754-e6d09a55b010	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:32:32.995762+00	2026-08-06 06:32:33.287332+00	\N	f	f
cda2a065-7a5e-41d6-a37d-3a944f328425	f1d17cc9-15ee-4758-846e-e01e49b8779a	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:29:47.42491+00	2026-08-06 02:29:47.722234+00	\N	f	f
18ca0e9c-5539-4920-ae88-b58d3fcb55d3	e2fd25fb-510b-4af5-a453-84ab5a69cf21	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:29:47.766774+00	2026-08-06 02:29:48.026424+00	\N	f	f
77acc801-1a7f-4116-ae6b-a3db46f07a84	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:29:56.395784+00	2026-08-06 02:29:56.651775+00	\N	f	f
cedc7c44-e447-48ca-8fc2-0cbc77cc513b	8b6fae7c-974a-4d6e-9221-f37cf6a97469	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:29:56.689326+00	2026-08-06 02:29:56.935681+00	\N	f	f
4fc9ae8f-3d8b-430c-9a5e-016845fb3b5b	5fd98325-1ea1-44ab-904c-b7d9c64df81a	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 06:33:27.150755+00	2026-08-06 06:33:28.635512+00	Hanafi	f	f
3a115868-68bc-49d5-b6aa-7c4b2b6ff73f	f5a61371-a191-4bfe-9659-1a05b788696b	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:30:17.363017+00	2026-08-06 02:30:17.735842+00	\N	f	f
4da12017-ca17-4934-a487-59a982bf37d8	3f591c6a-5509-45f9-a2e5-050be735735a	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:30:17.774767+00	2026-08-06 02:30:18.07462+00	\N	f	f
1b8a2606-303d-457f-98c7-06ab724a2e12	15628c01-d0a0-422c-95b2-dcc978ad6fa1	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:30:30.490147+00	2026-08-06 02:30:30.785754+00	\N	f	f
90db7e73-4783-4680-b12b-d3e8e99c2690	6c982b06-1aca-4977-b319-191e16fc4de6	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 02:30:30.833623+00	2026-08-06 02:30:31.135411+00	\N	f	f
529599c4-db15-4357-b6d3-2b489ff8e117	d4e10fc0-e272-4867-81cd-567a0e84cfdf	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 02:30:33.913826+00	2026-08-06 02:30:34.313771+00	\N	f	f
bf946e77-88b0-440f-ae11-fbf34cc52406	3033d43d-8034-498f-b48d-5c549e8f97fb	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 06:32:35.606754+00	2026-08-06 06:32:36.612959+00	Hanafi	f	f
8605f199-ec22-4e76-bd5e-7e6a33b03341	eebc8df0-9557-4dbe-9644-ebe4a13b931c	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 06:33:19.055029+00	2026-08-06 06:33:19.454429+00	\N	f	f
1fd69c1f-4d4e-4e53-b400-f9887322ce03	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:33:23.330599+00	2026-08-06 06:33:23.713419+00	\N	f	f
9c5c4610-8b83-42d3-adda-b3a98d1e375b	6df70e40-bb74-457a-a687-5e470514447b	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:33:23.781757+00	2026-08-06 06:33:24.574761+00	\N	f	f
8fbe0eb5-2dd5-4a46-905c-a64161f03a0c	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:33:49.15684+00	2026-08-06 06:33:49.499998+00	\N	f	f
54eb23b3-e85f-4a34-bdf8-ec6bbf2586b1	287fea1f-a616-4b7f-82f8-fc0886dceda0	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 06:33:49.532198+00	2026-08-06 06:33:49.804298+00	\N	f	f
a91d67a3-57c2-4b3a-826e-16deb5eb805e	d7c3fa7c-c268-4e5c-acec-0450571fdb18	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 06:33:56.147614+00	2026-08-06 06:33:56.570872+00	\N	f	f
18da5f30-72f9-4fef-b831-79af018290da	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:24:23.679141+00	2026-08-06 07:24:24.204085+00	\N	f	f
124ca761-2822-4ccc-8a6b-ac20dfa2dc76	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:24:50.58604+00	2026-08-06 07:24:50.913683+00	\N	f	f
0e399917-c702-4c98-b354-b1771358752e	150f70a6-62b8-44b8-95bb-3e78bbd916be	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:24:27.840588+00	2026-08-06 07:24:28.249918+00	\N	f	f
75081f3b-8d9a-4716-b74f-ff428507a8c4	7607d532-01cb-4685-93d0-019c266c06ca	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:24:28.288941+00	2026-08-06 07:24:28.650587+00	\N	f	f
fa088bb1-5fc9-4178-808f-ec6cd5f54ce9	744043a1-ee52-4e5d-a5d7-91221762e13a	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:24:36.134759+00	2026-08-06 07:24:37.168505+00	Hanafi	f	f
3ce60de2-e6c8-48bf-80c0-f8237affa293	86061e0a-d9e9-4fd4-91cc-f4113ffece92	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:24:50.94858+00	2026-08-06 07:24:51.717353+00	\N	f	f
117c714e-5790-4332-89d7-094bcf244dcf	cf8b1225-10c8-42b4-81a9-6dc603b4b753	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:24:57.862471+00	2026-08-06 07:24:58.223084+00	\N	f	f
5070e604-9183-4fef-bf21-559db5a2611c	d1ced440-d263-4434-a49f-2817345f0c27	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:25:06.00776+00	2026-08-06 07:25:06.995247+00	Hanafi	f	f
99a1e5eb-2ced-49ac-aa26-bafbd02957f3	c7329ca3-ba0b-44cb-a3b5-35291cad9718	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:25:20.214075+00	2026-08-06 07:25:20.599081+00	\N	f	f
dfc5abd8-c621-40b1-9e2b-445c18c375c6	5380e05f-af41-420b-a86b-6661ba12fa65	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:25:20.645176+00	2026-08-06 07:25:20.99549+00	\N	f	f
c0187b94-e9b5-4089-ba3d-df31316deef3	80208c67-25c3-4c79-8fd5-90b2d0440bba	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:25:41.370458+00	2026-08-06 07:25:41.751721+00	\N	f	f
d1beda26-a10d-4d54-8d26-a4b8f171a33b	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:25:41.840619+00	2026-08-06 07:25:42.150789+00	\N	f	f
22d19111-af40-4628-95be-5502d648bbbc	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:25:48.258319+00	2026-08-06 07:25:48.665853+00	\N	f	f
ade4582e-3a3d-49c0-91e6-73a0aa6a7563	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:40:46.264041+00	2026-08-06 07:40:46.558757+00	\N	f	f
2af03579-426c-4ea2-ba5a-32cab416fc11	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:25:54.90977+00	2026-08-06 07:25:56.052748+00	Hanafi	f	f
eb78856c-333d-47eb-af21-ab4416784f52	519b53fe-56c8-48ce-bd17-3e3bef8aef71	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:26:08.033887+00	2026-08-06 07:26:08.376795+00	\N	f	f
5393fac6-5481-4a22-b066-8e054e8c7920	afa30051-73b4-41e7-8b44-fe64122d74c6	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:26:08.41547+00	2026-08-06 07:26:08.763169+00	\N	f	f
907c2045-cd9d-4f0c-b011-04c30ab95700	a7d3612d-d0e9-4807-bdef-60f52458154c	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:26:50.839505+00	2026-08-06 07:26:51.239816+00	\N	f	f
d85a30e8-8c2e-4c3a-b00c-f6b7cb3a886f	8dce8e30-e3b1-4588-816e-60891d8a3202	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:26:51.287954+00	2026-08-06 07:26:51.613525+00	\N	f	f
2e6b608c-3210-4268-b555-806baed15363	355ba637-df1c-4775-8a5b-96c70b9a957a	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:27:03.703375+00	2026-08-06 07:27:04.096351+00	\N	f	f
1798d852-fb52-43c6-93b8-22720ba67ff3	eaf120d8-bd47-43fc-aa4b-975400c5f579	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:27:04.14762+00	2026-08-06 07:27:04.447761+00	\N	f	f
b060264f-7a41-4c21-acce-527a65eaed37	367fdce2-dc07-4945-af3f-22a1305b03e0	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:27:07.213321+00	2026-08-06 07:27:07.54838+00	\N	f	f
49a48df0-b267-4298-9f5c-ebc410bb5e20	7c916865-cac4-42be-a99b-c45e15e6845e	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:40:46.594647+00	2026-08-06 07:40:46.937048+00	\N	f	f
0865dd4b-8141-4880-bc18-04be5db77572	b521ee31-dd05-4b61-8902-a7d8e3359c87	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:27:17.332063+00	2026-08-06 07:27:19.352215+00	Hanafi	f	f
517c5465-56a6-4712-8d02-5f5d5a9651a6	88e672cf-f466-4a22-b7c7-fabe8b127ee3	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:39:24.927773+00	2026-08-06 07:39:25.478724+00	\N	f	f
b032fa7c-de04-4b06-a2b3-a0bc47caee9c	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:39:25.51862+00	2026-08-06 07:39:25.863639+00	\N	f	f
e29a476a-b9a4-474a-90cb-9d6a8058fa4f	1df93849-4a6e-4842-807d-e5df6c457760	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:39:28.533758+00	2026-08-06 07:39:29.775774+00	Hanafi	f	f
db7189a6-d0d4-437e-9042-5d41573b0a70	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:39:32.327282+00	2026-08-06 07:39:32.719983+00	\N	f	f
1d43bfa3-500a-490c-aec3-68923b98e03f	6e792cb8-9a1f-4c40-a825-985a1dd5b706	female	1996-04-10	5.40	52.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:40:00.787535+00	2026-08-06 07:40:01.187585+00	\N	f	f
bb7af655-ada8-42cd-bd9b-a7c5eb5324b8	89f81735-a971-4f31-be35-afce72c93bfc	male	1992-08-20	5.90	75.00	never_married	Muslim	Sunni	\N	Urdu	\N	\N	70	public	unverified	2026-08-06 07:40:01.259772+00	2026-08-06 07:40:01.66534+00	\N	f	f
1c3e3a95-c1a9-4272-979b-3b4b650934a8	cf11c185-cff1-4c4c-a254-63c9cae16950	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:40:05.076914+00	2026-08-06 07:40:05.406761+00	\N	f	f
a9fd481e-a2a1-4cbd-b0dc-95224dfd61da	68347b75-b32a-4bb4-9189-76fd0c9d4947	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:40:56.134083+00	2026-08-06 07:40:57.195454+00	Hanafi	f	f
1b26a938-27dd-4852-99a3-e3f9682ebe69	68dc303d-4fe0-423a-a6cb-9383ff75a1da	male	1995-06-15	5.90	72.00	never_married	Muslim	Sunni	\N	Urdu	B+	Updated about me text.	100	public	unverified	2026-08-06 07:40:16.137756+00	2026-08-06 07:40:17.28324+00	Hanafi	f	f
df39d252-9da7-4c7b-ac9b-362aa44d4975	9a619129-5447-45a7-b1a9-45ca14708e7b	female	1997-01-15	5.40	55.00	never_married	Muslim	Sunni	\N	Urdu	\N	Hello	100	public	unverified	2026-08-06 07:40:41.568838+00	2026-08-06 07:40:42.196753+00	\N	f	f
\.


--
-- Data for Name: UserSessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserSessions" ("SessionId", "UserId", "RefreshToken", "DeviceName", "Browser", "IPAddress", "LoginTime", "LogoutTime") FROM stdin;
55e031b0-81e3-4a34-b522-ff58e52d489d	8f3769a0-51a7-4bb1-93b0-836742c705b2	43d74e220cf4a8e09a7ff5b21190e6569b43b19aa12599892889d791f41f1a14	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 04:02:50.767429+00	\N
0be55d6c-854a-4335-9ab6-d0461b068a6c	8f3769a0-51a7-4bb1-93b0-836742c705b2	e4325b5cd94f57ba4f16a6a5f07884d4fe4c2fe29418bf849695197101308340	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 07:01:23.029383+00	\N
a5138ed2-f101-4e26-8cfd-7ad471a2bb24	6b185805-10cb-4f1a-9e15-3168dc691745	76c40e68f8e2256c1bbbbb30398d8865e3c50f661fdcb1a390a8330728f1e7a9	\N		::ffff:127.0.0.1	2026-08-05 09:45:17.90952+00	\N
02a22da1-e0c0-4802-80fc-d2b46f74bb4a	b78a2599-3f86-49da-9570-4d094ab240e7	dd42bad08622a1d9a5d951eac7f9742cf0ddd0c53a777b1e70db0b61671694e7	\N		::ffff:127.0.0.1	2026-08-05 09:45:30.01054+00	\N
10eb80aa-5f7c-4a9d-87a7-496f140c3138	4c4b64db-a7b1-40cf-98cb-357738726bc7	c7b605d40bf2ce60d1f32902b78d50d14a55de477725e58d399f05704b808714	\N		::ffff:127.0.0.1	2026-08-05 09:45:55.649442+00	\N
904979f9-b6a7-449a-9d6d-480e467f9619	6a62dd3b-10b2-44fa-aed4-320d1685025f	124ab3184529cedc6032519bee452787b42fb3a94387c15bc231558c5ceebf0b	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 09:49:06.517686+00	\N
75f8d8e4-3627-4bd1-be3a-de6d26110888	46f8f2e6-f83f-4a03-9c6c-684a91372144	5a2a984c20e9e6fe261363a067c86d532f2f6be37273af045f7957022631aa3d	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 10:14:01.10427+00	\N
484c1472-cf47-4d32-ad0e-e24af84e73f3	6a62dd3b-10b2-44fa-aed4-320d1685025f	ebe3bca3dabc5659d9b72757ad821a2c8c5b6b73b233eb721731eaa14b874bd9	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 10:22:23.882177+00	\N
3e1946f8-bf4c-422f-bfa1-3f51d05f9dc3	60f50480-cbe7-45b2-b94a-462ddc882514	c0aa7af5361caf51a0b47703fafe1f6531e430cf5c0769b2d7bb7e60cf1b1289	\N		::ffff:127.0.0.1	2026-08-05 10:26:46.739727+00	\N
464eba71-4489-4a7d-8907-3e609374899a	5b90a2de-8e41-493d-8311-e21b2e27a452	017f906faf4f2e2445eef9c100526d399e5ebd96cefe923f5b6d816ccc85696d	\N		::ffff:127.0.0.1	2026-08-05 10:26:56.074903+00	\N
8bb9f414-667e-4323-aab6-92b60661a4ef	a36f9544-213a-4594-887d-680b70dd32fb	bdfd93a9687ef182965b512d1ac324ecee184ec993ccf674676151d84afc854e	\N		::ffff:127.0.0.1	2026-08-05 10:27:01.861823+00	\N
66f3a19c-3df9-4861-9f30-653db48a27d9	46f8f2e6-f83f-4a03-9c6c-684a91372144	98b3db9b708175d231dc22d21e02e1e3e704677648e44465809e086a1f599ac9	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 10:55:58.843492+00	\N
ece47ac1-ca04-4d47-89d0-b6a2398d5baa	36615d5a-0131-4c21-98e3-956ceca31d48	d04d1814a45ae155368351c56b9ed03a7dfb4376db00570d76dfaf86a61df8d7	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 10:57:30.808827+00	\N
7a92eb67-fbbf-4f64-8259-68f0bba7155d	b9a9e0e7-72fd-4eef-9c0b-4ee5c0158432	f28ef55c1319affca9d0c4b797b7ed3b176d6508e95d259f5d7f707668f83613	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 10:59:54.317042+00	\N
1bcee3af-ccce-43de-8585-5bc9ce961478	36615d5a-0131-4c21-98e3-956ceca31d48	ab504aa150d81565ff335b83b4fc700bb89c1579f2a1dd489d7d0a4c3009ec57	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrom	::ffff:103.255.105.120	2026-08-05 11:03:18.190595+00	\N
54aa5414-1ba8-4aad-8433-f56c0e9eef39	36615d5a-0131-4c21-98e3-956ceca31d48	84b264c4dcc3c75998f21038a300be9836aab9d589fa27ac7d1a8beac8cb10b2	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 11:04:57.427129+00	\N
6f863c35-07b3-4afe-a342-314e4534bbb6	bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	735d1c4bdef627babc1d32fdea7d7fba8fbc8b4a5935c9b21a51246b77e482e4	\N		::ffff:127.0.0.1	2026-08-05 11:13:06.046506+00	\N
f1dbf17b-1599-4771-add6-d9092283455e	624934b7-aa0d-4f5f-9273-5698f83ac494	e4cb7a8aaf45f28275a3dfa4897dff4bc115c6bae46ffb3b464901077404c7d2	\N		::ffff:127.0.0.1	2026-08-05 11:13:19.896754+00	\N
82ca29b8-0a52-478a-a732-2f224a07e8a5	2b1e1113-1628-49d1-be26-eff461ad7395	9b9a883d1e93f53cba7e59eb7411dab7ce0b99401b5697475625f8d18bd423fc	\N		::ffff:127.0.0.1	2026-08-05 11:13:28.149886+00	\N
b6952182-06f6-4002-b521-ba3df720372c	c87d0759-ca5d-45db-b827-62210ce3b125	7c38cac7a961c48cf654a35a984de82378752fc34412b2bacdae427fa2bafcf7	\N		::ffff:127.0.0.1	2026-08-05 11:28:50.021204+00	\N
ca64c4db-a4d4-4035-ad01-6eac46d389b9	fb7f5234-b6df-4a37-99c3-1adeae58416c	46c1f75a8ee525cd5540ebbf2642e12951e7b4aab04080b93f95474845e22ca9	\N		::ffff:127.0.0.1	2026-08-05 11:29:04.061558+00	\N
7ca29c60-f50d-4f45-83eb-f9d41f271a14	36abc252-b881-46f8-add5-7549fcf1c02c	da17d6d6b34aa8a603ccfa8104f2197d6e0076d93687d43dca702fb16b4ff947	\N		::ffff:127.0.0.1	2026-08-05 11:29:29.236397+00	\N
b2652e29-ad36-43eb-b617-c2455e4b0caf	318ed88a-c7bf-4ab7-b73a-85007e92a400	d2418d6079cb4399ae0bf67b5aff1b62134729b00084e3b1d959548d3a477892	\N		::ffff:127.0.0.1	2026-08-05 12:51:53.776073+00	\N
30a3e940-d09f-46d4-9f86-c19816bb9ee5	61c7677e-2d35-423c-9088-77f26fd210ec	638bb7beb888f5de5890a38ceef5ce7b23f39fd108e61b1f266916fe26330bac	\N		::ffff:127.0.0.1	2026-08-05 12:52:14.044524+00	\N
3197020e-ee63-452b-8cd2-e0ba0cfa0264	ef29ab34-0926-4d68-b3a8-f9972bb2a232	bc5ee865ad9253b5d1bf73329c8f86a9b274f145b3bf66cb5572911e323175bd	\N		::ffff:127.0.0.1	2026-08-05 12:52:37.558654+00	\N
8993dc76-b2bc-4380-8caf-d1290c8451cf	dc416aae-d920-4b18-a151-fd516b79bc27	08d741ebbf75ffa2e275b315d12df13f24ef1d91dce562f85a21f7d498dbfd3b	\N		::ffff:127.0.0.1	2026-08-05 12:52:53.91641+00	\N
503a36d0-2557-4ec2-920c-40aaceb58182	ba861ecb-15ed-4eb9-a10e-3162b7d25a5c	d64d54e35226d2949de986bc8379abb0363d36f32b096b99d7fdebc9bb679f99	\N		::ffff:127.0.0.1	2026-08-05 12:53:03.745922+00	\N
0a24a81a-8fb9-4bd7-a76c-0912c16c420e	ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	874a54c270639cc4b41f1be3e3ddc295fd190f0ca278f7818a4a60d8c31afc3c	\N		::ffff:127.0.0.1	2026-08-05 12:53:06.606456+00	\N
10082bea-572c-47c4-a1bb-ec1c7f1acbcb	36615d5a-0131-4c21-98e3-956ceca31d48	641fdf35dd36222dc0a55d8b6f7737017dc4e17d2fa3a3797a9e38a6cdefb13d	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 13:01:29.466785+00	\N
59697852-6001-44f0-a25d-5a515e186208	571b5cef-8904-4a2b-bbeb-aae3a5dab145	df791b9b27360a6e16c6b8ee5a86f540139271172d70e9e35d1b11d10ce5b5a8	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 13:05:10.588905+00	\N
a0fe3c72-e3ce-43a5-b5f6-1dc98cb8a24c	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	c8fe2f0116f0fa4ec36c422d90e38e11731afe6d1b449f23cf5dd5fda4e978a7	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 13:05:47.116743+00	\N
f00f69ff-8721-49c1-b08f-1f9413f75372	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	a60ac1ea8c186c0d59e69522836cc3f6b365ab2969e3495fb06fa01b5c8331d7	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 13:13:47.371624+00	\N
1ea9dd8e-1523-4755-b0b4-f85ac59871bb	1993fb25-6147-4b5d-bb36-88f756254fd6	20758c76b0fb71ab224d3e5a33a1c822cede6af0b49813d2650e7173a86e7d37	\N		::ffff:127.0.0.1	2026-08-05 15:23:56.231084+00	\N
c163bf9c-04c7-4692-9ab8-c5faefc6f63c	f7a8ee4f-267f-4744-9fd2-46519cc21ab6	cb123ba9c30db7cb819a4ac07f2be82a7a519d4fc64161d0f226f7aab7cf34d7	\N		::ffff:127.0.0.1	2026-08-05 15:23:56.609222+00	\N
542a2f4b-18e1-4210-9d75-5e7989260e57	c8a549c1-0fe0-4e7f-af9e-56cc61372088	f2e199a76d2e33028518f6da62be74dbd30f2b61d8bc0c1f589b3adfe00a7132	\N		::ffff:127.0.0.1	2026-08-05 15:24:11.615799+00	\N
95589dd2-57b0-4d4b-9298-e44a5ebbdb20	efcd6ed2-c765-4041-9feb-cd72f820ee45	c09dac55adfea324691e8e2c796e01e6fd01cc5ce0c4678edc893ac519cfc2fd	\N		::ffff:127.0.0.1	2026-08-05 15:24:11.981386+00	\N
6c1bab17-6cfc-4465-b35a-834295fff833	9d68a437-4f37-4213-822f-c5babaf79822	e977896efdc9591ec4ea5c3dab3f8769c437e67c51031bbe08bc6c82871c0613	\N		::ffff:127.0.0.1	2026-08-05 15:24:16.857582+00	\N
d21f4fce-6a41-435f-8078-b872bf71e4f8	b0422680-a14b-46b5-aa9d-d9d226b3a071	059a00229389755ec4c92970961bc431192dc7cc15b57b916bf653720a1a4e5d	\N		::ffff:127.0.0.1	2026-08-05 15:24:17.90168+00	\N
98c79fdc-5fc8-40df-8ad5-f20ee743d324	d3b8e72c-44b9-4d1c-aae9-34648e47dc24	77492e9ff0341291a544885dded35841dd16e8740bdab14d753189d4d5ca2c2d	\N		::ffff:127.0.0.1	2026-08-05 15:24:19.318448+00	\N
4b77e720-7324-404b-b072-a61163b74350	d45844b4-81d5-448a-9e5b-549832b07407	5cb853e21d605bfed96489398aabe80edf8f83ebe8da07a583e74ab398efacb3	\N		::ffff:127.0.0.1	2026-08-05 15:24:32.525055+00	\N
2367a06a-d103-4cf3-ade9-2c7a137cd977	23d5ef6e-0ae5-4356-8387-da764ecd1b7a	10f6894843d2f28cb209f93b96920a67bdd78feac74ca7cf2e6cb92e41924b6f	\N		::ffff:127.0.0.1	2026-08-05 15:24:35.56363+00	\N
54811a4b-6f0b-43dc-933d-63b2d951d160	e576df13-6cd8-44a2-be61-44cb945bc25a	8b942c6070856001f29c6058302b0bda65a53e86dda78e6e4b8111b3e7801cf5	\N		::ffff:127.0.0.1	2026-08-05 15:24:35.97713+00	\N
bf4f35d7-ad3c-4bdb-b83e-9472f944698c	190b3097-f5a8-4ffa-b684-b8c6e77e4121	90f24f1f2581bbac0777d46900902ec3e35b9a65a1450a751622beca0da1d1f6	\N		::ffff:127.0.0.1	2026-08-05 15:31:11.008619+00	\N
1631eba1-f313-4bba-99a0-daa06727ab4f	98b38f18-ee4b-459f-b9cd-ddaf62d1f6da	0bb30607846f98362c725aa827b218c421bdb8328ce52b8670416aebb4e96b55	\N		::ffff:127.0.0.1	2026-08-05 15:31:13.048312+00	\N
2f1d8f52-6938-49ed-b94e-1f01e6ec99ae	05ae4bc0-b60c-4abd-b963-794677dcf06c	3028db2a58683c82d731032bc3d94b9ddcb46857aa947f5ac261117380761d59	\N		::ffff:127.0.0.1	2026-08-05 15:31:38.389759+00	\N
cfa3bb63-8763-423d-b944-513516b407bf	59296eac-cc9d-44d1-913d-a5ef3365343c	aba040f89b2a01a6562d574a6153d683c3bf585e51b1d5f6740bb6d4f17b6cce	\N		::ffff:127.0.0.1	2026-08-05 15:31:39.809558+00	\N
965fbfad-2db4-496d-96bb-8d5c73659caf	44edbe9e-2762-4722-bac2-b9731acd35b7	c8ce70f2007f1c59b5f0df7fcf66e0bcc8eccbcbc4122e084d3ce74fa45f6aea	\N		::ffff:127.0.0.1	2026-08-05 15:31:59.820508+00	\N
5c268264-81f4-4215-a576-78252ec23bbb	fbd4b51b-493b-429d-a938-94354ce49c63	5d25020d4e46cb572be44c9c78fd941b28ecef345e1995fe958bab79091bbdeb	\N		::ffff:127.0.0.1	2026-08-05 15:32:00.248278+00	\N
f21e2d43-7c2e-4b62-a7b1-e50c6faa2c9b	8412df15-3a96-45f4-b129-f82489d85111	5bdcf6777d015ba36722436abe07003190d39eca106229f92e1d7032c45a0867	\N		::ffff:127.0.0.1	2026-08-05 15:32:13.388569+00	\N
90e296a2-13ae-458f-9ab1-ff66f8f87c27	7ef79457-71f5-4e8c-bb17-fee5ba9da51d	c1e07c2f521e9a3042ed53d7a10947fdf8ee7005c0ba8fb65f9a2b1994298839	\N		::ffff:127.0.0.1	2026-08-05 15:32:14.628474+00	\N
87ad3ee3-15b5-4454-8142-bf1bb0824b47	a8ba3347-742a-4523-aed8-77c774142345	edfc4d63a40462eab8da19582fa27cf1b7192f14ec2184d6a649e942f8824349	\N		::ffff:127.0.0.1	2026-08-05 15:32:18.028354+00	\N
4412a11b-c075-40e6-8097-7c09cdf00ea3	3d8c7d31-67c4-4023-b401-4ac046cf56ac	2f01053926ef8c3cb6a3963dc529a2961517e426bfdeb1dcdaeadecd5fbbcb02	\N		::ffff:127.0.0.1	2026-08-05 15:32:18.473427+00	\N
b5b0e2ad-1e68-4f20-8ba7-f08712c88835	fd039e52-629b-489a-b445-3003be85cb8d	7a1699fd47150bcb76da985c327ce430dd81c91b54b81edbd5a6e96b75c8e800	\N		::ffff:127.0.0.1	2026-08-05 15:32:21.814814+00	\N
377f1c70-d71b-4649-ab98-abe70f02d40d	36615d5a-0131-4c21-98e3-956ceca31d48	ede82e7bce9e4f3935255048a9a13a3af752d1a572b5d298e5f1dbd5bd43b0b7	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 15:49:02.710244+00	\N
17fb2d49-744e-4978-a428-5dfa4aabe47d	36615d5a-0131-4c21-98e3-956ceca31d48	c42430f2d609fdcdd26613a004f91b1688b0939394a61406154d59c400f77009	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-05 16:28:22.384596+00	\N
92a376a8-9ccc-488b-9154-17c0b51330e3	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	0ebb77ba1fe19078ae2a08cdb6e4c6ef8934566b14144be1fa14a560b0aab179	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-05 17:20:22.044398+00	\N
6a77ebe4-db5e-4e05-abcb-2111373027e8	886d75e0-e090-4177-a6d8-570db8b1208c	184ce13a0d39eeb828cc78d01b073eaf5c614c31d2667748253b42a5f70ec727	\N	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Sa	::ffff:152.58.130.253	2026-08-05 17:35:28.685503+00	\N
2f067dcc-5873-47fb-a0f8-1a7dbdf92e51	46f8f2e6-f83f-4a03-9c6c-684a91372144	adfd1e8fe6c3a8197feb6f300d45522fb51b0c1ae81fa186ee96b129fb2cff27	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 02:15:42.232343+00	\N
76e39c94-5e5d-4d70-a5f6-82b86e89cb14	886d75e0-e090-4177-a6d8-570db8b1208c	6959b8b345e98d9fd0ef9304ec481e0a0906db22389fffc8ce4ab9e2e57a0bb4	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 02:13:40.381731+00	\N
fc4641ee-8ee2-4248-8d3d-b3c1114e2d3d	6a62dd3b-10b2-44fa-aed4-320d1685025f	46247f8cef0600aadcc0fcbb5595fafc5d61c011fbc5e274ea4771c9bb69c348	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 02:19:03.470008+00	\N
c7d36118-04e2-4c70-a94c-4215a474945e	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	ca68f73e39f387078e8477d9a03c72f63efae939defa670134386546f6743cc4	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 02:19:37.337267+00	\N
643b62c0-2d1d-4583-b39c-b3369c254b19	e2fd25fb-510b-4af5-a453-84ab5a69cf21	e286e578cf68a090ee759b0b6eafaa01d7361f15ee6308af6e384e7be411576e	\N		::ffff:127.0.0.1	2026-08-06 02:29:46.987545+00	\N
9fd40cc0-58a1-4332-a323-396d19f6e4aa	f1d17cc9-15ee-4758-846e-e01e49b8779a	d7c2b34454a82d039048a3a4b4c973ca9e4189a79b65167580807df45e7954b8	\N		::ffff:127.0.0.1	2026-08-06 02:29:47.38188+00	\N
6a83fdfc-cfe3-4d8d-925d-2fc871cf2812	8b6fae7c-974a-4d6e-9221-f37cf6a97469	53cfffcf8743bfa6cb6e403d74571bf52d489fba63a6576b67ff57f6fd748416	\N		::ffff:127.0.0.1	2026-08-06 02:29:55.964625+00	\N
ae13e9dd-eb00-46d0-b564-132ad090c57f	4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	349061286bef6dcd594765eb8632050593650551ac3308eccf2cd3b67b290065	\N		::ffff:127.0.0.1	2026-08-06 02:29:56.347966+00	\N
287f3c66-caee-4c41-b6e1-d9900143ee78	3f591c6a-5509-45f9-a2e5-050be735735a	bb9b87d38b46c7dcfa876e3e1c2740d76d20df74106809b0282344b1072db58f	\N		::ffff:127.0.0.1	2026-08-06 02:30:16.934428+00	\N
f6985d25-5980-470e-9e37-b1f4d2ae8d91	f5a61371-a191-4bfe-9659-1a05b788696b	562fc1eea62b33245ed169b40223aebc405d7616a060617a41e69c075ecb425e	\N		::ffff:127.0.0.1	2026-08-06 02:30:17.318504+00	\N
265e4e2c-6564-4f19-b3e1-22ea7d03059a	6a38eeb9-c8f8-4c02-874a-f365364bd4ff	661ffe4aa53f12c133d89e2d4fcda5ffbe475704b2baa534ce066924b6b8dbf0	\N		::ffff:127.0.0.1	2026-08-06 02:30:29.032676+00	\N
fc4266c2-ec2d-47b4-bfc9-74a93155d54e	6c982b06-1aca-4977-b319-191e16fc4de6	6774bd6b40aac961d3f11faea3de58a1137d559a905b2ddf735c88a070855bbe	\N		::ffff:127.0.0.1	2026-08-06 02:30:30.02575+00	\N
fa30b6bc-d8a9-4658-bcc4-a721ead4e388	15628c01-d0a0-422c-95b2-dcc978ad6fa1	37ad187e9b626c805ee4d2d3652653b572453f7fb3a296d16d539292bd1b3d8d	\N		::ffff:127.0.0.1	2026-08-06 02:30:30.453816+00	\N
5cc0001a-55ad-4034-a0ab-d053f77f73d8	2d150870-1d4e-42e0-863c-0bad5782141e	e7190438588b913adef3755b488ba213bdf29e963229d915ab40d1628cdae447	\N		::ffff:127.0.0.1	2026-08-06 02:30:33.484213+00	\N
81d8469e-d867-455e-b233-26f17dd1349b	d4e10fc0-e272-4867-81cd-567a0e84cfdf	dcad6b041175ca2e47d6f8c412a8b99c837c0ef746d1a84760b68aa96bd370b5	\N		::ffff:127.0.0.1	2026-08-06 02:30:33.878256+00	\N
dc8cb703-2403-46c0-97e8-882a3aea55eb	3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	6e37308ec40140e7e837842999ccbb149019b2a055823d82c30e6d681d472c45	\N		::ffff:127.0.0.1	2026-08-06 02:30:37.061497+00	\N
ab2fa5be-23cd-4120-ade2-5c76c71e3a9e	5aa1f3bc-0de4-4093-ac1e-3859b13929d2	7205f2bb20f4ea32238916cfada9fb3214bf0e6a7364b045a2563f96cfe09166	\N		::ffff:127.0.0.1	2026-08-06 02:30:39.48585+00	\N
6c133d26-5ba6-43d5-b9fb-66c300d717ce	36615d5a-0131-4c21-98e3-956ceca31d48	9d9a0412df0dfa48dd2c18ae8b1badf651897082eda90d03ed691e36ca9344fe	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 02:31:46.867939+00	\N
65dcf7b0-78b4-4c95-97c6-b6fca9901316	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	c730cc3f8b3bc2173741b6586b96081b9e1fdf8d23ff46dabce5882735c0302a	\N	Mozilla/5.0 (iPhone; CPU iPhone OS 18_6_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Ve	::ffff:104.28.37.209	2026-08-06 06:04:08.206979+00	\N
9056ba68-5f24-4bbe-b538-adc923da8f53	97ad09c8-7854-4467-b96b-ceb2b390c0ce	f39010ea603d0f2e5ff455a1bee3563f2e27b8a7af9ca1a198ffece2e2e67f95	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 06:27:51.64856+00	\N
95cbfc04-337e-4e27-9ebc-973e1fe04869	1e57d93c-53e2-4f0b-92e0-944de0c43daa	74797270c37699d929978fd823de082c61160d3fe55252c1112cbbae9db5d8b3	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 06:30:23.570799+00	\N
58e28c3d-f41d-4620-8f86-46b5833a1c09	f6d46263-407d-429f-aabc-f9e3c7b6aed3	689ccfd5c808d4e28a4e4fefa62c6e72d1f2cc0fa898e4b827950ec054373289	\N		::ffff:127.0.0.1	2026-08-06 06:31:47.49162+00	\N
aec021b6-60b6-4ab8-8002-3563101a0ab8	4758c076-09d2-42d8-88cc-cce435637c32	75364410be7a0e49251c3f46f8606c690dde4bc8b5e0b398fb603e7190470ea9	\N		::ffff:127.0.0.1	2026-08-06 06:31:47.898675+00	\N
aa6885d0-aaf6-499e-b308-f9ce3407a55d	59361f8d-559c-4874-9324-4d19418db3ea	fa110ec185d1697532c4d3e7c750cb7c18b840f5c484aece75cf9f84e6b2f36d	\N		::ffff:127.0.0.1	2026-08-06 06:31:48.544361+00	\N
57a674ec-7c02-4f7f-8e56-8c2f02bfc872	5ad80524-52fe-43f5-b245-2a7ae49a92cf	7764c8014bd6ac743a6dd7371c9f290656056f38108c7b110ee66b1adeb3d757	\N		::ffff:127.0.0.1	2026-08-06 06:31:58.056059+00	\N
83a2d932-bac8-4d66-9968-f650c6b46436	4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	c648d6ded0793fee23f20f6e83350deb551e0017503cadd6588bcf95ef1b9bd4	\N		::ffff:127.0.0.1	2026-08-06 06:31:58.440348+00	\N
933e7798-2488-43e5-90ac-14818ebfecc7	3a87cada-81bd-4de7-89dd-d9d1150bfada	70375c8da22bdf39e39e5e2fd71dd77b6686f3e56d7ed26c70bc332b88430b9a	\N		::ffff:127.0.0.1	2026-08-06 06:31:59.078758+00	\N
7505a100-9d47-41bb-a317-b987f7cf8be0	6914b9da-19a1-48d7-bccb-a39a08216f7c	9be41217acbaacebd61157f113e3641660f01a40e92647fbfea9338a0c4b5f3f	\N		::ffff:127.0.0.1	2026-08-06 06:32:07.158032+00	\N
32f7eee4-7bfb-4abd-83b5-0e7e7b71208b	12387821-8e7e-402f-9291-8f1fbadbce1e	95583e365ddc8e4af97b37c55f39f43be0f03c71d7008baf33ada08d35973c3f	\N		::ffff:127.0.0.1	2026-08-06 06:32:07.560857+00	\N
708b4d68-33fc-48f2-a60a-7a8a99321d50	01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	47af6c0a5a5f6cbd7caf6f9574bc3b67cfa6d3d4aa30a828dee724ec9d9d66c9	\N		::ffff:127.0.0.1	2026-08-06 06:32:21.098715+00	\N
1dd64502-2e5a-4f35-b99a-a6a54e74ef47	d31b3330-980a-4d38-bf4d-c221a5033bda	f1aab94a4a78a79ad657a831e044c6dc3178e233b27c08617bb93d5c77891e6d	\N		::ffff:127.0.0.1	2026-08-06 06:32:21.49033+00	\N
511677b0-c50f-43d3-862c-1110cce34071	3d9b43f7-0071-4d41-90e4-b911c4447dae	fb4234ff768068c3f1c7c5d55ad5917f7dcee9c791d8786d52726df16e8e95f1	\N		::ffff:127.0.0.1	2026-08-06 06:32:22.172224+00	\N
579e2908-b56d-4572-877c-3d9cdbb82018	2a224da9-7f89-435d-bb73-bf545c2d6bdf	dbc544e7daea9d1b2464b7955192c179b663552d14a22787793384038d7966e8	\N		::ffff:127.0.0.1	2026-08-06 06:32:27.817673+00	\N
b09316ba-3a1b-4605-875f-0656e659067b	35852f38-c0a3-4f81-8b41-0ffd689ac6dd	43d6e4a7c677589f09863f52c11187e3d20fd93f6872155834aa51c4715a0dfe	\N		::ffff:127.0.0.1	2026-08-06 06:32:28.882503+00	\N
db6e639b-0327-444c-91da-e9fa95096727	959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	3afcefd5ec29809587b9ed34f19e1c3dce9ba61c3783931d74d2d18d1cab2db1	\N		::ffff:127.0.0.1	2026-08-06 06:32:29.241644+00	\N
99815b54-edbc-4336-be21-e3582d1c027d	679a9cbd-c4bc-4326-a754-e6d09a55b010	751fba6b32f654ffbcc0873b1ed855445cf5b946cf432706c66bd0da866f6fc8	\N		::ffff:127.0.0.1	2026-08-06 06:32:32.25922+00	\N
b38ded7c-35c5-4283-a82e-559d59cfa392	08b05119-1ab8-4da6-aaa4-691d8b9d62e6	7877ad55f2d627679d8c3a57ba2f7d34f35147d116661e58f233147530771626	\N		::ffff:127.0.0.1	2026-08-06 06:32:32.632989+00	\N
d7e14621-06f8-4a7a-b461-890b4a7844c6	3033d43d-8034-498f-b48d-5c549e8f97fb	ba1f4c7fc6d3eaa2a507a2ad9501aef2b040f8291bb66d5cd8a5bef584b94e89	\N		::ffff:127.0.0.1	2026-08-06 06:32:35.467115+00	\N
1f620bb8-d3cf-4be2-a2c4-bfcf513fe193	3c27e34d-8df3-456a-8b12-079170f1f55b	c1940c2c150b074d52f5a4b596e9648c8940a533b46c823e663632ff4d852997	\N		::ffff:127.0.0.1	2026-08-06 06:32:37.899283+00	\N
30fd1f9b-ab6b-4e9a-9169-20901b5eef81	d1ef1fb4-c2d5-468d-8a4f-d1123278f72b	5a26355639002aba147b0f361a95c95a36cb25ebf0d4b88c3cb145bac1005e69	\N		::ffff:127.0.0.1	2026-08-06 06:33:13.542378+00	\N
b2328a44-144f-4819-bdb4-ce8933a504dd	e81e56cc-db91-4ddb-b1e8-530510958e6c	6f9b515fbef5db007d6abdd66de052acc5e040c4bf931a03839ecf6a2d85eca4	\N		::ffff:127.0.0.1	2026-08-06 06:33:15.110748+00	\N
97b0ff8e-ff1c-4d89-ab93-a38e8ffdb82c	25634a36-337f-4d14-a96d-1a843df8614e	f74658f9aae442c935df7aa5aa061bf027645deb49b17e1f1d4c53c697a1147e	\N		::ffff:127.0.0.1	2026-08-06 06:33:15.615559+00	\N
8fd2b3ea-4861-43b9-8b5c-884931267310	6003b134-d829-420c-acd5-b3f86ffbbc22	cc0d604295937b0c13c64857264427b183166a8517f133e7e85eb6ba87ae764e	\N		::ffff:127.0.0.1	2026-08-06 06:33:16.908435+00	\N
120a6533-118e-4b8c-976a-35fc2f4396fa	1c16cafc-57a6-4651-b25f-a364716b322e	d9d9554d0dc6eb05e9490ee6c89b23951cbc661ea05b76b20b771ad3a5551e38	\N		::ffff:127.0.0.1	2026-08-06 06:33:18.632654+00	\N
75d6045d-e2cb-4159-bb2b-b3da6ec302d3	eebc8df0-9557-4dbe-9644-ebe4a13b931c	3de94a987879408f089c9d6a1dd420ff48a4da17451bbb67737ea1bf36955caa	\N		::ffff:127.0.0.1	2026-08-06 06:33:19.020754+00	\N
ac2b4d60-c8e3-49af-865d-f97df305b10c	6df70e40-bb74-457a-a687-5e470514447b	1183a4114823da3094de4cfacf027055b7cea8488e3c64c7701447059d6df65b	\N		::ffff:127.0.0.1	2026-08-06 06:33:22.752707+00	\N
308318a9-75b4-4dd7-b62c-9a4314bb6dfd	02b1c183-6a2e-4088-be1a-0ad7ef1c638c	f7e54df51bf0d7268ac4c366ddbfd86e4a226c8d6ff17dcedb07786fb70b1140	\N		::ffff:127.0.0.1	2026-08-06 06:33:23.292479+00	\N
e1da0d06-98b5-4578-86a9-ffee3bf4cc21	5fd98325-1ea1-44ab-904c-b7d9c64df81a	75946aa01b6070b9428cd0ad895228c5d1a78c7e51aacd59d545242c448dd6b3	\N		::ffff:127.0.0.1	2026-08-06 06:33:27.061879+00	\N
081efa80-1213-4496-94af-b418fee9f0dc	f87a94fc-f840-4b86-a2c5-1c32001d8a05	3d258293cd7b0db03df8cb3dbfb6f20819b696e412ab949be21e86d9076f6fb7	\N		::ffff:127.0.0.1	2026-08-06 06:33:29.818673+00	\N
8620e499-2c8b-4873-a682-96407cf9a0cc	a9cd0b33-31db-4738-bc7c-a1b7158adf4a	5ced5d82f7e96c02ddfdc5dd0936779ffb176abc84e2055deabdbf1deebcdcd7	\N		::ffff:127.0.0.1	2026-08-06 06:33:47.739374+00	\N
51aa72f2-854e-4fb9-aa73-41baa796ec30	287fea1f-a616-4b7f-82f8-fc0886dceda0	fe8f49b5f7ca2718f124dd8c5645cda3114a588836a09f940ca844cdfa0b807f	\N		::ffff:127.0.0.1	2026-08-06 06:33:48.729601+00	\N
80cd84f6-da8e-4865-9876-03c7f7d1b1aa	6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	26cac301f2ca87bba93e72efeb9ada5a2c5aebefb4c0b02a9131ef401081f43c	\N		::ffff:127.0.0.1	2026-08-06 06:33:49.119245+00	\N
9cbf2232-fa2a-4736-8ec6-62836cdb25eb	730aab59-18e5-4343-8ea5-20d21d417f9a	d4458346b0087e454f8dc84e7fc08ff1577bc43f5e21f68403d7cb66aa27b249	\N		::ffff:127.0.0.1	2026-08-06 06:33:52.309203+00	\N
61172899-d0c6-4507-9eab-0d5dd4f8a336	b23ee7a2-7e56-495e-96b8-f1253aeaea36	fe555d652e6f99c49824e555f406c3f4d25339c2628ccc363e6d64f991c8f46d	\N		::ffff:127.0.0.1	2026-08-06 06:33:52.904752+00	\N
74400944-1d59-48d7-ac31-0cceb7674474	421ca638-b359-4990-8854-982f64dc2726	19fd0b2151ea32098cbbc29ce49e87e6f54324cdb77b53190d73c7f6dd8b6876	\N		::ffff:127.0.0.1	2026-08-06 06:33:53.924221+00	\N
1fbbb74e-4baa-4878-8d60-22cb249ecbba	7294e7cd-2388-4a10-9e3a-31f532b748ee	91858fd67b1b6fcd2cb63b14462fd3fae2cee45364c576b02ffd68a3f6fb0e7a	\N		::ffff:127.0.0.1	2026-08-06 06:33:55.716498+00	\N
13b65910-6cf7-4b2e-ae44-2fbac01ffeb6	d7c3fa7c-c268-4e5c-acec-0450571fdb18	66972978e2e8d67f98550125a1aa44b7569ed73a9ab83915459448bb43311578	\N		::ffff:127.0.0.1	2026-08-06 06:33:56.109156+00	\N
7f1e2978-8c4a-4924-9741-6c258d0aafdb	efe874e3-dc4c-4942-a44b-98f2a856525a	2eb75eeeb1c0c0681b7b10075eb779415a2dce311e0b748281deea7d5a26ff01	\N		::ffff:127.0.0.1	2026-08-06 06:33:59.46861+00	\N
123a5519-32a8-4e65-a540-85d074d1a748	ccef9aeb-4e3c-4923-bb15-f364e42fa1ac	ef599a98b02f9c3b0a2b9e71aeb25f636e9322028007d4b1a75ef98a129367a2	\N		::ffff:127.0.0.1	2026-08-06 06:34:01.957883+00	\N
80b316e0-7fdf-4778-9b99-843b3ba70e8e	649308eb-cc8e-4702-b6be-f823419073cc	5800222f39ad34d389fcf885dbdb59b3f1e50d5954c000f5e945742084bc5fef	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 06:34:02.074407+00	\N
0163f8c8-54a0-4e93-a99d-9a6da76ee6ee	bba02b1e-aae7-4873-9983-7a8196db808b	9d5720ad61c2bad0918baa10821022aecf8a2807678ba8402b54f5db9c4c0b4f	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 06:35:34.606449+00	\N
e63b3451-e395-4ff3-971e-9cf29c21bc7d	f3aa32d8-e43d-49ff-928d-a5c32e4a2576	a9a97c66cd1acaeea6bb9937313ba24605a4d3700db88944b2218e2e1861788e	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 06:35:35.018346+00	\N
0d44390c-7d96-4cd1-8b78-adaf4b8f6cad	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	4be3d9a3df6e490631e3e3bda32b74009194ece05d3dc3100b316d5dd3125768	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 06:48:16.266316+00	\N
aaff97bf-a3c5-48a6-b3e2-1832e4150a11	886d75e0-e090-4177-a6d8-570db8b1208c	0537a403a8e0325a920f1209f0f2fbde2d177e45dd53646fa0101700a9c1b560	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 06:57:44.982948+00	\N
442c0483-22d8-4df4-a39a-330298e6e498	886d75e0-e090-4177-a6d8-570db8b1208c	fb7e7c42d4ffd881d51184bd2498dd3dd344e5161b35cac400cbd02ba6da04bc	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrom	::ffff:103.255.105.120	2026-08-06 07:01:33.173008+00	\N
0f64fc69-bbcb-4ecd-86a8-6f36d1e14208	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	186902f77ba21e08e622a4a921f2cc306d8f238aeef8cdd4039675b709ad0758	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 07:16:39.190352+00	\N
4e9c9c44-ac01-44b3-955e-b4ee41d88d4e	886d75e0-e090-4177-a6d8-570db8b1208c	facf63258a42f278e096595426c11f947e3220e290faf3cc8361a54fce7b2079	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 07:16:39.765385+00	\N
d4b3c8a7-669b-4c1c-9f94-2848f702c04b	886d75e0-e090-4177-a6d8-570db8b1208c	d6e7bf2864f4034bf3f04c7f9502a2b345b96e4c73c99c57ca57a4967335c6c5	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.	::ffff:103.255.105.120	2026-08-06 07:18:22.16343+00	\N
2f433d46-4996-410d-8c4b-80b9d283b14f	58e3af63-5f33-49a0-9089-42509c07464a	efbc807127f937ff387b8534aae0e9a8da3c930b5d40657b742229534771e6f8	\N		::ffff:127.0.0.1	2026-08-06 07:24:22.062762+00	\N
479ebb36-1942-410c-83e8-77ff5e12820b	b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	b2f5d4bc3a521ea676506c139b6517fafdb491607d3437ce5f34c5c87d8d8556	\N		::ffff:127.0.0.1	2026-08-06 07:24:23.17844+00	\N
c975fa32-a7f3-45a8-adcd-c0d3a0d95c61	c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	6b2fc7cbbdce2529766f90c3c2796952ed32a87cb4ea3b5401d9a471ca190f92	\N		::ffff:127.0.0.1	2026-08-06 07:24:23.61456+00	\N
852a6877-ed8f-4113-a697-608a8c8df8c5	7607d532-01cb-4685-93d0-019c266c06ca	39e0ffb11f6718fe4a9071e89119e9bc20eaec1aca848b0534929af05e8e85cb	\N		::ffff:127.0.0.1	2026-08-06 07:24:27.371762+00	\N
4c217a5e-1dea-4c5f-88ad-741769af5115	150f70a6-62b8-44b8-95bb-3e78bbd916be	6d99862ba1866017658573d06749fc46cb51728504d5dbd9a1404176fd2e949c	\N		::ffff:127.0.0.1	2026-08-06 07:24:27.80533+00	\N
a77195d0-067f-4d74-8331-2d42e5bd9413	b3e94172-8013-4cdc-b429-33dd88309863	bd842462074bc01efe6a893f7b678df8780d21f914b03ef9d348aba9e735dbcd	\N		::ffff:127.0.0.1	2026-08-06 07:24:31.195814+00	\N
4c1e7866-ff20-4862-b976-c1caa8bcd31d	54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	ac1016b9bdfcdb0b2366784dea3c5f3c1d162bb899273b699c17fa8e8e8cafa0	\N		::ffff:127.0.0.1	2026-08-06 07:24:31.656058+00	\N
a1e7aeea-e8e3-4f58-a8d4-250dae34d642	f0288664-74a6-4047-9db1-a266f0bd5811	6da75fc5c92b79ce2ce9cc784a37b6ce65f297c4a3f5940535bc0f03f081ecb4	\N		::ffff:127.0.0.1	2026-08-06 07:24:32.727768+00	\N
60251dc3-70bd-4f65-a560-5afb2f69413b	639ff8c2-a929-4dbd-9f14-e19826bf1da3	ea9a70439f777be55f189533b952baba1413ee955f32bb91276e65caf909f332	\N		::ffff:127.0.0.1	2026-08-06 07:24:34.43252+00	\N
087a4bc4-b2f0-49cb-bdaf-2c1003685946	744043a1-ee52-4e5d-a5d7-91221762e13a	f71b4a80c9c503089992b71455dba1949f38232f6538a68d7a7e1a2288ad3431	\N		::ffff:127.0.0.1	2026-08-06 07:24:36.042763+00	\N
f4c4d3a8-7e6f-4e22-bdb1-e57443e195cf	86061e0a-d9e9-4fd4-91cc-f4113ffece92	d308b8753dad4dbb25f6217cea119daff05a8beb1c53eed76910f50a93172db4	\N		::ffff:127.0.0.1	2026-08-06 07:24:50.093156+00	\N
002519f1-d49a-46f7-9fa6-bebf3f066fc6	06b18ccf-7604-4247-b3ef-4b3dbf0afebf	6e2e1c81cbd3bd584359e24620a5c0886e69b773ff112cb3fc0ad9cf1b448c57	\N		::ffff:127.0.0.1	2026-08-06 07:24:50.515995+00	\N
bcd700dc-7a39-438c-8a91-9f9cbbf21799	af87f426-9540-4a3f-9796-61a215efc6c1	917454d8e5812399513c2b958071e2cfe6f7ca4b94a8a536f1f0bae384612c9d	\N		::ffff:127.0.0.1	2026-08-06 07:24:56.332436+00	\N
d77ad81c-bc95-4639-a22f-481ae0733ed0	ddcd3ad5-423b-436e-b921-4322d3397be4	3a9758e06789ff96fcab3f9e715213b5a0ce7f61ba6c462ea8ebd4a8fd87dc3d	\N		::ffff:127.0.0.1	2026-08-06 07:24:57.422175+00	\N
aebe236c-1d07-40d9-9beb-eb25ccad668c	cf8b1225-10c8-42b4-81a9-6dc603b4b753	95308b5042406db7dab4561287a3fb18ac424d2562e262c7ce580014817826ed	\N		::ffff:127.0.0.1	2026-08-06 07:24:57.828304+00	\N
d1c803c9-6f17-472e-9d65-48d4db3f5693	f20698bd-7049-4b40-8d92-c62216637198	c17063aa995fc844d517be09b3c792fa89576a9c96c9e53dd7dea6ac323b5b6e	\N		::ffff:127.0.0.1	2026-08-06 07:25:01.27516+00	\N
f7ba08b1-4347-49f0-9e33-f7a807143843	b53dcfda-741c-4278-a232-6c0f18ad2805	cd38f48f7f9c4c636b5b9e4c9013c738606b011658913e90c7c96c90aee781fc	\N		::ffff:127.0.0.1	2026-08-06 07:25:01.76585+00	\N
f936b6b9-71c9-4f2e-9059-b3a8dcaaae5e	5461fdf8-9481-4066-8c0b-5470b4184463	cef0d0972482a58bf2e46c4ba645e471b9729a2e3058c02851b0332b4230b952	\N		::ffff:127.0.0.1	2026-08-06 07:25:02.964747+00	\N
7cfd5495-58af-4d3d-a10e-cc551b7c2c53	d1ced440-d263-4434-a49f-2817345f0c27	2cebd0c0a2cc3ad30444268cf1f54e32152f629993b27e5154b21936bb9a314c	\N		::ffff:127.0.0.1	2026-08-06 07:25:05.917978+00	\N
8e937c12-1d42-4544-a155-67bdd396d573	56e227be-5f34-465e-b71c-9fb4ecd94d98	a2dcf4d4c4728097aa774aa406acc300c98431dbb9dd5aac75c98fec509112e2	\N		::ffff:127.0.0.1	2026-08-06 07:25:08.464995+00	\N
3c94fcc5-cb75-4f03-b51d-dcb5e533057a	5380e05f-af41-420b-a86b-6661ba12fa65	2ba390e0b9f69310f3438b589d72c775a1253df164b69b9a19acfa1012037039	\N		::ffff:127.0.0.1	2026-08-06 07:25:19.504629+00	\N
a05056b2-d5a0-4e5b-b1ee-3ac442649332	c7329ca3-ba0b-44cb-a3b5-35291cad9718	06188af940a1d9e69201b6160c4d7377025155449db80f5b8b31374897f13001	\N		::ffff:127.0.0.1	2026-08-06 07:25:20.131336+00	\N
85a37597-12ef-43de-a825-6d7b439adfd8	33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	5f059e29c2ea81c445d835395ab34db579ba42c45743ca8d28b915367220ea1e	\N		::ffff:127.0.0.1	2026-08-06 07:25:40.932745+00	\N
d84aa5fe-0969-4c6c-a534-1426cbb40faa	80208c67-25c3-4c79-8fd5-90b2d0440bba	ef8872a9961f21df705b85c40f172a13d1909792955bfc0714c85da0ba015d6a	\N		::ffff:127.0.0.1	2026-08-06 07:25:41.321972+00	\N
6047fdbb-2247-40c4-9cc5-bd6063453828	30a21658-542f-4803-a13c-651be1e25909	edd9115061ab0d4df9c454657a35d29e0d304eed5dcb65ba31b193bfe458c9b5	\N		::ffff:127.0.0.1	2026-08-06 07:25:44.698742+00	\N
05854483-87ca-45f1-8580-d418b3483b99	afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	3fc4c3d34a1469e0105a1c5296b546f07a87919ad8cb70b8aef87c423d618c33	\N		::ffff:127.0.0.1	2026-08-06 07:25:45.145802+00	\N
a544ad44-9bef-42fd-9f32-895b9fc6ea6e	03877811-6a4b-474a-9eb7-14e02ce491fc	a12cb172c33ceff449b83af20a85e98a1a933c9c87947c4bfe5d8ff6cbab888b	\N		::ffff:127.0.0.1	2026-08-06 07:25:45.894024+00	\N
118d59a3-69e7-4ed3-90b2-3dbd0a1e50fd	19d0db83-6560-4103-ac51-6d11e51c4d76	f80040cc9a94d27f8ddc09d34074edf7fb4db045b1c24e2c20fdbf8efc1cb7ee	\N		::ffff:127.0.0.1	2026-08-06 07:25:47.690683+00	\N
6f54b3ad-958f-4b8b-a446-9be41f71cfca	6ab6b1c0-1cdc-4315-8d05-e38622db9cff	9c788b7e5860b008d8e59b85bd3cedb3b15a5061ad9f09c1140f3b67861b2cda	\N		::ffff:127.0.0.1	2026-08-06 07:25:48.209022+00	\N
eee3da80-fe30-4d62-bc5d-cc7b5402027d	071354b7-e831-47f6-ac76-b927e48c0d23	3b0456b63ea62097fec43953d9d3df1c94318c78b8dd94ddf2edd2a34812c11d	\N		::ffff:127.0.0.1	2026-08-06 07:25:53.838915+00	\N
3bc7014b-bb7a-4822-bc58-66b2419abc5e	16e257e0-1991-4ddb-ba66-1b2eb47f43dc	b70cee7ef73a6c50880bd7e53331ab142a9c779dd2f773b553d4813c0348921f	\N		::ffff:127.0.0.1	2026-08-06 07:25:54.812669+00	\N
f58f3106-136f-4e88-ac5e-9baf1b3cbfa5	6a4d9674-6d2a-4be1-ab4c-213a45492132	56c84e0968de42bb88425a3a219fff080b46600ee26c034a7c87ddcaf9eb3983	\N		::ffff:127.0.0.1	2026-08-06 07:25:57.327762+00	\N
b93482d3-b99b-4e07-bdab-67a30ece93dd	afa30051-73b4-41e7-8b44-fe64122d74c6	74131ff1773bc4e8da66d12751449961d6ee645995f825b33844d42f9a430cc4	\N		::ffff:127.0.0.1	2026-08-06 07:26:07.538366+00	\N
4e56983c-5cbf-44f8-87bc-f5b145af6a5d	519b53fe-56c8-48ce-bd17-3e3bef8aef71	5d4d3919141ee64862162025b9896a24598fcd4a3c1325b17c95d7941ae674d9	\N		::ffff:127.0.0.1	2026-08-06 07:26:07.991003+00	\N
ce139b4e-6735-4f8c-87a2-5aee5a02f1f1	8dce8e30-e3b1-4588-816e-60891d8a3202	bb5c8dd14991791347222007ede12f99a171edc02fe7a06020c2fc6fcdb7effc	\N		::ffff:127.0.0.1	2026-08-06 07:26:50.356274+00	\N
1ef44bd9-2a92-4c56-bdd2-92984c0e5fd1	a7d3612d-d0e9-4807-bdef-60f52458154c	30651b818e32b5ebd301c8dcfe409d140416c042f5810b654bf6f8da64363ebd	\N		::ffff:127.0.0.1	2026-08-06 07:26:50.79222+00	\N
2dd2c572-4950-406e-a074-65154a027fe5	eaf120d8-bd47-43fc-aa4b-975400c5f579	98a8bf6f2bd3ea5339489102756982cf74d8526cfa1c8ddac43e84fbf46455b5	\N		::ffff:127.0.0.1	2026-08-06 07:27:03.208799+00	\N
9df0b87c-d5ad-48e9-adf1-1c1b8d09c353	355ba637-df1c-4775-8a5b-96c70b9a957a	2a4b83b3d458ac58284176a574cb97f96816f2bccd627e68ec5546e233653b46	\N		::ffff:127.0.0.1	2026-08-06 07:27:03.640052+00	\N
0ea171ef-e037-4ee0-a707-cf3d525337bd	7eb32340-5dc9-4180-ae5f-626b2090eb41	1c539cb8d887096fd5338cb7441a416170f9c64220277a82b7f5eb990a5352b6	\N		::ffff:127.0.0.1	2026-08-06 07:27:06.77876+00	\N
e0442204-e310-4ba1-a008-121bcf9f8e57	367fdce2-dc07-4945-af3f-22a1305b03e0	3e67d2259b9ffc46ed0ea01db5cfbc2cb5897bfe6e5b6ae91ada591eac8d0957	\N		::ffff:127.0.0.1	2026-08-06 07:27:07.180876+00	\N
53768202-239d-4ced-b455-f4a2209cf117	f7f6622a-e693-48e5-a4c4-e3bb66f119b6	5dc0771028db2e737d17010ee60782f715afb00c7dd55f4820b42ed31cb1cd2c	\N		::ffff:127.0.0.1	2026-08-06 07:27:12.506272+00	\N
b9a1760f-c168-4e40-bd57-5a97aeebaeda	d91dd487-28c3-4f03-8206-3d7bc12e0765	f77edb7a28a52171a5619cae2b81d39c9acca10ae743029fabf2fb68fec21912	\N		::ffff:127.0.0.1	2026-08-06 07:27:13.811789+00	\N
889840bb-9fc6-48e2-b75a-898feb8fae2c	b4163d69-9347-4fb5-8edf-0a58dedfd768	bd426572a26a69a15a4434e53189a3663ef4a91db11191812a781c01a46e7ae7	\N		::ffff:127.0.0.1	2026-08-06 07:27:14.337025+00	\N
99e83e81-0859-4463-b418-4b9a814f6f58	7e3edba5-5360-4010-85d2-cc7e9e008b1d	de2f6cf8d54d0cac0acc4e6cdf4e42f699d27f60d54421a012263fb354b88405	\N		::ffff:127.0.0.1	2026-08-06 07:27:15.036155+00	\N
cc6146e8-d9ed-4671-bd4d-e47a80bdd4a1	b521ee31-dd05-4b61-8902-a7d8e3359c87	7d01201cecb0d05e357e1d653f0d16d7d9b424efaf574cd870322e73e1c7afa7	\N		::ffff:127.0.0.1	2026-08-06 07:27:17.170196+00	\N
de734b5b-c79e-418f-91a4-a397a4a1f77a	3b777f71-d8a8-4d5e-a3a5-9dbc0057b9ac	d25d71bdac31abe102475504f335090b1716ef7773b251e9562555174bdcafa0	\N		::ffff:127.0.0.1	2026-08-06 07:27:21.087601+00	\N
8e2e46af-9f32-4595-adc3-4093796f03e5	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	755f42cc7cf02572b7c1cb000b1802579766fac539d40a39a653f26b0ff6b3c1	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 07:28:09.765282+00	\N
90794aac-2faa-4d86-a789-5809c2fe74b6	886d75e0-e090-4177-a6d8-570db8b1208c	9090b5f1b3a3113017d65fb2666ff5ad2f4a75267a6ba5f528f45f3ae37c10aa	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 07:28:10.326888+00	\N
9bd0e95e-afe0-4fec-aa15-6aa16731496c	08eb3e44-465f-45eb-965b-b6f56418ecdf	8941dfda98106907dbbd9665f1ba2698bb385d4b329195106eeae21503fb2460	\N		::ffff:127.0.0.1	2026-08-06 07:38:43.789565+00	\N
e4b32053-d143-4182-afc5-65953c87defd	116d7e4c-e0b2-4591-ac73-e8918aaf3d91	c71623865575b9d33e272af6342e7833abb329492abc443c35cb240cd72c3e1e	\N		::ffff:127.0.0.1	2026-08-06 07:38:52.417708+00	\N
62301b5c-0681-4562-bc98-9ad0f425c0c7	2f3e926f-0cbc-487f-bf08-9e1521cd4775	a8301867f130679d111b2b76cbd1e3f84fc3bb6df89bb567d243b68b95aeee04	\N		::ffff:127.0.0.1	2026-08-06 07:39:13.930021+00	\N
7f6a39b9-58d7-43ae-901b-3f99397ee856	30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	af92e0d9a6c29b61480479e21dce17caf8f10d894465996c5095ae5c6997d2e0	\N		::ffff:127.0.0.1	2026-08-06 07:39:24.432787+00	\N
e1f5f4b0-ef40-4ca9-97c4-a012e0638574	88e672cf-f466-4a22-b7c7-fabe8b127ee3	d0a3b6fcf3ebda8ce2eed4c479db8df7d74b809f39dcfa1d474aa9bf690db5b1	\N		::ffff:127.0.0.1	2026-08-06 07:39:24.880291+00	\N
e9d44325-422c-49f6-80c6-baf371d93390	1df93849-4a6e-4842-807d-e5df6c457760	c150875cb2bff4a310b678d2024f7380b12c8c157ada481f4b93689a6557f19e	\N		::ffff:127.0.0.1	2026-08-06 07:39:28.420844+00	\N
0e05687a-1862-4de7-a181-340d0abfbe06	3bd0bf00-d276-46c2-ae5b-11870c818ec5	21755bf254685590a451248adc173c165514f8f913c6a84789c486125c22c9bc	\N		::ffff:127.0.0.1	2026-08-06 07:39:31.742833+00	\N
1990cbb8-5024-4372-98f9-238e64b469c5	5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	7f9944b9e369d911cb5e22979b12c5aab7029c65c6ceb0e8799ee435fbf185a3	\N		::ffff:127.0.0.1	2026-08-06 07:39:32.287753+00	\N
81b8778e-99ae-4427-9f15-7bfbb5bb0a46	7ea9daf4-0016-43c4-b811-70ec6b60254d	cb65adc572d9618ad5b7e611f3499f0c669c63e4f241b6bcd51f8b17e7503152	\N		::ffff:127.0.0.1	2026-08-06 07:39:36.152628+00	\N
10ca5245-3b6a-4f57-b2cb-ccc0b5180e23	c3b43f87-73b1-435c-94a0-c45939b5ee02	f6ad8905635d1e778cfcfa651d936a1c38a7f5e9efdbe432e7074345d641009b	\N		::ffff:127.0.0.1	2026-08-06 07:39:36.786637+00	\N
ec520cfa-2683-4c33-a700-4e594474a6a5	34f33792-5b04-4538-821b-d889040be905	dfd8a7403b4943b3f5a11d4eecf22d008f5bb6e02d081995b595e3902f99c358	\N		::ffff:127.0.0.1	2026-08-06 07:39:37.684403+00	\N
630cf99e-1af2-4b55-a2b5-f9f63122ea3f	75ba8615-b5a8-4bb7-85c6-4e028e1f3359	78afbd4534837d048e884e5905fed990d1a2616b0322f3388d16da79010c3070	\N		::ffff:127.0.0.1	2026-08-06 07:39:42.249279+00	\N
2dae028a-0aad-4816-bcf1-7dd6ee5da0c3	ca5f760e-7b1d-46d9-b000-1d6041f494a5	2bd3ab0d0734e0579d138cef7ff9b264709ed2d1f84141691cd2f5a2cb9bdca9	\N		::ffff:127.0.0.1	2026-08-06 07:39:43.385954+00	\N
2d2312fd-adc9-4957-97aa-1438b00b018c	d95d19dd-5d82-4068-83c6-3683294a76df	9648fe811340644c20f0c87a12d045c6d44da4d9d18a38eb93d3186b20c20c32	\N		::ffff:127.0.0.1	2026-08-06 07:39:45.170755+00	\N
f0d9a2d4-f167-43f4-b3ff-03a809b91724	010bb5b8-d47d-43d9-87e1-4cb2e927b635	f0c1652a9a589951df1036598d299cf606c7da1e540245cc33f402ed37099473	\N		::ffff:127.0.0.1	2026-08-06 07:39:58.611528+00	\N
ed30adab-0656-4ec3-9431-fde5c6367970	89f81735-a971-4f31-be35-afce72c93bfc	64dc86369ebd9d61a23a503d333246a3c9513fb518da3747899cbeb3fbf41ec6	\N		::ffff:127.0.0.1	2026-08-06 07:40:00.25976+00	\N
fd7f28cf-4817-4a43-af09-a943498da514	6e792cb8-9a1f-4c40-a825-985a1dd5b706	730d5ad95de2c347dcc602a2f5519e280e8eb9a6cb506c467aa229c939e3537e	\N		::ffff:127.0.0.1	2026-08-06 07:40:00.704935+00	\N
69473578-f7a5-4840-8378-0c0fab5595a6	c118f901-1a69-4866-98b8-677f315742a1	3c0fdafa7bc47e64c4f67077f7f2df4b5a685fb538689b49bb1910ae84884cd7	\N		::ffff:127.0.0.1	2026-08-06 07:40:04.664467+00	\N
c24140f3-80ee-4b6f-89d2-30426a46d343	cf11c185-cff1-4c4c-a254-63c9cae16950	ed9d5c1d47bbced264048b1a09fe8dd7a6ddf2b2eacdcafa0a5b2461370e9aa9	\N		::ffff:127.0.0.1	2026-08-06 07:40:05.039289+00	\N
2e0dc381-4c56-41be-94ba-0e6145b74cff	77a4ff3b-0afa-4776-8504-a026984e3b14	c236fca03f796496e0a663ad7f7976169f06aae90c7863effa27d877e2dce17e	\N		::ffff:127.0.0.1	2026-08-06 07:40:09.441796+00	\N
d256abf8-3c96-41ca-9306-36b0199f7885	0a0ca69a-734a-464d-846d-03905795c51c	d6246204b62490917b80d38a2c1f55e7912f9b59d5cc6c513354421f3cd95f27	\N		::ffff:127.0.0.1	2026-08-06 07:40:09.812387+00	\N
a1f02282-c66b-4eac-b9cc-0d5174f85a0d	7c008e59-0297-4961-9f2e-33ffde5fa520	d6552209b76d708578bfbd5c8080e34e57604d3e7a47df3ddad612b7e2e9b6ee	\N		::ffff:127.0.0.1	2026-08-06 07:40:10.555727+00	\N
98b8fadf-f35b-4bb4-af79-398604b3f7bc	36163d7d-711d-4a3e-bc45-31eaeba1d21b	fd2976eee217dd25f7d72850e09c9f95638a438b5c0d0a8d724a2e4dca741947	\N		::ffff:127.0.0.1	2026-08-06 07:40:14.981991+00	\N
b932f8ce-4cb3-4a7a-90f7-2423eb9dad6f	68dc303d-4fe0-423a-a6cb-9383ff75a1da	d7c535edde886212d05b3022f19c9492a340399367a315a3bd3e619ef49de65b	\N		::ffff:127.0.0.1	2026-08-06 07:40:16.060238+00	\N
e9125aa2-c6b8-48ea-b013-2a90f7f4a1c2	778e0a0e-af86-42de-bc86-f9ce5f47c98e	b44ba341ab316158bedc91066dd0d5a67a9d3505fd9abc1a0ec953bde547e150	\N		::ffff:127.0.0.1	2026-08-06 07:40:18.891485+00	\N
1358aa1f-6be6-46d6-914f-4331b8b371f7	605f37bc-fb38-43e6-b3bc-11412f4a1724	a0e1de21dd43947c28d5dcf6bf4eaee9529ca40186dc3303a72aaacab7a3e2f2	\N		::ffff:127.0.0.1	2026-08-06 07:40:38.89705+00	\N
913e8ba0-00a6-4417-99af-ac0fe6310e29	087c71fc-5bd8-4fca-b1fc-0eb50342aeee	9d72e0260aa97c614dd7418f663dddd7c8b41c048859789a67161f5892895086	\N		::ffff:127.0.0.1	2026-08-06 07:40:40.952059+00	\N
82b92135-506e-4c5c-bd27-a8ca1a7c3be9	9a619129-5447-45a7-b1a9-45ca14708e7b	260d4b5f19a5be481eb24a46b8a27ae84e7017eb580566d0cc140769f2f31c8d	\N		::ffff:127.0.0.1	2026-08-06 07:40:41.494935+00	\N
cded0a96-2e2a-47ba-8272-2f8b012dc864	7c916865-cac4-42be-a99b-c45e15e6845e	a2380e8be61ffa01e71cad77b2f31a7970213ebc229d23fdb5ab3e8981338a68	\N		::ffff:127.0.0.1	2026-08-06 07:40:45.851293+00	\N
3620a47b-4fff-4fb3-b9b6-c7fa4635640d	cbb5af08-507b-4eb2-b1e4-2c6d91f68187	be504e07194f53faa2211d22d5798a11247538e9ff37d4d39be6715f1dd7236d	\N		::ffff:127.0.0.1	2026-08-06 07:40:46.229144+00	\N
445ff225-dfe7-4feb-b880-961f15a15298	4c071db4-45a4-4caa-8fa7-8c1c783785e2	e7545dd8776d4776a76009e3ad340b983d75bbdf14e0f224fb87ba26743293c0	\N		::ffff:127.0.0.1	2026-08-06 07:40:52.199743+00	\N
a212b8de-5312-4303-b8d5-4d310f16ad3a	215f7372-6d92-40ec-9f9a-1879debb080d	7ea484443d883ff6148a201a9b97fa934fc0e6f90ca345dedd03e93f5bf7f5d3	\N		::ffff:127.0.0.1	2026-08-06 07:40:53.232093+00	\N
b1f8d023-4168-4dd7-a7f3-10f51ecd50fe	0270429b-5a36-466a-82f5-0dbe02c49821	948ed582517a7e8f26f76ad417ae4158cad39cb794a2e24d3e32991d8dcc9869	\N		::ffff:127.0.0.1	2026-08-06 07:40:53.644646+00	\N
f2e85e21-22a3-4ccc-8ff8-27621cf75389	a4d79652-4ef8-40be-b7ab-ca04aaee390d	534ca39ddbe4c617e1062b3c3f5c0d63fee0c7bbfc18e4cddb849c2bd37cb5f4	\N		::ffff:127.0.0.1	2026-08-06 07:40:54.319577+00	\N
4a60cacf-4a3f-4e46-a92e-9614b6dd120b	68347b75-b32a-4bb4-9189-76fd0c9d4947	7c23690b1037274df7ae4205a37d7bd547f12e87d5af498a5566b04a10987f83	\N		::ffff:127.0.0.1	2026-08-06 07:40:56.051584+00	\N
5c67e862-c274-4617-b23a-0e5bd0b6b057	c82e6b63-ac48-40f4-b8f3-0be99df54466	0b517867fc673df0d7fb7f0755d34e96f07472ee37a85e2077d27fbe0e410b61	\N		::ffff:127.0.0.1	2026-08-06 07:40:58.568339+00	\N
68afdfe2-3a79-4dd2-a183-b573798ec032	886d75e0-e090-4177-a6d8-570db8b1208c	8052809887b2c86fd882439db337bc16d556750819daab0f483a824dc8516853	\N	Python-urllib/3.11	::ffff:103.255.105.120	2026-08-06 07:42:04.817409+00	\N
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Users" ("UserId", "UserName", "FirstName", "LastName", "Email", "Phone", "Password", "Role", "Status", "IsActive", "LastLogin", "CreatedOn", "UpdatedOn") FROM stdin;
f7a8ee4f-267f-4744-9fd2-46519cc21ab6	\N	User	\N	\N	+9195msg8ly3t	\N	end_user	active	t	2026-08-05 15:23:56.577296+00	2026-08-05 15:23:56.304044+00	2026-08-05 15:23:56.577296+00
c8a549c1-0fe0-4e7f-af9e-56cc61372088	\N	User	\N	\N	+9196msg8ma4h	\N	end_user	active	t	2026-08-05 15:24:11.581164+00	2026-08-05 15:24:11.289114+00	2026-08-05 15:24:11.581164+00
efcd6ed2-c765-4041-9feb-cd72f820ee45	\N	User	\N	\N	+9195msg8ma4h	\N	end_user	active	t	2026-08-05 15:24:11.949442+00	2026-08-05 15:24:11.683639+00	2026-08-05 15:24:11.949442+00
9d68a437-4f37-4213-822f-c5babaf79822	\N	User	\N	\N	+9198msg8mcnl	\N	end_user	active	t	2026-08-05 15:24:16.8212+00	2026-08-05 15:24:16.304376+00	2026-08-05 15:24:16.8212+00
8f3769a0-51a7-4bb1-93b0-836742c705b2	\N	User	\N	\N	+919812345678	\N	end_user	active	t	2026-08-05 07:04:21.029878+00	2026-08-05 04:02:44.230314+00	2026-08-05 07:04:21.029878+00
b0422680-a14b-46b5-aa9d-d9d226b3a071	\N	User	\N	\N	+9197msg8mez9	\N	end_user	active	t	2026-08-05 15:24:17.854455+00	2026-08-05 15:24:17.574002+00	2026-08-05 15:24:17.854455+00
6b185805-10cb-4f1a-9e15-3168dc691745	\N	User	\N	\N	+9198msfwie6f	\N	end_user	active	t	2026-08-05 09:45:17.838756+00	2026-08-05 09:45:17.217418+00	2026-08-05 09:45:17.838756+00
b78a2599-3f86-49da-9570-4d094ab240e7	\N	User	\N	\N	+9198msfwin6d	\N	end_user	active	t	2026-08-05 09:45:29.966549+00	2026-08-05 09:45:29.376758+00	2026-08-05 09:45:29.966549+00
4c4b64db-a7b1-40cf-98cb-357738726bc7	\N	User	\N	\N	+9198msfwj7k3	\N	end_user	active	t	2026-08-05 09:45:55.583349+00	2026-08-05 09:45:54.875473+00	2026-08-05 09:45:55.583349+00
d3b8e72c-44b9-4d1c-aae9-34648e47dc24	\N	User	\N	\N	+9198msg8mg41	\N	end_user	active	t	2026-08-05 15:24:19.285661+00	2026-08-05 15:24:18.996886+00	2026-08-05 15:24:19.285661+00
f5a61371-a191-4bfe-9659-1a05b788696b	\N	Ayesha	Khan	\N	+9193msgwevf2	\N	end_user	active	t	2026-08-06 02:30:17.281572+00	2026-08-06 02:30:17.007011+00	2026-08-06 02:30:17.408074+00
60f50480-cbe7-45b2-b94a-462ddc882514	\N	User	\N	\N	+9198msfxzsij	\N	end_user	active	t	2026-08-05 10:26:46.693547+00	2026-08-05 10:26:46.214767+00	2026-08-05 10:26:46.693547+00
5b90a2de-8e41-493d-8311-e21b2e27a452	\N	User	\N	\N	+9198msfxzzwn	\N	end_user	active	t	2026-08-05 10:26:56.011192+00	2026-08-05 10:26:55.6375+00	2026-08-05 10:26:56.011192+00
a36f9544-213a-4594-887d-680b70dd32fb	\N	User	\N	\N	+9198msfy0234	\N	end_user	active	t	2026-08-05 10:27:01.821167+00	2026-08-05 10:27:01.228154+00	2026-08-05 10:27:01.821167+00
3f591c6a-5509-45f9-a2e5-050be735735a	\N	Ahmed	Ali	\N	+9194msgwevf2	\N	end_user	active	t	2026-08-06 02:30:16.893757+00	2026-08-06 02:30:16.542096+00	2026-08-06 02:30:17.809812+00
d45844b4-81d5-448a-9e5b-549832b07407	\N	User	\N	\N	+9198msg8mpxd	\N	end_user	active	t	2026-08-05 15:24:32.453143+00	2026-08-05 15:24:32.023255+00	2026-08-05 15:24:32.453143+00
b9a9e0e7-72fd-4eef-9c0b-4ee5c0158432	\N	User	\N	\N	8004362634 	\N	end_user	active	t	2026-08-05 10:59:54.305844+00	2026-08-05 10:59:37.829504+00	2026-08-05 10:59:54.305844+00
23d5ef6e-0ae5-4356-8387-da764ecd1b7a	\N	User	\N	\N	+9196msg8msn8	\N	end_user	active	t	2026-08-05 15:24:35.528579+00	2026-08-05 15:24:35.233382+00	2026-08-05 15:24:35.528579+00
bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	\N	User	\N	\N	+9197msfznc78	\N	end_user	active	t	2026-08-05 11:13:05.894137+00	2026-08-05 11:13:05.144648+00	2026-08-05 11:13:05.894137+00
624934b7-aa0d-4f5f-9273-5698f83ac494	\N	User	\N	\N	+9197msfznniw	\N	end_user	active	t	2026-08-05 11:13:19.83209+00	2026-08-05 11:13:19.372782+00	2026-08-05 11:13:19.83209+00
2b1e1113-1628-49d1-be26-eff461ad7395	\N	User	\N	\N	+9197msfznud0	\N	end_user	active	t	2026-08-05 11:13:28.104802+00	2026-08-05 11:13:27.769748+00	2026-08-05 11:13:28.104802+00
c87d0759-ca5d-45db-b827-62210ce3b125	\N	User	\N	\N	+9197msg07k44	\N	end_user	active	t	2026-08-05 11:28:49.80432+00	2026-08-05 11:28:48.692053+00	2026-08-05 11:28:49.80432+00
fb7f5234-b6df-4a37-99c3-1adeae58416c	\N	User	\N	\N	+9197msg07uct	\N	end_user	active	t	2026-08-05 11:29:03.988556+00	2026-08-05 11:29:02.637223+00	2026-08-05 11:29:03.988556+00
36abc252-b881-46f8-add5-7549fcf1c02c	\N	User	\N	\N	+9197msg08e73	\N	end_user	active	t	2026-08-05 11:29:29.155956+00	2026-08-05 11:29:27.938253+00	2026-08-05 11:29:29.155956+00
318ed88a-c7bf-4ab7-b73a-85007e92a400	\N	User	\N	\N	+9197msg36e58	\N	end_user	active	t	2026-08-05 12:51:53.695677+00	2026-08-05 12:51:52.741126+00	2026-08-05 12:51:53.695677+00
61c7677e-2d35-423c-9088-77f26fd210ec	\N	User	\N	\N	+9197msg36tua	\N	end_user	active	t	2026-08-05 12:52:13.982154+00	2026-08-05 12:52:13.033675+00	2026-08-05 12:52:13.982154+00
ef29ab34-0926-4d68-b3a8-f9972bb2a232	\N	User	\N	\N	+9197msg37cgf	\N	end_user	active	t	2026-08-05 12:52:37.514768+00	2026-08-05 12:52:36.747228+00	2026-08-05 12:52:37.514768+00
dc416aae-d920-4b18-a151-fd516b79bc27	\N	User	\N	\N	+9197msg37p24	\N	end_user	active	t	2026-08-05 12:52:53.857717+00	2026-08-05 12:52:53.112145+00	2026-08-05 12:52:53.857717+00
ba861ecb-15ed-4eb9-a10e-3162b7d25a5c	\N	User	\N	\N	+9198msg37s1n	\N	end_user	active	t	2026-08-05 12:53:03.67776+00	2026-08-05 12:53:02.274906+00	2026-08-05 12:53:03.67776+00
ae149dc6-9ae0-4d9c-bc7f-25002b7a3761	\N	User	\N	\N	+9198msg37z4m	\N	end_user	active	t	2026-08-05 12:53:06.551716+00	2026-08-05 12:53:05.951179+00	2026-08-05 12:53:06.551716+00
571b5cef-8904-4a2b-bbeb-aae3a5dab145	\N	User	\N	\N	+919977665544	\N	end_user	active	t	2026-08-05 13:05:10.54758+00	2026-08-05 13:05:10.076298+00	2026-08-05 13:05:10.54758+00
1993fb25-6147-4b5d-bb36-88f756254fd6	\N	User	\N	\N	+9196msg8ly3t	\N	end_user	active	t	2026-08-05 15:23:56.18928+00	2026-08-05 15:23:55.860975+00	2026-08-05 15:23:56.18928+00
e576df13-6cd8-44a2-be61-44cb945bc25a	\N	User	\N	\N	+9195msg8msn8	\N	end_user	active	t	2026-08-05 15:24:35.944615+00	2026-08-05 15:24:35.645172+00	2026-08-05 15:24:35.944615+00
190b3097-f5a8-4ffa-b684-b8c6e77e4121	\N	User	\N	\N	+9198msg8v32f	\N	end_user	active	t	2026-08-05 15:31:10.965855+00	2026-08-05 15:31:10.27742+00	2026-08-05 15:31:10.965855+00
98b38f18-ee4b-459f-b9cd-ddaf62d1f6da	\N	User	\N	\N	+9197msg8vaiw	\N	end_user	active	t	2026-08-05 15:31:12.963536+00	2026-08-05 15:31:12.098755+00	2026-08-05 15:31:12.963536+00
05ae4bc0-b60c-4abd-b963-794677dcf06c	\N	User	\N	\N	+9196msg8vt6v	\N	end_user	active	t	2026-08-05 15:31:38.218834+00	2026-08-05 15:31:37.216281+00	2026-08-05 15:31:38.218834+00
59296eac-cc9d-44d1-913d-a5ef3365343c	\N	User	\N	\N	+9195msg8vt6v	\N	end_user	active	t	2026-08-05 15:31:39.469477+00	2026-08-05 15:31:38.536762+00	2026-08-05 15:31:39.469477+00
44edbe9e-2762-4722-bac2-b9731acd35b7	\N	User	\N	\N	+9196msg8wbd9	\N	end_user	active	t	2026-08-05 15:31:59.786201+00	2026-08-05 15:31:59.458623+00	2026-08-05 15:31:59.786201+00
fbd4b51b-493b-429d-a938-94354ce49c63	\N	User	\N	\N	+9195msg8wbd9	\N	end_user	active	t	2026-08-05 15:32:00.203757+00	2026-08-05 15:31:59.893978+00	2026-08-05 15:32:00.203757+00
8412df15-3a96-45f4-b129-f82489d85111	\N	User	\N	\N	+9198msg8wivz	\N	end_user	active	t	2026-08-05 15:32:13.342663+00	2026-08-05 15:32:12.493756+00	2026-08-05 15:32:13.342663+00
7ef79457-71f5-4e8c-bb17-fee5ba9da51d	\N	User	\N	\N	+9197msg8wmnr	\N	end_user	active	t	2026-08-05 15:32:14.591878+00	2026-08-05 15:32:14.266758+00	2026-08-05 15:32:14.591878+00
a8ba3347-742a-4523-aed8-77c774142345	\N	User	\N	\N	+9196msg8wpcw	\N	end_user	active	t	2026-08-05 15:32:17.961103+00	2026-08-05 15:32:17.652748+00	2026-08-05 15:32:17.961103+00
3d8c7d31-67c4-4023-b401-4ac046cf56ac	\N	User	\N	\N	+9195msg8wpcw	\N	end_user	active	t	2026-08-05 15:32:18.436126+00	2026-08-05 15:32:18.15462+00	2026-08-05 15:32:18.436126+00
fd039e52-629b-489a-b445-3003be85cb8d	\N	User	\N	\N	+9198msg8ws3m	\N	end_user	active	t	2026-08-05 15:32:21.772467+00	2026-08-05 15:32:21.467762+00	2026-08-05 15:32:21.772467+00
6a38eeb9-c8f8-4c02-874a-f365364bd4ff	\N	User	\N	\N	+9198msgwf2vt	\N	end_user	active	t	2026-08-06 02:30:28.994311+00	2026-08-06 02:30:28.443766+00	2026-08-06 02:30:28.994311+00
46f8f2e6-f83f-4a03-9c6c-684a91372144	\N	User	\N	aaquib4u@gmail.com	\N	\N	end_user	active	t	2026-08-06 02:15:42.220453+00	2026-08-05 07:23:00.786809+00	2026-08-06 02:15:42.220453+00
6a62dd3b-10b2-44fa-aed4-320d1685025f	\N	User	\N	\N	8004362634	\N	end_user	active	t	2026-08-06 02:19:03.45985+00	2026-08-05 06:51:07.789973+00	2026-08-06 02:19:03.45985+00
e2fd25fb-510b-4af5-a453-84ab5a69cf21	\N	User	\N	\N	+9194msgwe8a0	\N	end_user	active	t	2026-08-06 02:29:46.94759+00	2026-08-06 02:29:46.636754+00	2026-08-06 02:29:46.94759+00
f1d17cc9-15ee-4758-846e-e01e49b8779a	\N	User	\N	\N	+9193msgwe8a0	\N	end_user	active	t	2026-08-06 02:29:47.339254+00	2026-08-06 02:29:47.060591+00	2026-08-06 02:29:47.339254+00
8b6fae7c-974a-4d6e-9221-f37cf6a97469	\N	User	\N	\N	+9194msgwef9o	\N	end_user	active	t	2026-08-06 02:29:55.927754+00	2026-08-06 02:29:55.620584+00	2026-08-06 02:29:55.927754+00
4513fbdc-3de8-44e2-997a-89b1fa1aa4fd	\N	User	\N	\N	+9193msgwef9o	\N	end_user	active	t	2026-08-06 02:29:56.314141+00	2026-08-06 02:29:56.036834+00	2026-08-06 02:29:56.314141+00
d4e10fc0-e272-4867-81cd-567a0e84cfdf	\N	User	\N	\N	+9195msgwf87c	\N	end_user	active	t	2026-08-06 02:30:33.846293+00	2026-08-06 02:30:33.559838+00	2026-08-06 02:30:33.846293+00
3ea1debd-d1b1-4f7c-8ad8-c38b3b9066a2	\N	User	\N	\N	+9198msgwfayi	\N	end_user	active	t	2026-08-06 02:30:37.001594+00	2026-08-06 02:30:36.721584+00	2026-08-06 02:30:37.001594+00
15628c01-d0a0-422c-95b2-dcc978ad6fa1	\N	Ayesha	Khan	\N	+9193msgwf5lh	\N	end_user	active	t	2026-08-06 02:30:30.420759+00	2026-08-06 02:30:30.092579+00	2026-08-06 02:30:30.530153+00
6c982b06-1aca-4977-b319-191e16fc4de6	\N	Ahmed	Ali	\N	+9194msgwf5lh	\N	end_user	active	t	2026-08-06 02:30:29.987813+00	2026-08-06 02:30:29.686318+00	2026-08-06 02:30:30.869752+00
2d150870-1d4e-42e0-863c-0bad5782141e	\N	User	\N	\N	+9196msgwf87c	\N	end_user	active	t	2026-08-06 02:30:33.438596+00	2026-08-06 02:30:33.121363+00	2026-08-06 02:30:33.438596+00
5aa1f3bc-0de4-4093-ac1e-3859b13929d2	\N	User	\N	\N	+9197msgwfct3	\N	end_user	active	t	2026-08-06 02:30:39.440386+00	2026-08-06 02:30:39.140852+00	2026-08-06 02:30:39.440386+00
36615d5a-0131-4c21-98e3-956ceca31d48	\N	User	\N	\N	+919988776655	\N	end_user	active	t	2026-08-06 02:31:46.852363+00	2026-08-05 10:57:30.450761+00	2026-08-06 02:31:46.852363+00
97ad09c8-7854-4467-b96b-ceb2b390c0ce	\N	User	\N	notanemail	\N	\N	end_user	active	t	2026-08-06 06:27:51.613725+00	2026-08-06 06:27:27.202237+00	2026-08-06 06:27:51.613725+00
3f67a03d-221d-4f35-aa23-655ed8dbc56d	\N	User	\N	seconduser@example.com	\N	\N	end_user	pending_verification	t	\N	2026-08-06 06:29:15.870804+00	2026-08-06 06:29:15.870804+00
1e57d93c-53e2-4f0b-92e0-944de0c43daa	\N	User	\N	\N	9876543210	\N	end_user	active	t	2026-08-06 06:30:23.547368+00	2026-08-06 06:30:13.17091+00	2026-08-06 06:30:23.547368+00
f6d46263-407d-429f-aabc-f9e3c7b6aed3	\N	User	\N	\N	+9192msh51gg1	\N	end_user	active	t	2026-08-06 06:31:47.45335+00	2026-08-06 06:31:47.136254+00	2026-08-06 06:31:47.45335+00
4758c076-09d2-42d8-88cc-cce435637c32	\N	User	\N	\N	+9191msh51gg1	\N	end_user	active	t	2026-08-06 06:31:47.866023+00	2026-08-06 06:31:47.563772+00	2026-08-06 06:31:47.866023+00
59361f8d-559c-4874-9324-4d19418db3ea	\N	User	\N	\N	+9190msh51gg1	\N	end_user	active	t	2026-08-06 06:31:48.514823+00	2026-08-06 06:31:48.216983+00	2026-08-06 06:31:48.514823+00
5ad80524-52fe-43f5-b245-2a7ae49a92cf	\N	User	\N	\N	+9192msh51oko	\N	end_user	active	t	2026-08-06 06:31:58.020762+00	2026-08-06 06:31:57.705807+00	2026-08-06 06:31:58.020762+00
4c6ae7b3-0be7-4cd9-9c2f-495b296b66e0	\N	User	\N	\N	+9191msh51oko	\N	end_user	active	t	2026-08-06 06:31:58.410255+00	2026-08-06 06:31:58.137756+00	2026-08-06 06:31:58.410255+00
3a87cada-81bd-4de7-89dd-d9d1150bfada	\N	User	\N	\N	+9190msh51oko	\N	end_user	active	t	2026-08-06 06:31:59.034846+00	2026-08-06 06:31:58.738479+00	2026-08-06 06:31:59.034846+00
6914b9da-19a1-48d7-bccb-a39a08216f7c	\N	User	\N	\N	+9192msh51vm4	\N	end_user	active	t	2026-08-06 06:32:07.124668+00	2026-08-06 06:32:06.811893+00	2026-08-06 06:32:07.124668+00
12387821-8e7e-402f-9291-8f1fbadbce1e	\N	User	\N	\N	+9191msh51vm4	\N	end_user	active	t	2026-08-06 06:32:07.525951+00	2026-08-06 06:32:07.248861+00	2026-08-06 06:32:07.525951+00
b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	\N	Aaquib	khan	\N	+918004362634	\N	end_user	active	t	2026-08-06 07:28:09.757425+00	2026-08-05 13:05:31.969761+00	2026-08-06 07:28:09.757425+00
886d75e0-e090-4177-a6d8-570db8b1208c	\N	User	\N	8004362634	7007708213	\N	end_user	active	t	2026-08-06 07:42:04.803565+00	2026-08-05 17:35:09.894677+00	2026-08-06 07:42:04.803565+00
01e2b9b4-410e-44f6-a9a0-7723c7f96ff5	\N	User	\N	\N	+9192msh5267a	\N	end_user	active	t	2026-08-06 06:32:20.977176+00	2026-08-06 06:32:20.617758+00	2026-08-06 06:32:20.977176+00
d31b3330-980a-4d38-bf4d-c221a5033bda	\N	User	\N	\N	+9191msh5267a	\N	end_user	active	t	2026-08-06 06:32:21.456734+00	2026-08-06 06:32:21.172106+00	2026-08-06 06:32:21.456734+00
3d9b43f7-0071-4d41-90e4-b911c4447dae	\N	User	\N	\N	+9190msh5267a	\N	end_user	active	t	2026-08-06 06:32:22.131883+00	2026-08-06 06:32:21.834385+00	2026-08-06 06:32:22.131883+00
2a224da9-7f89-435d-bb73-bf545c2d6bdf	\N	User	\N	\N	+9198msh52900	\N	end_user	active	t	2026-08-06 06:32:27.776779+00	2026-08-06 06:32:27.038854+00	2026-08-06 06:32:27.776779+00
35852f38-c0a3-4f81-8b41-0ffd689ac6dd	\N	User	\N	\N	+9196msh52cex	\N	end_user	active	t	2026-08-06 06:32:28.84776+00	2026-08-06 06:32:28.548333+00	2026-08-06 06:32:28.84776+00
959de7e4-5ec1-4c46-89d4-aec4a0b5c39c	\N	User	\N	\N	+9195msh52cex	\N	end_user	active	t	2026-08-06 06:32:29.211533+00	2026-08-06 06:32:28.94914+00	2026-08-06 06:32:29.211533+00
f3aa32d8-e43d-49ff-928d-a5c32e4a2576	\N	User	\N	\N	+918788776655	\N	end_user	active	t	2026-08-06 06:35:35.014929+00	2026-08-06 06:35:34.710153+00	2026-08-06 06:35:35.014929+00
08b05119-1ab8-4da6-aaa4-691d8b9d62e6	\N	Ayesha	Khan	\N	+9193msh52f08	\N	end_user	active	t	2026-08-06 06:32:32.598414+00	2026-08-06 06:32:32.327746+00	2026-08-06 06:32:32.705764+00
679a9cbd-c4bc-4326-a754-e6d09a55b010	\N	Ahmed	Ali	\N	+9194msh52f08	\N	end_user	active	t	2026-08-06 06:32:32.209639+00	2026-08-06 06:32:31.925763+00	2026-08-06 06:32:33.027359+00
3033d43d-8034-498f-b48d-5c549e8f97fb	\N	User	\N	\N	+9198msh52hht	\N	end_user	active	t	2026-08-06 06:32:35.412763+00	2026-08-06 06:32:35.100082+00	2026-08-06 06:32:35.412763+00
3c27e34d-8df3-456a-8b12-079170f1f55b	\N	User	\N	\N	+9197msh52jd3	\N	end_user	active	t	2026-08-06 06:32:37.833664+00	2026-08-06 06:32:37.519381+00	2026-08-06 06:32:37.833664+00
d1ef1fb4-c2d5-468d-8a4f-d1123278f72b	\N	User	\N	\N	+9198msh538x0	\N	end_user	active	t	2026-08-06 06:33:13.505665+00	2026-08-06 06:33:12.730828+00	2026-08-06 06:33:13.505665+00
e81e56cc-db91-4ddb-b1e8-530510958e6c	\N	User	\N	\N	+9192msh53bth	\N	end_user	active	t	2026-08-06 06:33:14.972271+00	2026-08-06 06:33:14.54077+00	2026-08-06 06:33:14.972271+00
25634a36-337f-4d14-a96d-1a843df8614e	\N	User	\N	\N	+9191msh53bth	\N	end_user	active	t	2026-08-06 06:33:15.544566+00	2026-08-06 06:33:15.18718+00	2026-08-06 06:33:15.544566+00
6003b134-d829-420c-acd5-b3f86ffbbc22	\N	User	\N	\N	+9190msh53bth	\N	end_user	active	t	2026-08-06 06:33:16.848223+00	2026-08-06 06:33:16.493787+00	2026-08-06 06:33:16.848223+00
1c16cafc-57a6-4651-b25f-a364716b322e	\N	User	\N	\N	+9196msh53eua	\N	end_user	active	t	2026-08-06 06:33:18.593752+00	2026-08-06 06:33:18.303753+00	2026-08-06 06:33:18.593752+00
eebc8df0-9557-4dbe-9644-ebe4a13b931c	\N	User	\N	\N	+9195msh53eua	\N	end_user	active	t	2026-08-06 06:33:18.989269+00	2026-08-06 06:33:18.700441+00	2026-08-06 06:33:18.989269+00
58e3af63-5f33-49a0-9089-42509c07464a	\N	User	\N	\N	+9198msh6wzva	\N	end_user	active	t	2026-08-06 07:24:22.022783+00	2026-08-06 07:24:21.365557+00	2026-08-06 07:24:22.022783+00
02b1c183-6a2e-4088-be1a-0ad7ef1c638c	\N	Ayesha	Khan	\N	+9193msh53htb	\N	end_user	active	t	2026-08-06 06:33:23.258056+00	2026-08-06 06:33:22.883878+00	2026-08-06 06:33:23.381956+00
6df70e40-bb74-457a-a687-5e470514447b	\N	Ahmed	Ali	\N	+9194msh53htb	\N	end_user	active	t	2026-08-06 06:33:22.684348+00	2026-08-06 06:33:22.365608+00	2026-08-06 06:33:23.855076+00
5fd98325-1ea1-44ab-904c-b7d9c64df81a	\N	User	\N	\N	+9198msh53l9e	\N	end_user	active	t	2026-08-06 06:33:27.026652+00	2026-08-06 06:33:26.684505+00	2026-08-06 06:33:27.026652+00
f87a94fc-f840-4b86-a2c5-1c32001d8a05	\N	User	\N	\N	+9197msh53ngj	\N	end_user	active	t	2026-08-06 06:33:29.784418+00	2026-08-06 06:33:29.481102+00	2026-08-06 06:33:29.784418+00
a9cd0b33-31db-4738-bc7c-a1b7158adf4a	\N	User	\N	\N	+9198msh53zdg	\N	end_user	active	t	2026-08-06 06:33:47.699985+00	2026-08-06 06:33:47.140709+00	2026-08-06 06:33:47.699985+00
b4b9d664-ccf9-4a6b-b29e-5b8ea54e8dd8	\N	User	\N	\N	+9196msh6x3d9	\N	end_user	active	t	2026-08-06 07:24:23.138637+00	2026-08-06 07:24:22.797261+00	2026-08-06 07:24:23.138637+00
6eb69aed-a13c-4ce9-a4de-3b2bdd84e2f7	\N	Ayesha	Khan	\N	+9193msh5421i	\N	end_user	active	t	2026-08-06 06:33:49.085963+00	2026-08-06 06:33:48.80651+00	2026-08-06 06:33:49.189479+00
287fea1f-a616-4b7f-82f8-fc0886dceda0	\N	Ahmed	Ali	\N	+9194msh5421i	\N	end_user	active	t	2026-08-06 06:33:48.691175+00	2026-08-06 06:33:48.384873+00	2026-08-06 06:33:49.567747+00
730aab59-18e5-4343-8ea5-20d21d417f9a	\N	User	\N	\N	+9192msh544q1	\N	end_user	active	t	2026-08-06 06:33:52.219748+00	2026-08-06 06:33:51.931766+00	2026-08-06 06:33:52.219748+00
b23ee7a2-7e56-495e-96b8-f1253aeaea36	\N	User	\N	\N	+9191msh544q1	\N	end_user	active	t	2026-08-06 06:33:52.839316+00	2026-08-06 06:33:52.432343+00	2026-08-06 06:33:52.839316+00
421ca638-b359-4990-8854-982f64dc2726	\N	User	\N	\N	+9190msh544q1	\N	end_user	active	t	2026-08-06 06:33:53.875762+00	2026-08-06 06:33:53.479168+00	2026-08-06 06:33:53.875762+00
7294e7cd-2388-4a10-9e3a-31f532b748ee	\N	User	\N	\N	+9196msh547eb	\N	end_user	active	t	2026-08-06 06:33:55.673758+00	2026-08-06 06:33:55.336753+00	2026-08-06 06:33:55.673758+00
d7c3fa7c-c268-4e5c-acec-0450571fdb18	\N	User	\N	\N	+9195msh547eb	\N	end_user	active	t	2026-08-06 06:33:56.068597+00	2026-08-06 06:33:55.782373+00	2026-08-06 06:33:56.068597+00
efe874e3-dc4c-4942-a44b-98f2a856525a	\N	User	\N	\N	+9198msh54abt	\N	end_user	active	t	2026-08-06 06:33:59.427937+00	2026-08-06 06:33:59.157758+00	2026-08-06 06:33:59.427937+00
ccef9aeb-4e3c-4923-bb15-f364e42fa1ac	\N	User	\N	\N	+9197msh54c54	\N	end_user	active	t	2026-08-06 06:34:01.901256+00	2026-08-06 06:34:01.534766+00	2026-08-06 06:34:01.901256+00
649308eb-cc8e-4702-b6be-f823419073cc	\N	User	\N	notarealemail	\N	\N	end_user	active	t	2026-08-06 06:34:02.062443+00	2026-08-06 06:33:21.105733+00	2026-08-06 06:34:02.062443+00
bba02b1e-aae7-4873-9983-7a8196db808b	\N	User	\N	\N	+918988776655	\N	end_user	active	t	2026-08-06 06:35:34.596652+00	2026-08-06 06:35:34.325708+00	2026-08-06 06:35:34.596652+00
c7fa5fb4-0bb7-4944-ad43-2feec28bd2b7	\N	User	\N	\N	+9195msh6x3d9	\N	end_user	active	t	2026-08-06 07:24:23.570343+00	2026-08-06 07:24:23.261786+00	2026-08-06 07:24:23.570343+00
f20698bd-7049-4b40-8d92-c62216637198	\N	User	\N	\N	+9192msh6xwrz	\N	end_user	active	t	2026-08-06 07:25:01.216372+00	2026-08-06 07:25:00.886083+00	2026-08-06 07:25:01.216372+00
150f70a6-62b8-44b8-95bb-3e78bbd916be	\N	Ayesha	Khan	\N	+9193msh6x6ml	\N	end_user	active	t	2026-08-06 07:24:27.772579+00	2026-08-06 07:24:27.475516+00	2026-08-06 07:24:27.878119+00
7607d532-01cb-4685-93d0-019c266c06ca	\N	Ahmed	Ali	\N	+9194msh6x6ml	\N	end_user	active	t	2026-08-06 07:24:27.312306+00	2026-08-06 07:24:26.993238+00	2026-08-06 07:24:28.32528+00
b3e94172-8013-4cdc-b429-33dd88309863	\N	User	\N	\N	+9192msh6x9hq	\N	end_user	active	t	2026-08-06 07:24:31.16227+00	2026-08-06 07:24:30.828763+00	2026-08-06 07:24:31.16227+00
54a1c8d5-f4c4-4726-bb69-eb07271a6a8b	\N	User	\N	\N	+9191msh6x9hq	\N	end_user	active	t	2026-08-06 07:24:31.618203+00	2026-08-06 07:24:31.284416+00	2026-08-06 07:24:31.618203+00
f0288664-74a6-4047-9db1-a266f0bd5811	\N	User	\N	\N	+9190msh6x9hq	\N	end_user	active	t	2026-08-06 07:24:32.694761+00	2026-08-06 07:24:32.346767+00	2026-08-06 07:24:32.694761+00
639ff8c2-a929-4dbd-9f14-e19826bf1da3	\N	User	\N	\N	+9197msh6xc3p	\N	end_user	active	t	2026-08-06 07:24:34.394206+00	2026-08-06 07:24:34.095763+00	2026-08-06 07:24:34.394206+00
744043a1-ee52-4e5d-a5d7-91221762e13a	\N	User	\N	\N	+9198msh6xdai	\N	end_user	active	t	2026-08-06 07:24:36.00182+00	2026-08-06 07:24:35.690759+00	2026-08-06 07:24:36.00182+00
b53dcfda-741c-4278-a232-6c0f18ad2805	\N	User	\N	\N	+9191msh6xwrz	\N	end_user	active	t	2026-08-06 07:25:01.722469+00	2026-08-06 07:25:01.360024+00	2026-08-06 07:25:01.722469+00
06b18ccf-7604-4247-b3ef-4b3dbf0afebf	\N	Ayesha	Khan	\N	+9193msh6xo0q	\N	end_user	active	t	2026-08-06 07:24:50.479085+00	2026-08-06 07:24:50.172037+00	2026-08-06 07:24:50.634868+00
86061e0a-d9e9-4fd4-91cc-f4113ffece92	\N	Ahmed	Ali	\N	+9194msh6xo0q	\N	end_user	active	t	2026-08-06 07:24:50.050361+00	2026-08-06 07:24:49.700045+00	2026-08-06 07:24:50.980524+00
af87f426-9540-4a3f-9796-61a215efc6c1	\N	User	\N	\N	+9198msh6xraz	\N	end_user	active	t	2026-08-06 07:24:56.292418+00	2026-08-06 07:24:55.705944+00	2026-08-06 07:24:56.292418+00
ddcd3ad5-423b-436e-b921-4322d3397be4	\N	User	\N	\N	+9196msh6xts0	\N	end_user	active	t	2026-08-06 07:24:57.37937+00	2026-08-06 07:24:57.027318+00	2026-08-06 07:24:57.37937+00
cf8b1225-10c8-42b4-81a9-6dc603b4b753	\N	User	\N	\N	+9195msh6xts0	\N	end_user	active	t	2026-08-06 07:24:57.781827+00	2026-08-06 07:24:57.490537+00	2026-08-06 07:24:57.781827+00
5461fdf8-9481-4066-8c0b-5470b4184463	\N	User	\N	\N	+9190msh6xwrz	\N	end_user	active	t	2026-08-06 07:25:02.71804+00	2026-08-06 07:25:02.213225+00	2026-08-06 07:25:02.71804+00
d1ced440-d263-4434-a49f-2817345f0c27	\N	User	\N	\N	+9198msh6y0cc	\N	end_user	active	t	2026-08-06 07:25:05.87722+00	2026-08-06 07:25:05.58343+00	2026-08-06 07:25:05.87722+00
56e227be-5f34-465e-b71c-9fb4ecd94d98	\N	User	\N	\N	+9197msh6y275	\N	end_user	active	t	2026-08-06 07:25:08.423084+00	2026-08-06 07:25:08.111143+00	2026-08-06 07:25:08.423084+00
c7329ca3-ba0b-44cb-a3b5-35291cad9718	\N	Ayesha	Khan	\N	+9193msh6yagx	\N	end_user	active	t	2026-08-06 07:25:20.063619+00	2026-08-06 07:25:19.637765+00	2026-08-06 07:25:20.274857+00
5380e05f-af41-420b-a86b-6661ba12fa65	\N	Ahmed	Ali	\N	+9194msh6yagx	\N	end_user	active	t	2026-08-06 07:25:19.434611+00	2026-08-06 07:25:18.983646+00	2026-08-06 07:25:20.677083+00
19d0db83-6560-4103-ac51-6d11e51c4d76	\N	User	\N	\N	+9196msh6ywkg	\N	end_user	active	t	2026-08-06 07:25:47.63844+00	2026-08-06 07:25:47.30236+00	2026-08-06 07:25:47.63844+00
80208c67-25c3-4c79-8fd5-90b2d0440bba	\N	Ayesha	Khan	\N	+9193msh6yrcd	\N	end_user	active	t	2026-08-06 07:25:41.288455+00	2026-08-06 07:25:41.008166+00	2026-08-06 07:25:41.417765+00
33ffbd02-a0bc-449f-9d2f-2b0659b1dedb	\N	Ahmed	Ali	\N	+9194msh6yrcd	\N	end_user	active	t	2026-08-06 07:25:40.89126+00	2026-08-06 07:25:40.52963+00	2026-08-06 07:25:41.894454+00
30a21658-542f-4803-a13c-651be1e25909	\N	User	\N	\N	+9192msh6yu91	\N	end_user	active	t	2026-08-06 07:25:44.663506+00	2026-08-06 07:25:44.310752+00	2026-08-06 07:25:44.663506+00
afc78693-4d5d-42f7-a8aa-d1f4bdbbec6d	\N	User	\N	\N	+9191msh6yu91	\N	end_user	active	t	2026-08-06 07:25:45.084385+00	2026-08-06 07:25:44.766757+00	2026-08-06 07:25:45.084385+00
03877811-6a4b-474a-9eb7-14e02ce491fc	\N	User	\N	\N	+9190msh6yu91	\N	end_user	active	t	2026-08-06 07:25:45.857665+00	2026-08-06 07:25:45.563906+00	2026-08-06 07:25:45.857665+00
6ab6b1c0-1cdc-4315-8d05-e38622db9cff	\N	User	\N	\N	+9195msh6ywkg	\N	end_user	active	t	2026-08-06 07:25:48.173516+00	2026-08-06 07:25:47.818313+00	2026-08-06 07:25:48.173516+00
071354b7-e831-47f6-ac76-b927e48c0d23	\N	User	\N	\N	+9198msh6yzph	\N	end_user	active	t	2026-08-06 07:25:53.796122+00	2026-08-06 07:25:53.247983+00	2026-08-06 07:25:53.796122+00
16e257e0-1991-4ddb-ba66-1b2eb47f43dc	\N	User	\N	\N	+9198msh6z24r	\N	end_user	active	t	2026-08-06 07:25:54.777381+00	2026-08-06 07:25:54.459749+00	2026-08-06 07:25:54.777381+00
6a4d9674-6d2a-4be1-ab4c-213a45492132	\N	User	\N	\N	+9197msh6z40o	\N	end_user	active	t	2026-08-06 07:25:57.258831+00	2026-08-06 07:25:56.942427+00	2026-08-06 07:25:57.258831+00
afa30051-73b4-41e7-8b44-fe64122d74c6	\N	Ahmed	Ali	\N	+9194msh6zbqe	\N	end_user	active	t	2026-08-06 07:26:07.465566+00	2026-08-06 07:26:07.135502+00	2026-08-06 07:26:08.463265+00
519b53fe-56c8-48ce-bd17-3e3bef8aef71	\N	Ayesha	Khan	\N	+9193msh6zbqe	\N	end_user	active	t	2026-08-06 07:26:07.930044+00	2026-08-06 07:26:07.620194+00	2026-08-06 07:26:08.088449+00
8dce8e30-e3b1-4588-816e-60891d8a3202	\N	Ahmed	Ali	\N	+9194msh708vs	\N	end_user	active	t	2026-08-06 07:26:50.306994+00	2026-08-06 07:26:49.993751+00	2026-08-06 07:26:51.327763+00
a7d3612d-d0e9-4807-bdef-60f52458154c	\N	Ayesha	Khan	\N	+9193msh708vs	\N	end_user	active	t	2026-08-06 07:26:50.719044+00	2026-08-06 07:26:50.428452+00	2026-08-06 07:26:50.876854+00
eaf120d8-bd47-43fc-aa4b-975400c5f579	\N	Ahmed	Ali	\N	+9194msh70inh	\N	end_user	active	t	2026-08-06 07:27:03.165403+00	2026-08-06 07:27:02.723927+00	2026-08-06 07:27:04.191739+00
355ba637-df1c-4775-8a5b-96c70b9a957a	\N	Ayesha	Khan	\N	+9193msh70inh	\N	end_user	active	t	2026-08-06 07:27:03.601892+00	2026-08-06 07:27:03.288759+00	2026-08-06 07:27:03.738544+00
7eb32340-5dc9-4180-ae5f-626b2090eb41	\N	User	\N	\N	+9196msh70lmv	\N	end_user	active	t	2026-08-06 07:27:06.740144+00	2026-08-06 07:27:06.423254+00	2026-08-06 07:27:06.740144+00
367fdce2-dc07-4945-af3f-22a1305b03e0	\N	User	\N	\N	+9195msh70lmv	\N	end_user	active	t	2026-08-06 07:27:07.143191+00	2026-08-06 07:27:06.856981+00	2026-08-06 07:27:07.143191+00
f7f6622a-e693-48e5-a4c4-e3bb66f119b6	\N	User	\N	\N	+9198msh70of5	\N	end_user	active	t	2026-08-06 07:27:12.463545+00	2026-08-06 07:27:11.9354+00	2026-08-06 07:27:12.463545+00
d91dd487-28c3-4f03-8206-3d7bc12e0765	\N	User	\N	\N	+9192msh70qyd	\N	end_user	active	t	2026-08-06 07:27:13.751741+00	2026-08-06 07:27:13.382783+00	2026-08-06 07:27:13.751741+00
b4163d69-9347-4fb5-8edf-0a58dedfd768	\N	User	\N	\N	+9191msh70qyd	\N	end_user	active	t	2026-08-06 07:27:14.291765+00	2026-08-06 07:27:13.913763+00	2026-08-06 07:27:14.291765+00
7e3edba5-5360-4010-85d2-cc7e9e008b1d	\N	User	\N	\N	+9190msh70qyd	\N	end_user	active	t	2026-08-06 07:27:15.003587+00	2026-08-06 07:27:14.713179+00	2026-08-06 07:27:15.003587+00
b521ee31-dd05-4b61-8902-a7d8e3359c87	\N	User	\N	\N	+9198msh70tc1	\N	end_user	active	t	2026-08-06 07:27:17.076207+00	2026-08-06 07:27:16.630116+00	2026-08-06 07:27:17.076207+00
3b777f71-d8a8-4d5e-a3a5-9dbc0057b9ac	\N	User	\N	\N	+9197msh70wht	\N	end_user	active	t	2026-08-06 07:27:21.047259+00	2026-08-06 07:27:20.693979+00	2026-08-06 07:27:21.047259+00
08eb3e44-465f-45eb-965b-b6f56418ecdf	\N	User	\N	\N	+9188msh7fja7	\N	end_user	active	t	2026-08-06 07:38:43.751241+00	2026-08-06 07:38:43.376597+00	2026-08-06 07:38:43.751241+00
116d7e4c-e0b2-4591-ac73-e8918aaf3d91	\N	User	\N	\N	+9188msh7fpyv	\N	end_user	active	t	2026-08-06 07:38:52.376914+00	2026-08-06 07:38:51.979651+00	2026-08-06 07:38:52.376914+00
2f3e926f-0cbc-487f-bf08-9e1521cd4775	\N	User	\N	\N	+9188msh7g6ld	\N	end_user	active	t	2026-08-06 07:39:13.89149+00	2026-08-06 07:39:13.527535+00	2026-08-06 07:39:13.89149+00
778e0a0e-af86-42de-bc86-f9ce5f47c98e	\N	User	\N	\N	+9197msh7hkkz	\N	end_user	active	t	2026-08-06 07:40:18.82876+00	2026-08-06 07:40:18.405758+00	2026-08-06 07:40:18.82876+00
88e672cf-f466-4a22-b7c7-fabe8b127ee3	\N	Ayesha	Khan	\N	+9193msh7gemf	\N	end_user	active	t	2026-08-06 07:39:24.846678+00	2026-08-06 07:39:24.544723+00	2026-08-06 07:39:24.983282+00
30f4cca4-0969-4c6e-b6d6-4ee28bbb7221	\N	Ahmed	Ali	\N	+9194msh7gemf	\N	end_user	active	t	2026-08-06 07:39:24.388686+00	2026-08-06 07:39:23.995913+00	2026-08-06 07:39:25.55124+00
1df93849-4a6e-4842-807d-e5df6c457760	\N	User	\N	\N	+9198msh7ghuq	\N	end_user	active	t	2026-08-06 07:39:28.381158+00	2026-08-06 07:39:28.083159+00	2026-08-06 07:39:28.381158+00
3bd0bf00-d276-46c2-ae5b-11870c818ec5	\N	User	\N	\N	+9196msh7gk7k	\N	end_user	active	t	2026-08-06 07:39:31.679887+00	2026-08-06 07:39:31.275828+00	2026-08-06 07:39:31.679887+00
5a1c4da1-d9a0-4475-9c2b-5ab4b4335209	\N	User	\N	\N	+9195msh7gk7k	\N	end_user	active	t	2026-08-06 07:39:32.247277+00	2026-08-06 07:39:31.870515+00	2026-08-06 07:39:32.247277+00
7ea9daf4-0016-43c4-b811-70ec6b60254d	\N	User	\N	\N	+9192msh7gnje	\N	end_user	active	t	2026-08-06 07:39:36.075913+00	2026-08-06 07:39:35.660815+00	2026-08-06 07:39:36.075913+00
c3b43f87-73b1-435c-94a0-c45939b5ee02	\N	User	\N	\N	+9191msh7gnje	\N	end_user	active	t	2026-08-06 07:39:36.719208+00	2026-08-06 07:39:36.282194+00	2026-08-06 07:39:36.719208+00
34f33792-5b04-4538-821b-d889040be905	\N	User	\N	\N	+9190msh7gnje	\N	end_user	active	t	2026-08-06 07:39:37.642415+00	2026-08-06 07:39:37.316995+00	2026-08-06 07:39:37.642415+00
75ba8615-b5a8-4bb7-85c6-4e028e1f3359	\N	User	\N	\N	+9198msh7gquh	\N	end_user	active	t	2026-08-06 07:39:42.209969+00	2026-08-06 07:39:41.678874+00	2026-08-06 07:39:42.209969+00
ca5f760e-7b1d-46d9-b000-1d6041f494a5	\N	User	\N	\N	+9188msh7gtbd	\N	end_user	active	t	2026-08-06 07:39:43.34877+00	2026-08-06 07:39:43.021139+00	2026-08-06 07:39:43.34877+00
d95d19dd-5d82-4068-83c6-3683294a76df	\N	User	\N	\N	+9197msh7guqf	\N	end_user	active	t	2026-08-06 07:39:45.129738+00	2026-08-06 07:39:44.825233+00	2026-08-06 07:39:45.129738+00
010bb5b8-d47d-43d9-87e1-4cb2e927b635	\N	User	\N	\N	+9188msh7h557	\N	end_user	active	t	2026-08-06 07:39:58.57042+00	2026-08-06 07:39:58.245777+00	2026-08-06 07:39:58.57042+00
605f37bc-fb38-43e6-b3bc-11412f4a1724	\N	User	\N	\N	+9188msh7hzxu	\N	end_user	active	t	2026-08-06 07:40:38.828012+00	2026-08-06 07:40:38.371832+00	2026-08-06 07:40:38.828012+00
6e792cb8-9a1f-4c40-a825-985a1dd5b706	\N	Ayesha	Khan	\N	+9193msh7h6dr	\N	end_user	active	t	2026-08-06 07:40:00.66207+00	2026-08-06 07:40:00.336772+00	2026-08-06 07:40:00.833037+00
89f81735-a971-4f31-be35-afce72c93bfc	\N	Ahmed	Ali	\N	+9194msh7h6dr	\N	end_user	active	t	2026-08-06 07:40:00.207013+00	2026-08-06 07:39:59.878778+00	2026-08-06 07:40:01.321916+00
c118f901-1a69-4866-98b8-677f315742a1	\N	User	\N	\N	+9196msh7h9pf	\N	end_user	active	t	2026-08-06 07:40:04.619577+00	2026-08-06 07:40:04.328107+00	2026-08-06 07:40:04.619577+00
cf11c185-cff1-4c4c-a254-63c9cae16950	\N	User	\N	\N	+9195msh7h9pf	\N	end_user	active	t	2026-08-06 07:40:05.006083+00	2026-08-06 07:40:04.737758+00	2026-08-06 07:40:05.006083+00
77a4ff3b-0afa-4776-8504-a026984e3b14	\N	User	\N	\N	+9192msh7hdcv	\N	end_user	active	t	2026-08-06 07:40:09.36805+00	2026-08-06 07:40:08.976772+00	2026-08-06 07:40:09.36805+00
0a0ca69a-734a-464d-846d-03905795c51c	\N	User	\N	\N	+9191msh7hdcv	\N	end_user	active	t	2026-08-06 07:40:09.779509+00	2026-08-06 07:40:09.513026+00	2026-08-06 07:40:09.779509+00
7c008e59-0297-4961-9f2e-33ffde5fa520	\N	User	\N	\N	+9190msh7hdcv	\N	end_user	active	t	2026-08-06 07:40:10.504771+00	2026-08-06 07:40:10.188611+00	2026-08-06 07:40:10.504771+00
36163d7d-711d-4a3e-bc45-31eaeba1d21b	\N	User	\N	\N	+9198msh7hfuj	\N	end_user	active	t	2026-08-06 07:40:14.944055+00	2026-08-06 07:40:14.342259+00	2026-08-06 07:40:14.944055+00
68dc303d-4fe0-423a-a6cb-9383ff75a1da	\N	User	\N	\N	+9198msh7hilz	\N	end_user	active	t	2026-08-06 07:40:16.00499+00	2026-08-06 07:40:15.72329+00	2026-08-06 07:40:16.00499+00
087c71fc-5bd8-4fca-b1fc-0eb50342aeee	\N	User	\N	\N	+9196msh7i1lj	\N	end_user	active	t	2026-08-06 07:40:40.905362+00	2026-08-06 07:40:40.508273+00	2026-08-06 07:40:40.905362+00
9a619129-5447-45a7-b1a9-45ca14708e7b	\N	User	\N	\N	+9195msh7i1lj	\N	end_user	active	t	2026-08-06 07:40:41.428787+00	2026-08-06 07:40:41.072076+00	2026-08-06 07:40:41.428787+00
cbb5af08-507b-4eb2-b1e4-2c6d91f68187	\N	Ayesha	Khan	\N	+9193msh7i5i1	\N	end_user	active	t	2026-08-06 07:40:46.193052+00	2026-08-06 07:40:45.934957+00	2026-08-06 07:40:46.300183+00
7c916865-cac4-42be-a99b-c45e15e6845e	\N	Ahmed	Ali	\N	+9194msh7i5i1	\N	end_user	active	t	2026-08-06 07:40:45.7931+00	2026-08-06 07:40:45.494955+00	2026-08-06 07:40:46.625047+00
4c071db4-45a4-4caa-8fa7-8c1c783785e2	\N	User	\N	\N	+9198msh7i8da	\N	end_user	active	t	2026-08-06 07:40:52.162519+00	2026-08-06 07:40:51.631042+00	2026-08-06 07:40:52.162519+00
215f7372-6d92-40ec-9f9a-1879debb080d	\N	User	\N	\N	+9192msh7ibc6	\N	end_user	active	t	2026-08-06 07:40:53.192144+00	2026-08-06 07:40:52.879757+00	2026-08-06 07:40:53.192144+00
0270429b-5a36-466a-82f5-0dbe02c49821	\N	User	\N	\N	+9191msh7ibc6	\N	end_user	active	t	2026-08-06 07:40:53.604287+00	2026-08-06 07:40:53.336866+00	2026-08-06 07:40:53.604287+00
a4d79652-4ef8-40be-b7ab-ca04aaee390d	\N	User	\N	\N	+9190msh7ibc6	\N	end_user	active	t	2026-08-06 07:40:54.287755+00	2026-08-06 07:40:53.994759+00	2026-08-06 07:40:54.287755+00
68347b75-b32a-4bb4-9189-76fd0c9d4947	\N	User	\N	\N	+9198msh7idha	\N	end_user	active	t	2026-08-06 07:40:56.01414+00	2026-08-06 07:40:55.708942+00	2026-08-06 07:40:56.01414+00
c82e6b63-ac48-40f4-b8f3-0be99df54466	\N	User	\N	\N	+9197msh7ifdc	\N	end_user	active	t	2026-08-06 07:40:58.467821+00	2026-08-06 07:40:58.115805+00	2026-08-06 07:40:58.467821+00
\.


--
-- Data for Name: VerificationRequests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."VerificationRequests" ("VerificationId", "UserId", "DocType", "DocReference", "Status", "ReviewedBy", "ReviewedOn", "CreatedOn") FROM stdin;
a56f01d4-8a38-40d7-ab20-6ccef657b434	36615d5a-0131-4c21-98e3-956ceca31d48	aadhaar	1234-5678-9012	verified	\N	2026-08-05 13:05:09.808952+00	2026-08-05 13:01:29.603774+00
0f933259-c581-4265-b42e-d41433fa5a62	b8cda91a-1d2d-4a8e-afa0-e3e6d13d5358	aadhaar	1234432112344321	verified	\N	2026-08-05 18:26:37.528779+00	2026-08-05 18:18:30.297599+00
ca4dbd19-121c-4d32-9377-253361ccb53c	7ef79457-71f5-4e8c-bb17-fee5ba9da51d	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:42.63419+00	2026-08-05 15:32:15.130352+00
519f2387-e469-4c0d-9ec2-9a0a60789c85	b0422680-a14b-46b5-aa9d-d9d226b3a071	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:44.980967+00	2026-08-05 15:24:18.213641+00
82d3ccda-6f61-46db-9860-55dad68d9c87	dc416aae-d920-4b18-a151-fd516b79bc27	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:47.990229+00	2026-08-05 12:52:54.427886+00
be20eff6-b61f-4426-950a-cfa0b61e1668	ef29ab34-0926-4d68-b3a8-f9972bb2a232	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:51.908738+00	2026-08-05 12:52:38.156757+00
5c9a6b14-fde3-4093-815a-56f3748e8dcc	98b38f18-ee4b-459f-b9cd-ddaf62d1f6da	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:52.906534+00	2026-08-05 15:31:17.027739+00
8302eb52-de42-4b11-afb1-02a66952a849	61c7677e-2d35-423c-9088-77f26fd210ec	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:56.15359+00	2026-08-05 12:52:14.760762+00
c4be0381-5cb2-4bc0-9ac2-c2cafa216888	318ed88a-c7bf-4ab7-b73a-85007e92a400	aadhaar	1234-5678-9012	verified	\N	2026-08-05 18:26:57.546354+00	2026-08-05 12:51:54.626025+00
07f59225-6d7e-4a6b-9df6-c027f3152d42	36abc252-b881-46f8-add5-7549fcf1c02c	aadhaar	1234-5678-9012	rejected	\N	2026-08-05 18:26:59.14991+00	2026-08-05 11:29:30.46938+00
d6e9ebf4-eff5-4baa-9a01-fe5b8a2d40bd	624934b7-aa0d-4f5f-9273-5698f83ac494	aadhaar	1234-5678-9012	rejected	\N	2026-08-05 18:27:00.435349+00	2026-08-05 11:13:20.706758+00
7fa44c13-7893-4132-8063-c4f890a1f1bc	bbfc0103-145b-48cf-a30f-5fe1cd9c8d73	aadhaar	1234-5678-9012	rejected	\N	2026-08-05 18:27:01.669567+00	2026-08-05 11:13:07.546504+00
31a584e4-50d6-4476-9df5-cdad71e01705	5aa1f3bc-0de4-4093-ac1e-3859b13929d2	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 02:30:39.796188+00
d0868867-befa-42d0-ab09-655be5dd7f28	1e57d93c-53e2-4f0b-92e0-944de0c43daa	aadhaar	abc	pending	\N	\N	2026-08-06 06:31:09.180854+00
eff6ca66-edd2-4c0f-b231-4ba45ca4f3d6	3c27e34d-8df3-456a-8b12-079170f1f55b	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 06:32:38.200946+00
0be20bbf-e9d9-499d-bb42-90a769cebba8	f87a94fc-f840-4b86-a2c5-1c32001d8a05	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 06:33:30.111598+00
ad16463f-828c-432f-8594-64a70686b584	ccef9aeb-4e3c-4923-bb15-f364e42fa1ac	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 06:34:02.617242+00
b6bf0d63-9d9c-46de-9985-7e902bf23495	639ff8c2-a929-4dbd-9f14-e19826bf1da3	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:24:34.761324+00
5cebdb6c-0022-43ab-9981-9e0ccc777c51	56e227be-5f34-465e-b71c-9fb4ecd94d98	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:25:09.125769+00
d54f06db-d8f4-47e9-b117-95650d791793	6a4d9674-6d2a-4be1-ab4c-213a45492132	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:25:57.733612+00
f2b5b63c-c2cd-4988-9571-36dc94db241b	3b777f71-d8a8-4d5e-a3a5-9dbc0057b9ac	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:27:21.398299+00
8f1db650-ac60-4b09-a84b-a537f26db71f	d95d19dd-5d82-4068-83c6-3683294a76df	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:39:45.562786+00
217a72c2-3111-4d64-81fd-9a1a7f51d53b	778e0a0e-af86-42de-bc86-f9ce5f47c98e	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:40:19.363022+00
99d792fc-564f-402d-881c-804646de709f	c82e6b63-ac48-40f4-b8f3-0be99df54466	aadhaar	1234-5678-9012	pending	\N	\N	2026-08-06 07:40:58.911303+00
\.


--
-- Name: AssistedMatchmakingRequests AssistedMatchmakingRequests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssistedMatchmakingRequests"
    ADD CONSTRAINT "AssistedMatchmakingRequests_pkey" PRIMARY KEY ("RequestId");


--
-- Name: BlockedUsers BlockedUsers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BlockedUsers"
    ADD CONSTRAINT "BlockedUsers_pkey" PRIMARY KEY ("BlockId");


--
-- Name: CallLogs CallLogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CallLogs"
    ADD CONSTRAINT "CallLogs_pkey" PRIMARY KEY ("CallId");


--
-- Name: CuratedMatches CuratedMatches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CuratedMatches"
    ADD CONSTRAINT "CuratedMatches_pkey" PRIMARY KEY ("CuratedMatchId");


--
-- Name: EndUserPayments EndUserPayments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserPayments"
    ADD CONSTRAINT "EndUserPayments_pkey" PRIMARY KEY ("PaymentId");


--
-- Name: EndUserPlans EndUserPlans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserPlans"
    ADD CONSTRAINT "EndUserPlans_pkey" PRIMARY KEY ("PlanId");


--
-- Name: EndUserSubscriptions EndUserSubscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserSubscriptions"
    ADD CONSTRAINT "EndUserSubscriptions_pkey" PRIMARY KEY ("SubscriptionId");


--
-- Name: Favorites Favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Favorites"
    ADD CONSTRAINT "Favorites_pkey" PRIMARY KEY ("FavoriteId");


--
-- Name: FeaturedListings FeaturedListings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FeaturedListings"
    ADD CONSTRAINT "FeaturedListings_pkey" PRIMARY KEY ("FeaturedId");


--
-- Name: GuardianDetails GuardianDetails_UserId_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."GuardianDetails"
    ADD CONSTRAINT "GuardianDetails_UserId_key" UNIQUE ("UserId");


--
-- Name: GuardianDetails GuardianDetails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."GuardianDetails"
    ADD CONSTRAINT "GuardianDetails_pkey" PRIMARY KEY ("GuardianId");


--
-- Name: InterestRequests InterestRequests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InterestRequests"
    ADD CONSTRAINT "InterestRequests_pkey" PRIMARY KEY ("InterestId");


--
-- Name: Matches Matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Matches"
    ADD CONSTRAINT "Matches_pkey" PRIMARY KEY ("MatchId");


--
-- Name: Messages Messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT "Messages_pkey" PRIMARY KEY ("MessageId");


--
-- Name: Notifications Notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "Notifications_pkey" PRIMARY KEY ("NotificationId");


--
-- Name: OTPRequests OTPRequests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OTPRequests"
    ADD CONSTRAINT "OTPRequests_pkey" PRIMARY KEY ("OTPRequestId");


--
-- Name: PrivacySettings PrivacySettings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PrivacySettings"
    ADD CONSTRAINT "PrivacySettings_pkey" PRIMARY KEY ("UserId");


--
-- Name: ProfileViews ProfileViews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfileViews"
    ADD CONSTRAINT "ProfileViews_pkey" PRIMARY KEY ("ViewId");


--
-- Name: Reports Reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT "Reports_pkey" PRIMARY KEY ("ReportId");


--
-- Name: SuccessStories SuccessStories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SuccessStories"
    ADD CONSTRAINT "SuccessStories_pkey" PRIMARY KEY ("StoryId");


--
-- Name: UserEducation UserEducation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserEducation"
    ADD CONSTRAINT "UserEducation_pkey" PRIMARY KEY ("EducationId");


--
-- Name: UserFamilyDetails UserFamilyDetails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserFamilyDetails"
    ADD CONSTRAINT "UserFamilyDetails_pkey" PRIMARY KEY ("FamilyId");


--
-- Name: UserLifestyle UserLifestyle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserLifestyle"
    ADD CONSTRAINT "UserLifestyle_pkey" PRIMARY KEY ("LifestyleId");


--
-- Name: UserLocation UserLocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserLocation"
    ADD CONSTRAINT "UserLocation_pkey" PRIMARY KEY ("LocationId");


--
-- Name: UserOccupation UserOccupation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserOccupation"
    ADD CONSTRAINT "UserOccupation_pkey" PRIMARY KEY ("OccupationId");


--
-- Name: UserPhotos UserPhotos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPhotos"
    ADD CONSTRAINT "UserPhotos_pkey" PRIMARY KEY ("PhotoId");


--
-- Name: UserPreferences UserPreferences_UserId_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPreferences"
    ADD CONSTRAINT "UserPreferences_UserId_key" UNIQUE ("UserId");


--
-- Name: UserPreferences UserPreferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPreferences"
    ADD CONSTRAINT "UserPreferences_pkey" PRIMARY KEY ("PreferenceId");


--
-- Name: UserProfiles UserProfiles_UserId_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserProfiles"
    ADD CONSTRAINT "UserProfiles_UserId_key" UNIQUE ("UserId");


--
-- Name: UserProfiles UserProfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserProfiles"
    ADD CONSTRAINT "UserProfiles_pkey" PRIMARY KEY ("ProfileId");


--
-- Name: UserSessions UserSessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserSessions"
    ADD CONSTRAINT "UserSessions_pkey" PRIMARY KEY ("SessionId");


--
-- Name: Users Users_Email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_Email_key" UNIQUE ("Email");


--
-- Name: Users Users_Phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_Phone_key" UNIQUE ("Phone");


--
-- Name: Users Users_UserName_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_UserName_key" UNIQUE ("UserName");


--
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY ("UserId");


--
-- Name: VerificationRequests VerificationRequests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."VerificationRequests"
    ADD CONSTRAINT "VerificationRequests_pkey" PRIMARY KEY ("VerificationId");


--
-- Name: BlockedUsers uq_block_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BlockedUsers"
    ADD CONSTRAINT uq_block_pair UNIQUE ("UserId", "BlockedUserId");


--
-- Name: Favorites uq_favorite_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Favorites"
    ADD CONSTRAINT uq_favorite_pair UNIQUE ("UserId", "FavoriteUserId");


--
-- Name: InterestRequests uq_interest_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InterestRequests"
    ADD CONSTRAINT uq_interest_pair UNIQUE ("SenderUserId", "ReceiverUserId");


--
-- Name: Matches uq_match_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Matches"
    ADD CONSTRAINT uq_match_pair UNIQUE ("UserId1", "UserId2");


--
-- Name: idx_calls_receiver; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_receiver ON public."CallLogs" USING btree ("ReceiverUserId");


--
-- Name: idx_enduserpay_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enduserpay_ref ON public."EndUserPayments" USING btree ("ProviderRef");


--
-- Name: idx_enduserpay_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enduserpay_user ON public."EndUserPayments" USING btree ("UserId");


--
-- Name: idx_endusersub_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_endusersub_user ON public."EndUserSubscriptions" USING btree ("UserId", "Status");


--
-- Name: idx_featured_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_featured_active ON public."FeaturedListings" USING btree ("UserId", "ExpiresOn");


--
-- Name: idx_interest_receiver; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interest_receiver ON public."InterestRequests" USING btree ("ReceiverUserId", "Status");


--
-- Name: idx_location_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_location_city ON public."UserLocation" USING btree ("City", "State");


--
-- Name: idx_matches_user1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_matches_user1 ON public."Matches" USING btree ("UserId1");


--
-- Name: idx_matches_user2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_matches_user2 ON public."Matches" USING btree ("UserId2");


--
-- Name: idx_messages_thread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_thread ON public."Messages" USING btree ("SenderUserId", "ReceiverUserId", "SentOn");


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user ON public."Notifications" USING btree ("UserId", "IsRead");


--
-- Name: idx_otp_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_phone ON public."OTPRequests" USING btree ("Phone");


--
-- Name: idx_photos_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_photos_user ON public."UserPhotos" USING btree ("UserId");


--
-- Name: idx_privacy_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_privacy_user ON public."PrivacySettings" USING btree ("UserId");


--
-- Name: idx_profiles_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_search ON public."UserProfiles" USING btree ("Gender", "Religion", "MaritalStatus");


--
-- Name: idx_profiles_visibility; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_visibility ON public."UserProfiles" USING btree ("Visibility");


--
-- Name: idx_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_status ON public."Reports" USING btree ("Status");


--
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user ON public."UserSessions" USING btree ("UserId");


--
-- Name: idx_verification_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verification_status ON public."VerificationRequests" USING btree ("Status");


--
-- Name: idx_views_viewed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_views_viewed ON public."ProfileViews" USING btree ("ViewedUserId", "ViewedOn");


--
-- Name: PrivacySettings trg_privacysettings_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_privacysettings_updated_on BEFORE UPDATE ON public."PrivacySettings" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: UserProfiles trg_userprofiles_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_userprofiles_updated_on BEFORE UPDATE ON public."UserProfiles" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: Users trg_users_updated_on; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_on BEFORE UPDATE ON public."Users" FOR EACH ROW EXECUTE FUNCTION public.set_updated_on();


--
-- Name: AssistedMatchmakingRequests fk_assisted_admin; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssistedMatchmakingRequests"
    ADD CONSTRAINT fk_assisted_admin FOREIGN KEY ("AssignedAdminId") REFERENCES public."Users"("UserId");


--
-- Name: AssistedMatchmakingRequests fk_assisted_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssistedMatchmakingRequests"
    ADD CONSTRAINT fk_assisted_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: BlockedUsers fk_blocked_target; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BlockedUsers"
    ADD CONSTRAINT fk_blocked_target FOREIGN KEY ("BlockedUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: BlockedUsers fk_blocked_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BlockedUsers"
    ADD CONSTRAINT fk_blocked_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: CallLogs fk_calls_caller; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CallLogs"
    ADD CONSTRAINT fk_calls_caller FOREIGN KEY ("CallerUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: CallLogs fk_calls_receiver; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CallLogs"
    ADD CONSTRAINT fk_calls_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: CuratedMatches fk_curated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CuratedMatches"
    ADD CONSTRAINT fk_curated_by FOREIGN KEY ("CuratedBy") REFERENCES public."Users"("UserId");


--
-- Name: CuratedMatches fk_curated_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CuratedMatches"
    ADD CONSTRAINT fk_curated_request FOREIGN KEY ("RequestId") REFERENCES public."AssistedMatchmakingRequests"("RequestId") ON DELETE CASCADE;


--
-- Name: CuratedMatches fk_curated_suggested; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CuratedMatches"
    ADD CONSTRAINT fk_curated_suggested FOREIGN KEY ("SuggestedUserId") REFERENCES public."Users"("UserId");


--
-- Name: UserEducation fk_education_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserEducation"
    ADD CONSTRAINT fk_education_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: EndUserPayments fk_enduserpay_sub; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserPayments"
    ADD CONSTRAINT fk_enduserpay_sub FOREIGN KEY ("SubscriptionId") REFERENCES public."EndUserSubscriptions"("SubscriptionId");


--
-- Name: EndUserPayments fk_enduserpay_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserPayments"
    ADD CONSTRAINT fk_enduserpay_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId");


--
-- Name: EndUserSubscriptions fk_endusersub_plan; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserSubscriptions"
    ADD CONSTRAINT fk_endusersub_plan FOREIGN KEY ("PlanId") REFERENCES public."EndUserPlans"("PlanId");


--
-- Name: EndUserSubscriptions fk_endusersub_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EndUserSubscriptions"
    ADD CONSTRAINT fk_endusersub_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserFamilyDetails fk_family_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserFamilyDetails"
    ADD CONSTRAINT fk_family_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Favorites fk_favorites_target; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Favorites"
    ADD CONSTRAINT fk_favorites_target FOREIGN KEY ("FavoriteUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Favorites fk_favorites_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Favorites"
    ADD CONSTRAINT fk_favorites_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: FeaturedListings fk_featured_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FeaturedListings"
    ADD CONSTRAINT fk_featured_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: GuardianDetails fk_guardian_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."GuardianDetails"
    ADD CONSTRAINT fk_guardian_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: InterestRequests fk_interest_receiver; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InterestRequests"
    ADD CONSTRAINT fk_interest_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: InterestRequests fk_interest_sender; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InterestRequests"
    ADD CONSTRAINT fk_interest_sender FOREIGN KEY ("SenderUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserLifestyle fk_lifestyle_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserLifestyle"
    ADD CONSTRAINT fk_lifestyle_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserLocation fk_location_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserLocation"
    ADD CONSTRAINT fk_location_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Matches fk_matches_user1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Matches"
    ADD CONSTRAINT fk_matches_user1 FOREIGN KEY ("UserId1") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Matches fk_matches_user2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Matches"
    ADD CONSTRAINT fk_matches_user2 FOREIGN KEY ("UserId2") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Messages fk_messages_receiver; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT fk_messages_receiver FOREIGN KEY ("ReceiverUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Messages fk_messages_sender; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Messages"
    ADD CONSTRAINT fk_messages_sender FOREIGN KEY ("SenderUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Notifications fk_notifications_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT fk_notifications_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserOccupation fk_occupation_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserOccupation"
    ADD CONSTRAINT fk_occupation_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: OTPRequests fk_otp_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OTPRequests"
    ADD CONSTRAINT fk_otp_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserPhotos fk_photos_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPhotos"
    ADD CONSTRAINT fk_photos_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserPreferences fk_preferences_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPreferences"
    ADD CONSTRAINT fk_preferences_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: PrivacySettings fk_privacy_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PrivacySettings"
    ADD CONSTRAINT fk_privacy_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: UserProfiles fk_profiles_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserProfiles"
    ADD CONSTRAINT fk_profiles_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Reports fk_reports_reported; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT fk_reports_reported FOREIGN KEY ("ReportedUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Reports fk_reports_reporter; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT fk_reports_reporter FOREIGN KEY ("ReporterUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: Reports fk_reports_reviewer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Reports"
    ADD CONSTRAINT fk_reports_reviewer FOREIGN KEY ("ReviewedBy") REFERENCES public."Users"("UserId");


--
-- Name: UserSessions fk_sessions_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserSessions"
    ADD CONSTRAINT fk_sessions_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: SuccessStories fk_story_approver; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SuccessStories"
    ADD CONSTRAINT fk_story_approver FOREIGN KEY ("ApprovedBy") REFERENCES public."Users"("UserId");


--
-- Name: SuccessStories fk_story_user1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SuccessStories"
    ADD CONSTRAINT fk_story_user1 FOREIGN KEY ("UserId1") REFERENCES public."Users"("UserId");


--
-- Name: SuccessStories fk_story_user2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SuccessStories"
    ADD CONSTRAINT fk_story_user2 FOREIGN KEY ("UserId2") REFERENCES public."Users"("UserId");


--
-- Name: VerificationRequests fk_verification_reviewer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."VerificationRequests"
    ADD CONSTRAINT fk_verification_reviewer FOREIGN KEY ("ReviewedBy") REFERENCES public."Users"("UserId");


--
-- Name: VerificationRequests fk_verification_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."VerificationRequests"
    ADD CONSTRAINT fk_verification_user FOREIGN KEY ("UserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: ProfileViews fk_views_viewed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfileViews"
    ADD CONSTRAINT fk_views_viewed FOREIGN KEY ("ViewedUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- Name: ProfileViews fk_views_viewer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfileViews"
    ADD CONSTRAINT fk_views_viewer FOREIGN KEY ("ViewerUserId") REFERENCES public."Users"("UserId") ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 9Ag1x2XtHJ73HdXtMucayzoqFhD4YsRJfQgeDZpDxKBv6U88FVtqbQh5Q4jJ7Va


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    persistence_token character varying(255),
    crypted_password character varying(255),
    password_salt character varying(255),
    login_count integer DEFAULT 0,
    failed_login_count integer DEFAULT 0,
    current_login_at timestamp without time zone,
    last_login_at timestamp without time zone,
    current_login_ip character varying(255),
    last_login_ip character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    role character varying(10) NOT NULL,
    force_password_reset boolean DEFAULT true,
    password_changed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    last_request_at timestamp without time zone
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: debate_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.debate_outcomes (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    debated_on date,
    transcript_url character varying(500),
    video_url character varying(500),
    overview text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    debated boolean DEFAULT true NOT NULL,
    commons_image_file_name character varying,
    commons_image_content_type character varying,
    commons_image_file_size integer,
    commons_image_updated_at timestamp without time zone,
    debate_pack_url character varying(500)
);


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.debate_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.debate_outcomes_id_seq OWNED BY public.debate_outcomes.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    queue character varying(255)
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: email_requested_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_requested_receipts (
    id integer NOT NULL,
    petition_id integer,
    government_response timestamp without time zone,
    debate_outcome timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    debate_scheduled timestamp without time zone,
    petition_email timestamp without time zone
);


--
-- Name: email_requested_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_requested_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_requested_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_requested_receipts_id_seq OWNED BY public.email_requested_receipts.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id integer NOT NULL,
    comment character varying(32768) NOT NULL,
    petition_link_or_title character varying,
    email character varying,
    user_agent character varying
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;


--
-- Name: government_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.government_responses (
    id integer NOT NULL,
    petition_id integer,
    summary character varying(500) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    responded_on date
);


--
-- Name: government_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.government_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: government_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.government_responses_id_seq OWNED BY public.government_responses.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id integer NOT NULL,
    christmas_start date,
    christmas_end date,
    easter_start date,
    easter_end date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: invalidations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invalidations (
    id integer NOT NULL,
    summary character varying(255) NOT NULL,
    details character varying(10000),
    petition_id integer,
    name character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    email character varying(255),
    created_after timestamp without time zone,
    created_before timestamp without time zone,
    matching_count integer DEFAULT 0 NOT NULL,
    invalidated_count integer DEFAULT 0 NOT NULL,
    enqueued_at timestamp without time zone,
    started_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    completed_at timestamp without time zone,
    counted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: invalidations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invalidations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invalidations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invalidations_id_seq OWNED BY public.invalidations.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    petition_id integer,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: parish_petition_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parish_petition_journals (
    id integer NOT NULL,
    parish_id character varying NOT NULL,
    petition_id integer NOT NULL,
    signature_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: parish_petition_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parish_petition_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parish_petition_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parish_petition_journals_id_seq OWNED BY public.parish_petition_journals.id;


--
-- Name: parishes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parishes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: parishes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parishes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parishes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parishes_id_seq OWNED BY public.parishes.id;


--
-- Name: petition_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.petition_emails (
    id integer NOT NULL,
    petition_id integer,
    subject character varying NOT NULL,
    body text,
    sent_by character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: petition_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.petition_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: petition_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.petition_emails_id_seq OWNED BY public.petition_emails.id;


--
-- Name: petitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.petitions (
    id integer NOT NULL,
    action character varying(255) NOT NULL,
    additional_details text,
    state character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    open_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    closed_at timestamp without time zone,
    signature_count integer DEFAULT 0,
    notified_by_email boolean DEFAULT false,
    background character varying(300),
    sponsor_token character varying(255),
    government_response_at timestamp without time zone,
    scheduled_debate_date date,
    last_signed_at timestamp without time zone,
    response_threshold_reached_at timestamp without time zone,
    debate_threshold_reached_at timestamp without time zone,
    rejected_at timestamp without time zone,
    debate_outcome_at timestamp without time zone,
    moderation_threshold_reached_at timestamp without time zone,
    debate_state character varying(30) DEFAULT 'pending'::character varying,
    special_consideration boolean,
    tags integer[] DEFAULT '{}'::integer[] NOT NULL,
    locked_at timestamp without time zone,
    locked_by_id integer,
    moderation_lag integer
);


--
-- Name: petitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.petitions_id_seq
    START WITH 200000
    INCREMENT BY 1
    MINVALUE 200000
    NO MAXVALUE
    CACHE 1;


--
-- Name: petitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.petitions_id_seq OWNED BY public.petitions.id;


--
-- Name: postcodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postcodes (
    postcode character varying(10) NOT NULL,
    parish character varying(30) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: rate_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_limits (
    id integer NOT NULL,
    burst_rate integer DEFAULT 1 NOT NULL,
    burst_period integer DEFAULT 60 NOT NULL,
    sustained_rate integer DEFAULT 5 NOT NULL,
    sustained_period integer DEFAULT 300 NOT NULL,
    allowed_domains character varying(10000) DEFAULT ''::character varying NOT NULL,
    allowed_ips character varying(10000) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    blocked_domains character varying(50000) DEFAULT ''::character varying NOT NULL,
    blocked_ips character varying(50000) DEFAULT ''::character varying NOT NULL,
    geoblocking_enabled boolean DEFAULT false NOT NULL,
    countries character varying(2000) DEFAULT ''::character varying NOT NULL
);


--
-- Name: rate_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_limits_id_seq OWNED BY public.rate_limits.id;


--
-- Name: rejections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejections (
    id integer NOT NULL,
    petition_id integer,
    code character varying(50) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rejections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rejections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rejections_id_seq OWNED BY public.rejections.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signatures (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT false,
    email character varying(255),
    unsubscribe_token character varying,
    parish_id character varying,
    validated_at timestamp without time zone,
    number integer,
    seen_signed_confirmation_page boolean DEFAULT false NOT NULL,
    invalidated_at timestamp without time zone,
    invalidation_id integer,
    government_response_email_at timestamp without time zone,
    debate_scheduled_email_at timestamp without time zone,
    debate_outcome_email_at timestamp without time zone,
    petition_email_at timestamp without time zone,
    uuid uuid,
    email_count integer DEFAULT 0 NOT NULL,
    sponsor boolean DEFAULT false NOT NULL,
    creator boolean DEFAULT false NOT NULL
);


--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.signatures_id_seq OWNED BY public.signatures.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    id integer NOT NULL,
    title character varying(50) DEFAULT 'Petition States Assembly'::character varying NOT NULL,
    url character varying(50) DEFAULT 'https://petitions.gov.je'::character varying NOT NULL,
    email_from character varying(100) DEFAULT '"Petitions: Jersey States Assembly" <no-reply@gov.je>'::character varying NOT NULL,
    username character varying(30),
    password_digest character varying(60),
    enabled boolean DEFAULT true NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    petition_duration integer DEFAULT 6 NOT NULL,
    minimum_number_of_sponsors integer DEFAULT 5 NOT NULL,
    maximum_number_of_sponsors integer DEFAULT 20 NOT NULL,
    threshold_for_moderation integer DEFAULT 5 NOT NULL,
    threshold_for_response integer DEFAULT 10000 NOT NULL,
    threshold_for_debate integer DEFAULT 100000 NOT NULL,
    last_checked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feedback_email character varying(100) DEFAULT '"Petitions: Jersey States Assembly" <petitions@gov.je>'::character varying NOT NULL,
    moderate_url character varying(50) DEFAULT 'https://moderate.petitions.gov.je'::character varying NOT NULL,
    last_petition_created_at timestamp without time zone,
    login_timeout integer DEFAULT 1800 NOT NULL,
    feature_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    petition_report_email character varying(100) DEFAULT '"Petitions: Jersey States Assembly" <petitions@gov.je>'::character varying NOT NULL,
    petition_report_day_of_week integer DEFAULT 0,
    petition_report_hour_of_day integer DEFAULT 9
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sites_id_seq OWNED BY public.sites.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: debate_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes ALTER COLUMN id SET DEFAULT nextval('public.debate_outcomes_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: email_requested_receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts ALTER COLUMN id SET DEFAULT nextval('public.email_requested_receipts_id_seq'::regclass);


--
-- Name: feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);


--
-- Name: government_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses ALTER COLUMN id SET DEFAULT nextval('public.government_responses_id_seq'::regclass);


--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: invalidations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invalidations ALTER COLUMN id SET DEFAULT nextval('public.invalidations_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: parish_petition_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parish_petition_journals ALTER COLUMN id SET DEFAULT nextval('public.parish_petition_journals_id_seq'::regclass);


--
-- Name: parishes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parishes ALTER COLUMN id SET DEFAULT nextval('public.parishes_id_seq'::regclass);


--
-- Name: petition_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails ALTER COLUMN id SET DEFAULT nextval('public.petition_emails_id_seq'::regclass);


--
-- Name: petitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petitions ALTER COLUMN id SET DEFAULT nextval('public.petitions_id_seq'::regclass);


--
-- Name: rate_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits ALTER COLUMN id SET DEFAULT nextval('public.rate_limits_id_seq'::regclass);


--
-- Name: rejections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections ALTER COLUMN id SET DEFAULT nextval('public.rejections_id_seq'::regclass);


--
-- Name: signatures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures ALTER COLUMN id SET DEFAULT nextval('public.signatures_id_seq'::regclass);


--
-- Name: sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites ALTER COLUMN id SET DEFAULT nextval('public.sites_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: debate_outcomes debate_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes
    ADD CONSTRAINT debate_outcomes_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: email_requested_receipts email_requested_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts
    ADD CONSTRAINT email_requested_receipts_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: government_responses government_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses
    ADD CONSTRAINT government_responses_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: invalidations invalidations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invalidations
    ADD CONSTRAINT invalidations_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: parish_petition_journals parish_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parish_petition_journals
    ADD CONSTRAINT parish_petition_journals_pkey PRIMARY KEY (id);


--
-- Name: parishes parishes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parishes
    ADD CONSTRAINT parishes_pkey PRIMARY KEY (id);


--
-- Name: petition_emails petition_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails
    ADD CONSTRAINT petition_emails_pkey PRIMARY KEY (id);


--
-- Name: petitions petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petitions
    ADD CONSTRAINT petitions_pkey PRIMARY KEY (id);


--
-- Name: postcodes postcodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcodes
    ADD CONSTRAINT postcodes_pkey PRIMARY KEY (postcode);


--
-- Name: rate_limits rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits
    ADD CONSTRAINT rate_limits_pkey PRIMARY KEY (id);


--
-- Name: rejections rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections
    ADD CONSTRAINT rejections_pkey PRIMARY KEY (id);


--
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY (id);


--
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: ft_index_invalidations_on_details; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_details ON public.invalidations USING gin (to_tsvector('english'::regconfig, (details)::text));


--
-- Name: ft_index_invalidations_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_id ON public.invalidations USING gin (to_tsvector('english'::regconfig, (id)::text));


--
-- Name: ft_index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_petition_id ON public.invalidations USING gin (to_tsvector('english'::regconfig, (petition_id)::text));


--
-- Name: ft_index_invalidations_on_summary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_summary ON public.invalidations USING gin (to_tsvector('english'::regconfig, (summary)::text));


--
-- Name: idx_constituency_petition_journal_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_constituency_petition_journal_uniqueness ON public.parish_petition_journals USING btree (petition_id, parish_id);


--
-- Name: idx_parish_petition_journal_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_parish_petition_journal_uniqueness ON public.parish_petition_journals USING btree (petition_id, parish_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_email ON public.admin_users USING btree (email);


--
-- Name: index_admin_users_on_last_name_and_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_users_on_last_name_and_first_name ON public.admin_users USING btree (last_name, first_name);


--
-- Name: index_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_debate_outcomes_on_petition_id ON public.debate_outcomes USING btree (petition_id);


--
-- Name: index_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debate_outcomes_on_petition_id_and_debated_on ON public.debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_debate_outcomes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debate_outcomes_on_updated_at ON public.debate_outcomes USING btree (updated_at);


--
-- Name: index_delayed_jobs_on_priority_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_priority_and_run_at ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_email_requested_receipts_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_requested_receipts_on_petition_id ON public.email_requested_receipts USING btree (petition_id);


--
-- Name: index_ft_tags_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ft_tags_on_description ON public.tags USING gin (to_tsvector('english'::regconfig, (description)::text));


--
-- Name: index_ft_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ft_tags_on_name ON public.tags USING gin (to_tsvector('english'::regconfig, (name)::text));


--
-- Name: index_government_responses_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_government_responses_on_petition_id ON public.government_responses USING btree (petition_id);


--
-- Name: index_government_responses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_government_responses_on_updated_at ON public.government_responses USING btree (updated_at);


--
-- Name: index_invalidations_on_cancelled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_cancelled_at ON public.invalidations USING btree (cancelled_at);


--
-- Name: index_invalidations_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_completed_at ON public.invalidations USING btree (completed_at);


--
-- Name: index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_petition_id ON public.invalidations USING btree (petition_id);


--
-- Name: index_invalidations_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_started_at ON public.invalidations USING btree (started_at);


--
-- Name: index_notes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notes_on_petition_id ON public.notes USING btree (petition_id);


--
-- Name: index_parishes_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_parishes_on_slug ON public.parishes USING btree (slug);


--
-- Name: index_petition_emails_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petition_emails_on_petition_id ON public.petition_emails USING btree (petition_id);


--
-- Name: index_petitions_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_action ON public.petitions USING gin (to_tsvector('english'::regconfig, (action)::text));


--
-- Name: index_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_additional_details ON public.petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_petitions_on_background; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_background ON public.petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_petitions_on_created_at_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_created_at_and_state ON public.petitions USING btree (created_at, state);


--
-- Name: index_petitions_on_debate_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_debate_state ON public.petitions USING btree (debate_state);


--
-- Name: index_petitions_on_debate_threshold_reached_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_debate_threshold_reached_at ON public.petitions USING btree (debate_threshold_reached_at);


--
-- Name: index_petitions_on_last_signed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_last_signed_at ON public.petitions USING btree (last_signed_at);


--
-- Name: index_petitions_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_locked_by_id ON public.petitions USING btree (locked_by_id);


--
-- Name: index_petitions_on_mt_reached_at_and_moderation_lag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_mt_reached_at_and_moderation_lag ON public.petitions USING btree (moderation_threshold_reached_at, moderation_lag);


--
-- Name: index_petitions_on_response_threshold_reached_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_response_threshold_reached_at ON public.petitions USING btree (response_threshold_reached_at);


--
-- Name: index_petitions_on_signature_count_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_signature_count_and_state ON public.petitions USING btree (signature_count, state);


--
-- Name: index_petitions_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_tags ON public.petitions USING gin (tags public.gin__int_ops);


--
-- Name: index_rejections_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rejections_on_petition_id ON public.rejections USING btree (petition_id);


--
-- Name: index_signatures_on_created_at_and_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_created_at_and_ip_address_and_petition_id ON public.signatures USING btree (created_at, ip_address, petition_id);


--
-- Name: index_signatures_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_domain ON public.signatures USING btree ("substring"((email)::text, ("position"((email)::text, '@'::text) + 1)));


--
-- Name: index_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_signatures_on_email_and_petition_id_and_name ON public.signatures USING btree (email, petition_id, name);


--
-- Name: index_signatures_on_invalidation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_invalidation_id ON public.signatures USING btree (invalidation_id);


--
-- Name: index_signatures_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_ip_address_and_petition_id ON public.signatures USING btree (ip_address, petition_id);


--
-- Name: index_signatures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_name ON public.signatures USING btree (lower((name)::text));


--
-- Name: index_signatures_on_parish_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_parish_id ON public.signatures USING btree (parish_id);


--
-- Name: index_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_petition_id ON public.signatures USING btree (petition_id);


--
-- Name: index_signatures_on_petition_id_where_creator_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_signatures_on_petition_id_where_creator_is_true ON public.signatures USING btree (petition_id) WHERE (creator = true);


--
-- Name: index_signatures_on_petition_id_where_sponsor_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_petition_id_where_sponsor_is_true ON public.signatures USING btree (petition_id) WHERE (sponsor = true);


--
-- Name: index_signatures_on_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_state_and_petition_id ON public.signatures USING btree (state, petition_id);


--
-- Name: index_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_updated_at ON public.signatures USING btree (updated_at);


--
-- Name: index_signatures_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_uuid ON public.signatures USING btree (uuid);


--
-- Name: index_signatures_on_validated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_validated_at ON public.signatures USING btree (validated_at);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tasks_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tasks_on_name ON public.tasks USING btree (name);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: government_responses fk_rails_0af6bc4d41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses
    ADD CONSTRAINT fk_rails_0af6bc4d41 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: signatures fk_rails_3e01179571; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT fk_rails_3e01179571 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_3e3a2f376e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_3e3a2f376e FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: parish_petition_journals fk_rails_5186723bbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parish_petition_journals
    ADD CONSTRAINT fk_rails_5186723bbd FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: rejections fk_rails_82ffb00060; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections
    ADD CONSTRAINT fk_rails_82ffb00060 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: email_requested_receipts fk_rails_898597541e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts
    ADD CONSTRAINT fk_rails_898597541e FOREIGN KEY (petition_id) REFERENCES public.petitions(id);


--
-- Name: petition_emails fk_rails_9f55aacb99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails
    ADD CONSTRAINT fk_rails_9f55aacb99 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: debate_outcomes fk_rails_cb057e3dd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes
    ADD CONSTRAINT fk_rails_cb057e3dd1 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20150602200239'),
('20150603033108'),
('20150603112821'),
('20150605100049'),
('20150609111042'),
('20150610091149'),
('20150612095611'),
('20150612103324'),
('20150612111204'),
('20150615131623'),
('20150615145953'),
('20150615151103'),
('20150617114935'),
('20150617135014'),
('20150617164310'),
('20150618134919'),
('20150618143114'),
('20150618144922'),
('20150618233548'),
('20150618233718'),
('20150619075903'),
('20150619090833'),
('20150619133502'),
('20150619134335'),
('20150621200307'),
('20150622083615'),
('20150622140322'),
('20150630105949'),
('20150701111544'),
('20150701145201'),
('20150701145202'),
('20150701151007'),
('20150701151008'),
('20150701165424'),
('20150701165425'),
('20150701174136'),
('20150703100716'),
('20150703165930'),
('20150705114811'),
('20150707094523'),
('20150709152530'),
('20150714140659'),
('20150730110838'),
('20150805142206'),
('20150805142254'),
('20150806140552'),
('20150814111100'),
('20150820152623'),
('20150820153515'),
('20150820155740'),
('20150820161504'),
('20150913073343'),
('20150913074747'),
('20150924082835'),
('20150924082944'),
('20150924090755'),
('20150924091057'),
('20150928162418'),
('20151014152915'),
('20151014152929'),
('20160104144458'),
('20160210001632'),
('20160210174624'),
('20160210195916'),
('20160211002731'),
('20160211003703'),
('20160214133749'),
('20160214233414'),
('20160217192016'),
('20160527112417'),
('20160704152204'),
('20160704162920'),
('20160704185825'),
('20160706060256'),
('20160713124623'),
('20160713130452'),
('20160715092819'),
('20160716164929'),
('20160819062044'),
('20160819062058'),
('20160820132056'),
('20160820162023'),
('20160820165029'),
('20160822064645'),
('20160910054223'),
('20161006095752'),
('20161006101123'),
('20170419165419'),
('20170422104143'),
('20170424145119'),
('20170428185435'),
('20170428211336'),
('20170429023722'),
('20170501093620'),
('20170502155040'),
('20170503192115'),
('20170610132850'),
('20170611115913'),
('20170611123348'),
('20170611131130'),
('20170611190354'),
('20170612120307'),
('20170612144648'),
('20170613113510'),
('20170614165953'),
('20170615133536'),
('20170622114605'),
('20170622114801'),
('20170622151936'),
('20170622152415'),
('20170622161343'),
('20170623144023'),
('20170626123257'),
('20170626130418'),
('20170627125046'),
('20170629144129'),
('20170703100952'),
('20170710090730'),
('20170711112737'),
('20170711134626'),
('20170711134758'),
('20170711153944'),
('20170711153945'),
('20170712070139'),
('20170713193039'),
('20170818110849'),
('20170821153056'),
('20170821153057'),
('20170903162156'),
('20170903181738'),
('20170906203439'),
('20170909092251'),
('20170909095357'),
('20170915102120'),
('20170918162913'),
('20171204113835'),
('20171204122339'),
('20180329062433'),
('20180510122656'),
('20180510131346'),
('20180522033130'),
('20180522145833'),
('20180524033654'),
('20180524211622'),
('20180525102331'),
('20180525102340'),
('20180525102341'),
('20180604101626'),
('20180620094258'),
('20180621150426'),
('20180623131406');



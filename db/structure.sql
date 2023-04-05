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
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: trim_html_tags(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trim_html_tags(input text, OUT output text) RETURNS text
    LANGUAGE sql
    AS $$
      SELECT regexp_replace(input, E'<[^>]*>', '', 'g');
      $$;


SET default_tablespace = '';

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id bigint NOT NULL,
    my_module_id bigint,
    owner_id bigint,
    type_of integer NOT NULL,
    message character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_id bigint,
    experiment_id bigint,
    subject_type character varying,
    subject_id bigint,
    team_id bigint,
    group_type integer,
    "values" jsonb
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: activity_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_filters (
    id bigint NOT NULL,
    name character varying NOT NULL,
    filter jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: activity_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_filters_id_seq OWNED BY public.activity_filters.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_text_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_text_data (
    id bigint NOT NULL,
    data text NOT NULL,
    asset_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_vector tsvector
);


--
-- Name: asset_text_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_text_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_text_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_text_data_id_seq OWNED BY public.asset_text_data.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    estimated_size integer DEFAULT 0 NOT NULL,
    lock character varying(1024),
    lock_ttl integer,
    version integer DEFAULT 1,
    file_processing boolean,
    team_id integer,
    file_image_quality integer,
    view_mode integer DEFAULT 0 NOT NULL,
    pdf_preview_processing boolean DEFAULT false
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: bmt_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bmt_filters (
    id bigint NOT NULL,
    name character varying NOT NULL,
    filters json NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bmt_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bmt_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bmt_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bmt_filters_id_seq OWNED BY public.bmt_filters.id;


--
-- Name: checklist_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checklist_items (
    id bigint NOT NULL,
    text character varying NOT NULL,
    checked boolean DEFAULT false NOT NULL,
    checklist_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    "position" integer
);


--
-- Name: checklist_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.checklist_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklist_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.checklist_items_id_seq OWNED BY public.checklist_items.id;


--
-- Name: checklists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checklists (
    id bigint NOT NULL,
    name character varying NOT NULL,
    step_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint
);


--
-- Name: checklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.checklists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.checklists_id_seq OWNED BY public.checklists.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    message character varying NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_modified_by_id bigint,
    type character varying,
    associated_id integer,
    unseen_by bigint[] DEFAULT '{}'::bigint[]
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connections (
    id bigint NOT NULL,
    input_id bigint NOT NULL,
    output_id bigint NOT NULL
);


--
-- Name: connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connections_id_seq OWNED BY public.connections.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    description character varying,
    space_taken bigint DEFAULT 1048576 NOT NULL
);


--
-- Name: user_teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_teams (
    id bigint NOT NULL,
    role integer DEFAULT 1 NOT NULL,
    user_id bigint NOT NULL,
    team_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_by_id bigint
);


--
-- Name: datatables_teams; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.datatables_teams AS
 SELECT teams.id,
    teams.name,
    user_teams.role,
    ( SELECT count(*) AS count
           FROM public.user_teams user_teams_1
          WHERE (user_teams_1.team_id = teams.id)) AS members,
        CASE
            WHEN (teams.created_by_id = user_teams.user_id) THEN false
            ELSE true
        END AS can_be_left,
    user_teams.id AS user_team_id,
    user_teams.user_id
   FROM (public.teams
     JOIN public.user_teams ON ((teams.id = user_teams.team_id)));


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    AS integer
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
-- Name: experiments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    project_id integer NOT NULL,
    created_by_id bigint NOT NULL,
    last_modified_by_id bigint NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    archived_by_id bigint,
    archived_on timestamp without time zone,
    restored_by_id bigint,
    restored_on timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uuid uuid
);


--
-- Name: experiments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiments_id_seq OWNED BY public.experiments.id;


--
-- Name: hidden_repository_cell_reminders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hidden_repository_cell_reminders (
    id bigint NOT NULL,
    repository_cell_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: hidden_repository_cell_reminders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hidden_repository_cell_reminders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hidden_repository_cell_reminders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hidden_repository_cell_reminders_id_seq OWNED BY public.hidden_repository_cell_reminders.id;


--
-- Name: label_printers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_printers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    type_of integer NOT NULL,
    language_type integer NOT NULL,
    host character varying,
    port integer,
    fluics_api_key character varying,
    fluics_lid character varying,
    current_print_job_ids character varying[] DEFAULT '{}'::character varying[],
    status integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: label_printers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.label_printers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: label_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.label_printers_id_seq OWNED BY public.label_printers.id;


--
-- Name: label_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_templates (
    id bigint NOT NULL,
    name character varying NOT NULL,
    content text NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description character varying,
    last_modified_by_id integer,
    created_by_id integer,
    team_id bigint,
    type character varying,
    width_mm double precision,
    height_mm double precision,
    unit integer DEFAULT 0,
    density integer DEFAULT 12
);


--
-- Name: label_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.label_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: label_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.label_templates_id_seq OWNED BY public.label_templates.id;


--
-- Name: my_module_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_groups (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    experiment_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: my_module_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_groups_id_seq OWNED BY public.my_module_groups.id;


--
-- Name: my_module_repository_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_repository_rows (
    id bigint NOT NULL,
    repository_row_id bigint NOT NULL,
    my_module_id integer,
    assigned_by_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    stock_consumption numeric,
    repository_stock_unit_item_id bigint
);


--
-- Name: my_module_repository_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_repository_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_repository_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_repository_rows_id_seq OWNED BY public.my_module_repository_rows.id;


--
-- Name: my_module_status_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_status_conditions (
    id bigint NOT NULL,
    my_module_status_id bigint,
    type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: my_module_status_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_status_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_status_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_status_conditions_id_seq OWNED BY public.my_module_status_conditions.id;


--
-- Name: my_module_status_consequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_status_consequences (
    id bigint NOT NULL,
    my_module_status_id bigint,
    type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: my_module_status_consequences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_status_consequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_status_consequences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_status_consequences_id_seq OWNED BY public.my_module_status_consequences.id;


--
-- Name: my_module_status_flows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_status_flows (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    visibility integer DEFAULT 0,
    team_id bigint,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: my_module_status_flows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_status_flows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_status_flows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_status_flows_id_seq OWNED BY public.my_module_status_flows.id;


--
-- Name: my_module_status_implications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_status_implications (
    id bigint NOT NULL,
    my_module_status_id bigint,
    type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: my_module_status_implications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_status_implications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_status_implications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_status_implications_id_seq OWNED BY public.my_module_status_implications.id;


--
-- Name: my_module_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_statuses (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    color character varying NOT NULL,
    my_module_status_flow_id bigint,
    previous_status_id bigint,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: my_module_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_statuses_id_seq OWNED BY public.my_module_statuses.id;


--
-- Name: my_module_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_module_tags (
    id bigint NOT NULL,
    my_module_id integer,
    tag_id integer,
    created_by_id bigint
);


--
-- Name: my_module_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_module_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_module_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_module_tags_id_seq OWNED BY public.my_module_tags.id;


--
-- Name: my_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.my_modules (
    id bigint NOT NULL,
    name character varying NOT NULL,
    due_date timestamp without time zone,
    description character varying,
    x integer DEFAULT 0 NOT NULL,
    y integer DEFAULT 0 NOT NULL,
    my_module_group_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    archived_on timestamp without time zone,
    created_by_id bigint,
    last_modified_by_id bigint,
    archived_by_id bigint,
    restored_by_id bigint,
    restored_on timestamp without time zone,
    workflow_order integer DEFAULT '-1'::integer NOT NULL,
    experiment_id bigint DEFAULT 0 NOT NULL,
    state smallint DEFAULT 0,
    completed_on timestamp without time zone,
    started_on timestamp without time zone,
    my_module_status_id bigint,
    status_changing boolean DEFAULT false,
    changing_from_my_module_status_id bigint,
    last_transition_error jsonb,
    provisioning_status integer
);


--
-- Name: my_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.my_modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.my_modules_id_seq OWNED BY public.my_modules.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    title character varying,
    message character varying,
    type_of integer NOT NULL,
    generator_user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    resource_owner_id bigint,
    application_id bigint,
    token text NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: project_folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_folders (
    id bigint NOT NULL,
    name character varying NOT NULL,
    team_id bigint NOT NULL,
    parent_folder_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    archived_by_id bigint,
    archived_on timestamp without time zone,
    restored_by_id bigint,
    restored_on timestamp without time zone
);


--
-- Name: project_folders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_folders_id_seq OWNED BY public.project_folders.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    name character varying NOT NULL,
    visibility integer DEFAULT 0 NOT NULL,
    due_date timestamp without time zone,
    team_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    archived_on timestamp without time zone,
    created_by_id bigint,
    last_modified_by_id bigint,
    archived_by_id bigint,
    restored_by_id bigint,
    restored_on timestamp without time zone,
    experiments_order character varying,
    template boolean,
    demo boolean DEFAULT false NOT NULL,
    project_folder_id bigint,
    default_public_user_role_id bigint
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: protocol_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protocol_keywords (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    nr_of_protocols integer DEFAULT 0,
    team_id bigint NOT NULL
);


--
-- Name: protocol_keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protocol_keywords_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.protocol_keywords_id_seq OWNED BY public.protocol_keywords.id;


--
-- Name: protocol_protocol_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protocol_protocol_keywords (
    id bigint NOT NULL,
    protocol_id bigint NOT NULL,
    protocol_keyword_id bigint NOT NULL
);


--
-- Name: protocol_protocol_keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protocol_protocol_keywords_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_protocol_keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.protocol_protocol_keywords_id_seq OWNED BY public.protocol_protocol_keywords.id;


--
-- Name: protocols; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protocols (
    id bigint NOT NULL,
    name character varying,
    authors text,
    description text,
    added_by_id bigint,
    my_module_id bigint,
    team_id bigint NOT NULL,
    protocol_type integer DEFAULT 0 NOT NULL,
    parent_id bigint,
    parent_updated_at timestamp without time zone,
    archived_by_id bigint,
    archived_on timestamp without time zone,
    restored_by_id bigint,
    restored_on timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    published_on timestamp without time zone,
    nr_of_linked_children integer DEFAULT 0,
    visibility integer DEFAULT 0,
    archived boolean DEFAULT false NOT NULL,
    version_number integer DEFAULT 1,
    version_comment character varying,
    default_public_user_role_id bigint,
    previous_version_id bigint,
    last_modified_by_id bigint,
    published_by_id bigint,
    linked_at timestamp without time zone
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protocols_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.protocols_id_seq OWNED BY public.protocols.id;


--
-- Name: report_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_elements (
    id bigint NOT NULL,
    "position" integer NOT NULL,
    type_of integer NOT NULL,
    sort_order integer DEFAULT 0,
    report_id bigint,
    parent_id integer,
    project_id bigint,
    my_module_id bigint,
    step_id bigint,
    result_id bigint,
    checklist_id bigint,
    asset_id bigint,
    table_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    experiment_id bigint,
    repository_id integer
);


--
-- Name: report_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_elements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_elements_id_seq OWNED BY public.report_elements.id;


--
-- Name: report_template_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_template_values (
    id bigint NOT NULL,
    report_id bigint NOT NULL,
    view_component character varying NOT NULL,
    name character varying NOT NULL,
    value jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: report_template_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_template_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_template_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_template_values_id_seq OWNED BY public.report_template_values.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_modified_by_id bigint,
    team_id bigint,
    pdf_file_status integer DEFAULT 0,
    docx_file_status integer DEFAULT 0,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repositories (
    id bigint NOT NULL,
    team_id integer,
    created_by_id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    discarded_at timestamp without time zone,
    permission_level integer DEFAULT 0 NOT NULL,
    type character varying,
    parent_id bigint,
    status integer,
    selected boolean,
    my_module_id bigint,
    archived boolean DEFAULT false NOT NULL,
    archived_on timestamp without time zone,
    restored_on timestamp without time zone,
    archived_by_id bigint,
    restored_by_id bigint
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repositories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repositories_id_seq OWNED BY public.repositories.id;


--
-- Name: repository_asset_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_asset_values (
    id bigint NOT NULL,
    asset_id bigint,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: repository_asset_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_asset_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_asset_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_asset_values_id_seq OWNED BY public.repository_asset_values.id;


--
-- Name: repository_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_cells (
    id bigint NOT NULL,
    repository_row_id bigint,
    repository_column_id integer,
    value_type character varying,
    value_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: repository_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_cells_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_cells_id_seq OWNED BY public.repository_cells.id;


--
-- Name: repository_checklist_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_checklist_items (
    id bigint NOT NULL,
    data character varying NOT NULL,
    repository_column_id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_checklist_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_checklist_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_checklist_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_checklist_items_id_seq OWNED BY public.repository_checklist_items.id;


--
-- Name: repository_checklist_items_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_checklist_items_values (
    id bigint NOT NULL,
    repository_checklist_value_id bigint,
    repository_checklist_item_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_checklist_items_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_checklist_items_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_checklist_items_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_checklist_items_values_id_seq OWNED BY public.repository_checklist_items_values.id;


--
-- Name: repository_checklist_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_checklist_values (
    id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_checklist_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_checklist_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_checklist_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_checklist_values_id_seq OWNED BY public.repository_checklist_values.id;


--
-- Name: repository_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_columns (
    id bigint NOT NULL,
    repository_id integer,
    created_by_id bigint NOT NULL,
    name character varying,
    data_type integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    parent_id bigint
);


--
-- Name: repository_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_columns_id_seq OWNED BY public.repository_columns.id;


--
-- Name: repository_date_time_range_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_date_time_range_values (
    id bigint NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    last_modified_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying,
    start_time_dup timestamp without time zone,
    end_time_dup timestamp without time zone
);


--
-- Name: repository_date_time_range_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_date_time_range_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_date_time_range_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_date_time_range_values_id_seq OWNED BY public.repository_date_time_range_values.id;


--
-- Name: repository_date_time_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_date_time_values (
    id bigint NOT NULL,
    data timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by_id bigint NOT NULL,
    last_modified_by_id bigint NOT NULL,
    type character varying,
    data_dup timestamp without time zone
);


--
-- Name: repository_date_time_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_date_time_values_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_date_time_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_date_time_values_id_seq OWNED BY public.repository_date_time_values.id;


--
-- Name: repository_ledger_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_ledger_records (
    id bigint NOT NULL,
    repository_stock_value_id bigint NOT NULL,
    reference_type character varying NOT NULL,
    reference_id bigint NOT NULL,
    amount numeric,
    balance numeric,
    user_id bigint,
    comment text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_ledger_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_ledger_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_ledger_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_ledger_records_id_seq OWNED BY public.repository_ledger_records.id;


--
-- Name: repository_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_list_items (
    id bigint NOT NULL,
    repository_column_id bigint,
    data text NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: repository_list_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_list_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_list_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_list_items_id_seq OWNED BY public.repository_list_items.id;


--
-- Name: repository_list_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_list_values (
    id bigint NOT NULL,
    repository_list_item_id bigint,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: repository_list_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_list_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_list_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_list_values_id_seq OWNED BY public.repository_list_values.id;


--
-- Name: repository_number_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_number_values (
    id bigint NOT NULL,
    data numeric,
    last_modified_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_number_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_number_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_number_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_number_values_id_seq OWNED BY public.repository_number_values.id;


--
-- Name: repository_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_rows (
    id bigint NOT NULL,
    repository_id integer,
    created_by_id bigint NOT NULL,
    last_modified_by_id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    parent_id bigint,
    archived boolean DEFAULT false NOT NULL,
    archived_on timestamp without time zone,
    restored_on timestamp without time zone,
    archived_by_id bigint,
    restored_by_id bigint,
    external_id character varying
);


--
-- Name: repository_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_rows_id_seq OWNED BY public.repository_rows.id;


--
-- Name: repository_status_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_status_items (
    id bigint NOT NULL,
    status character varying NOT NULL,
    icon character varying NOT NULL,
    repository_column_id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_status_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_status_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_status_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_status_items_id_seq OWNED BY public.repository_status_items.id;


--
-- Name: repository_status_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_status_values (
    id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    repository_status_item_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_status_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_status_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_status_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_status_values_id_seq OWNED BY public.repository_status_values.id;


--
-- Name: repository_stock_unit_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_stock_unit_items (
    id bigint NOT NULL,
    data character varying NOT NULL,
    repository_column_id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_stock_unit_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_stock_unit_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_stock_unit_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_stock_unit_items_id_seq OWNED BY public.repository_stock_unit_items.id;


--
-- Name: repository_stock_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_stock_values (
    id bigint NOT NULL,
    amount numeric,
    repository_stock_unit_item_id bigint,
    type character varying,
    last_modified_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    low_stock_threshold numeric
);


--
-- Name: repository_stock_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_stock_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_stock_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_stock_values_id_seq OWNED BY public.repository_stock_values.id;


--
-- Name: repository_table_filter_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_table_filter_elements (
    id bigint NOT NULL,
    repository_table_filter_id bigint,
    repository_column_id bigint,
    operator integer,
    parameters jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_table_filter_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_table_filter_elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_table_filter_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_table_filter_elements_id_seq OWNED BY public.repository_table_filter_elements.id;


--
-- Name: repository_table_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_table_filters (
    id bigint NOT NULL,
    name character varying NOT NULL,
    default_columns jsonb DEFAULT '{}'::jsonb NOT NULL,
    repository_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: repository_table_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_table_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_table_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_table_filters_id_seq OWNED BY public.repository_table_filters.id;


--
-- Name: repository_table_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_table_states (
    id bigint NOT NULL,
    state jsonb NOT NULL,
    user_id integer NOT NULL,
    repository_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: repository_table_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_table_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_table_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_table_states_id_seq OWNED BY public.repository_table_states.id;


--
-- Name: repository_text_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_text_values (
    id bigint NOT NULL,
    data character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by_id bigint NOT NULL,
    last_modified_by_id bigint NOT NULL
);


--
-- Name: repository_text_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_text_values_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_text_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_text_values_id_seq OWNED BY public.repository_text_values.id;


--
-- Name: result_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.result_assets (
    id bigint NOT NULL,
    result_id bigint NOT NULL,
    asset_id bigint NOT NULL
);


--
-- Name: result_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.result_assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.result_assets_id_seq OWNED BY public.result_assets.id;


--
-- Name: result_tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.result_tables (
    id bigint NOT NULL,
    result_id bigint NOT NULL,
    table_id bigint NOT NULL
);


--
-- Name: result_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.result_tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.result_tables_id_seq OWNED BY public.result_tables.id;


--
-- Name: result_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.result_texts (
    id bigint NOT NULL,
    text character varying NOT NULL,
    result_id bigint NOT NULL
);


--
-- Name: result_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.result_texts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.result_texts_id_seq OWNED BY public.result_texts.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.results (
    id bigint NOT NULL,
    name character varying,
    my_module_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    archived_on timestamp without time zone,
    last_modified_by_id bigint,
    archived_by_id bigint,
    restored_by_id bigint,
    restored_on timestamp without time zone
);


--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.results_id_seq OWNED BY public.results.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    type text NOT NULL,
    "values" jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: step_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.step_assets (
    id bigint NOT NULL,
    step_id bigint NOT NULL,
    asset_id bigint NOT NULL
);


--
-- Name: step_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.step_assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: step_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.step_assets_id_seq OWNED BY public.step_assets.id;


--
-- Name: step_orderable_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.step_orderable_elements (
    id bigint NOT NULL,
    step_id bigint NOT NULL,
    "position" integer,
    orderable_type character varying,
    orderable_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: step_orderable_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.step_orderable_elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: step_orderable_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.step_orderable_elements_id_seq OWNED BY public.step_orderable_elements.id;


--
-- Name: step_tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.step_tables (
    id bigint NOT NULL,
    step_id bigint NOT NULL,
    table_id bigint NOT NULL
);


--
-- Name: step_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.step_tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: step_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.step_tables_id_seq OWNED BY public.step_tables.id;


--
-- Name: step_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.step_texts (
    id bigint NOT NULL,
    step_id bigint NOT NULL,
    text character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: step_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.step_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: step_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.step_texts_id_seq OWNED BY public.step_texts.id;


--
-- Name: steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.steps (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    "position" integer NOT NULL,
    completed boolean NOT NULL,
    completed_on timestamp without time zone,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_modified_by_id bigint,
    protocol_id bigint NOT NULL,
    assets_view_mode integer DEFAULT 0 NOT NULL
);


--
-- Name: steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.steps_id_seq OWNED BY public.steps.id;


--
-- Name: system_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_notifications (
    id bigint NOT NULL,
    title character varying,
    description text,
    modal_title character varying,
    modal_body text,
    show_on_login boolean DEFAULT false,
    source_created_at timestamp without time zone,
    source_id bigint,
    last_time_changed_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: system_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_notifications_id_seq OWNED BY public.system_notifications.id;


--
-- Name: tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tables (
    id bigint NOT NULL,
    contents bytea NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint,
    data_vector tsvector,
    name character varying DEFAULT ''::character varying,
    team_id integer,
    metadata jsonb
);


--
-- Name: tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tables_id_seq OWNED BY public.tables.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color character varying DEFAULT '#ff0000'::character varying NOT NULL,
    project_id bigint NOT NULL,
    created_by_id bigint,
    last_modified_by_id bigint
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
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
-- Name: team_shared_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_shared_objects (
    id bigint NOT NULL,
    team_id bigint,
    shared_object_id bigint,
    permission_level integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    shared_object_type character varying
);


--
-- Name: team_shared_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_shared_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_shared_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_shared_objects_id_seq OWNED BY public.team_shared_objects.id;


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: temp_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.temp_files (
    id bigint NOT NULL,
    session_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: temp_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.temp_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temp_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.temp_files_id_seq OWNED BY public.temp_files.id;


--
-- Name: tiny_mce_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tiny_mce_assets (
    id bigint NOT NULL,
    estimated_size integer DEFAULT 0 NOT NULL,
    team_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    saved boolean DEFAULT true,
    object_type character varying,
    object_id bigint
);


--
-- Name: tiny_mce_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tiny_mce_assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tiny_mce_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tiny_mce_assets_id_seq OWNED BY public.tiny_mce_assets.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    id bigint NOT NULL,
    token character varying NOT NULL,
    ttl integer NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tokens_id_seq OWNED BY public.tokens.id;


--
-- Name: user_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_assignments (
    id bigint NOT NULL,
    assignable_type character varying NOT NULL,
    assignable_id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_role_id bigint NOT NULL,
    assigned_by_id bigint,
    assigned integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    team_id bigint
);


--
-- Name: user_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_assignments_id_seq OWNED BY public.user_assignments.id;


--
-- Name: user_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_identities (
    id bigint NOT NULL,
    user_id integer,
    provider character varying NOT NULL,
    uid character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_identities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_identities_id_seq OWNED BY public.user_identities.id;


--
-- Name: user_my_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_my_modules (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    my_module_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_by_id bigint
);


--
-- Name: user_my_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_my_modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_my_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_my_modules_id_seq OWNED BY public.user_my_modules.id;


--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notifications (
    id bigint NOT NULL,
    user_id bigint,
    notification_id bigint,
    checked boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_notifications_id_seq OWNED BY public.user_notifications.id;


--
-- Name: user_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_projects (
    id bigint NOT NULL,
    role integer,
    user_id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assigned_by_id bigint
);


--
-- Name: user_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_projects_id_seq OWNED BY public.user_projects.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id bigint NOT NULL,
    name character varying,
    predefined boolean DEFAULT false,
    permissions character varying[] DEFAULT '{}'::character varying[],
    created_by_id bigint,
    last_modified_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: user_system_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_system_notifications (
    id bigint NOT NULL,
    user_id bigint,
    system_notification_id bigint,
    seen_at timestamp without time zone,
    read_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_system_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_system_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_system_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_system_notifications_id_seq OWNED BY public.user_system_notifications.id;


--
-- Name: user_teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_teams_id_seq OWNED BY public.user_teams.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    full_name character varying NOT NULL,
    initials character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_type character varying,
    invited_by_id integer,
    invitations_count integer DEFAULT 0,
    current_team_id bigint,
    authentication_token character varying(30),
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    variables jsonb DEFAULT '{}'::jsonb NOT NULL,
    two_factor_auth_enabled boolean DEFAULT false NOT NULL,
    otp_secret character varying,
    otp_recovery_codes jsonb,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp without time zone,
    unlock_token character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: view_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.view_states (
    id bigint NOT NULL,
    state jsonb,
    user_id bigint,
    viewable_type character varying,
    viewable_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: view_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.view_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: view_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.view_states_id_seq OWNED BY public.view_states.id;


--
-- Name: webhooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhooks (
    id bigint NOT NULL,
    activity_filter_id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    url character varying NOT NULL,
    http_method integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_error text,
    text text,
    secret_key character varying
);


--
-- Name: webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhooks_id_seq OWNED BY public.webhooks.id;


--
-- Name: wopi_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wopi_actions (
    id bigint NOT NULL,
    action character varying NOT NULL,
    extension character varying NOT NULL,
    urlsrc character varying NOT NULL,
    wopi_app_id bigint NOT NULL
);


--
-- Name: wopi_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wopi_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wopi_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wopi_actions_id_seq OWNED BY public.wopi_actions.id;


--
-- Name: wopi_apps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wopi_apps (
    id bigint NOT NULL,
    name character varying NOT NULL,
    icon character varying NOT NULL,
    wopi_discovery_id bigint NOT NULL
);


--
-- Name: wopi_apps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wopi_apps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wopi_apps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wopi_apps_id_seq OWNED BY public.wopi_apps.id;


--
-- Name: wopi_discoveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wopi_discoveries (
    id bigint NOT NULL,
    expires integer NOT NULL,
    proof_key_mod character varying NOT NULL,
    proof_key_exp character varying NOT NULL,
    proof_key_old_mod character varying NOT NULL,
    proof_key_old_exp character varying NOT NULL
);


--
-- Name: wopi_discoveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wopi_discoveries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wopi_discoveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wopi_discoveries_id_seq OWNED BY public.wopi_discoveries.id;


--
-- Name: zip_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zip_exports (
    id bigint NOT NULL,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying
);


--
-- Name: zip_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zip_exports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zip_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zip_exports_id_seq OWNED BY public.zip_exports.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: activity_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_filters ALTER COLUMN id SET DEFAULT nextval('public.activity_filters_id_seq'::regclass);


--
-- Name: asset_text_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_text_data ALTER COLUMN id SET DEFAULT nextval('public.asset_text_data_id_seq'::regclass);


--
-- Name: assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: bmt_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bmt_filters ALTER COLUMN id SET DEFAULT nextval('public.bmt_filters_id_seq'::regclass);


--
-- Name: checklist_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_items ALTER COLUMN id SET DEFAULT nextval('public.checklist_items_id_seq'::regclass);


--
-- Name: checklists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklists ALTER COLUMN id SET DEFAULT nextval('public.checklists_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections ALTER COLUMN id SET DEFAULT nextval('public.connections_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: experiments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments ALTER COLUMN id SET DEFAULT nextval('public.experiments_id_seq'::regclass);


--
-- Name: hidden_repository_cell_reminders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_repository_cell_reminders ALTER COLUMN id SET DEFAULT nextval('public.hidden_repository_cell_reminders_id_seq'::regclass);


--
-- Name: label_printers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_printers ALTER COLUMN id SET DEFAULT nextval('public.label_printers_id_seq'::regclass);


--
-- Name: label_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_templates ALTER COLUMN id SET DEFAULT nextval('public.label_templates_id_seq'::regclass);


--
-- Name: my_module_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_groups ALTER COLUMN id SET DEFAULT nextval('public.my_module_groups_id_seq'::regclass);


--
-- Name: my_module_repository_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_repository_rows ALTER COLUMN id SET DEFAULT nextval('public.my_module_repository_rows_id_seq'::regclass);


--
-- Name: my_module_status_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_conditions ALTER COLUMN id SET DEFAULT nextval('public.my_module_status_conditions_id_seq'::regclass);


--
-- Name: my_module_status_consequences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_consequences ALTER COLUMN id SET DEFAULT nextval('public.my_module_status_consequences_id_seq'::regclass);


--
-- Name: my_module_status_flows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_flows ALTER COLUMN id SET DEFAULT nextval('public.my_module_status_flows_id_seq'::regclass);


--
-- Name: my_module_status_implications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_implications ALTER COLUMN id SET DEFAULT nextval('public.my_module_status_implications_id_seq'::regclass);


--
-- Name: my_module_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_statuses ALTER COLUMN id SET DEFAULT nextval('public.my_module_statuses_id_seq'::regclass);


--
-- Name: my_module_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_tags ALTER COLUMN id SET DEFAULT nextval('public.my_module_tags_id_seq'::regclass);


--
-- Name: my_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules ALTER COLUMN id SET DEFAULT nextval('public.my_modules_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: project_folders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders ALTER COLUMN id SET DEFAULT nextval('public.project_folders_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: protocol_keywords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_keywords ALTER COLUMN id SET DEFAULT nextval('public.protocol_keywords_id_seq'::regclass);


--
-- Name: protocol_protocol_keywords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_protocol_keywords ALTER COLUMN id SET DEFAULT nextval('public.protocol_protocol_keywords_id_seq'::regclass);


--
-- Name: protocols id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols ALTER COLUMN id SET DEFAULT nextval('public.protocols_id_seq'::regclass);


--
-- Name: report_elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements ALTER COLUMN id SET DEFAULT nextval('public.report_elements_id_seq'::regclass);


--
-- Name: report_template_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_template_values ALTER COLUMN id SET DEFAULT nextval('public.report_template_values_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories ALTER COLUMN id SET DEFAULT nextval('public.repositories_id_seq'::regclass);


--
-- Name: repository_asset_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_asset_values ALTER COLUMN id SET DEFAULT nextval('public.repository_asset_values_id_seq'::regclass);


--
-- Name: repository_cells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_cells ALTER COLUMN id SET DEFAULT nextval('public.repository_cells_id_seq'::regclass);


--
-- Name: repository_checklist_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items ALTER COLUMN id SET DEFAULT nextval('public.repository_checklist_items_id_seq'::regclass);


--
-- Name: repository_checklist_items_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items_values ALTER COLUMN id SET DEFAULT nextval('public.repository_checklist_items_values_id_seq'::regclass);


--
-- Name: repository_checklist_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_values ALTER COLUMN id SET DEFAULT nextval('public.repository_checklist_values_id_seq'::regclass);


--
-- Name: repository_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_columns ALTER COLUMN id SET DEFAULT nextval('public.repository_columns_id_seq'::regclass);


--
-- Name: repository_date_time_range_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_range_values ALTER COLUMN id SET DEFAULT nextval('public.repository_date_time_range_values_id_seq'::regclass);


--
-- Name: repository_date_time_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_values ALTER COLUMN id SET DEFAULT nextval('public.repository_date_time_values_id_seq'::regclass);


--
-- Name: repository_ledger_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ledger_records ALTER COLUMN id SET DEFAULT nextval('public.repository_ledger_records_id_seq'::regclass);


--
-- Name: repository_list_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_items ALTER COLUMN id SET DEFAULT nextval('public.repository_list_items_id_seq'::regclass);


--
-- Name: repository_list_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_values ALTER COLUMN id SET DEFAULT nextval('public.repository_list_values_id_seq'::regclass);


--
-- Name: repository_number_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_number_values ALTER COLUMN id SET DEFAULT nextval('public.repository_number_values_id_seq'::regclass);


--
-- Name: repository_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows ALTER COLUMN id SET DEFAULT nextval('public.repository_rows_id_seq'::regclass);


--
-- Name: repository_status_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_items ALTER COLUMN id SET DEFAULT nextval('public.repository_status_items_id_seq'::regclass);


--
-- Name: repository_status_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_values ALTER COLUMN id SET DEFAULT nextval('public.repository_status_values_id_seq'::regclass);


--
-- Name: repository_stock_unit_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_unit_items ALTER COLUMN id SET DEFAULT nextval('public.repository_stock_unit_items_id_seq'::regclass);


--
-- Name: repository_stock_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_values ALTER COLUMN id SET DEFAULT nextval('public.repository_stock_values_id_seq'::regclass);


--
-- Name: repository_table_filter_elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_filter_elements ALTER COLUMN id SET DEFAULT nextval('public.repository_table_filter_elements_id_seq'::regclass);


--
-- Name: repository_table_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_filters ALTER COLUMN id SET DEFAULT nextval('public.repository_table_filters_id_seq'::regclass);


--
-- Name: repository_table_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_states ALTER COLUMN id SET DEFAULT nextval('public.repository_table_states_id_seq'::regclass);


--
-- Name: repository_text_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_text_values ALTER COLUMN id SET DEFAULT nextval('public.repository_text_values_id_seq'::regclass);


--
-- Name: result_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_assets ALTER COLUMN id SET DEFAULT nextval('public.result_assets_id_seq'::regclass);


--
-- Name: result_tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_tables ALTER COLUMN id SET DEFAULT nextval('public.result_tables_id_seq'::regclass);


--
-- Name: result_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_texts ALTER COLUMN id SET DEFAULT nextval('public.result_texts_id_seq'::regclass);


--
-- Name: results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results ALTER COLUMN id SET DEFAULT nextval('public.results_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: step_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_assets ALTER COLUMN id SET DEFAULT nextval('public.step_assets_id_seq'::regclass);


--
-- Name: step_orderable_elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_orderable_elements ALTER COLUMN id SET DEFAULT nextval('public.step_orderable_elements_id_seq'::regclass);


--
-- Name: step_tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_tables ALTER COLUMN id SET DEFAULT nextval('public.step_tables_id_seq'::regclass);


--
-- Name: step_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_texts ALTER COLUMN id SET DEFAULT nextval('public.step_texts_id_seq'::regclass);


--
-- Name: steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steps ALTER COLUMN id SET DEFAULT nextval('public.steps_id_seq'::regclass);


--
-- Name: system_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_notifications ALTER COLUMN id SET DEFAULT nextval('public.system_notifications_id_seq'::regclass);


--
-- Name: tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tables ALTER COLUMN id SET DEFAULT nextval('public.tables_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: team_shared_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_shared_objects ALTER COLUMN id SET DEFAULT nextval('public.team_shared_objects_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: temp_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_files ALTER COLUMN id SET DEFAULT nextval('public.temp_files_id_seq'::regclass);


--
-- Name: tiny_mce_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiny_mce_assets ALTER COLUMN id SET DEFAULT nextval('public.tiny_mce_assets_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens ALTER COLUMN id SET DEFAULT nextval('public.tokens_id_seq'::regclass);


--
-- Name: user_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments ALTER COLUMN id SET DEFAULT nextval('public.user_assignments_id_seq'::regclass);


--
-- Name: user_identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities ALTER COLUMN id SET DEFAULT nextval('public.user_identities_id_seq'::regclass);


--
-- Name: user_my_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_my_modules ALTER COLUMN id SET DEFAULT nextval('public.user_my_modules_id_seq'::regclass);


--
-- Name: user_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications ALTER COLUMN id SET DEFAULT nextval('public.user_notifications_id_seq'::regclass);


--
-- Name: user_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects ALTER COLUMN id SET DEFAULT nextval('public.user_projects_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: user_system_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_system_notifications ALTER COLUMN id SET DEFAULT nextval('public.user_system_notifications_id_seq'::regclass);


--
-- Name: user_teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_teams ALTER COLUMN id SET DEFAULT nextval('public.user_teams_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: view_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.view_states ALTER COLUMN id SET DEFAULT nextval('public.view_states_id_seq'::regclass);


--
-- Name: webhooks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks ALTER COLUMN id SET DEFAULT nextval('public.webhooks_id_seq'::regclass);


--
-- Name: wopi_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_actions ALTER COLUMN id SET DEFAULT nextval('public.wopi_actions_id_seq'::regclass);


--
-- Name: wopi_apps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_apps ALTER COLUMN id SET DEFAULT nextval('public.wopi_apps_id_seq'::regclass);


--
-- Name: wopi_discoveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_discoveries ALTER COLUMN id SET DEFAULT nextval('public.wopi_discoveries_id_seq'::regclass);


--
-- Name: zip_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_exports ALTER COLUMN id SET DEFAULT nextval('public.zip_exports_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_filters activity_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_filters
    ADD CONSTRAINT activity_filters_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: asset_text_data asset_text_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_text_data
    ADD CONSTRAINT asset_text_data_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: bmt_filters bmt_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bmt_filters
    ADD CONSTRAINT bmt_filters_pkey PRIMARY KEY (id);


--
-- Name: checklist_items checklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT checklist_items_pkey PRIMARY KEY (id);


--
-- Name: checklists checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklists
    ADD CONSTRAINT checklists_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: experiments experiments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_pkey PRIMARY KEY (id);


--
-- Name: hidden_repository_cell_reminders hidden_repository_cell_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_repository_cell_reminders
    ADD CONSTRAINT hidden_repository_cell_reminders_pkey PRIMARY KEY (id);


--
-- Name: label_printers label_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_printers
    ADD CONSTRAINT label_printers_pkey PRIMARY KEY (id);


--
-- Name: label_templates label_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_templates
    ADD CONSTRAINT label_templates_pkey PRIMARY KEY (id);


--
-- Name: my_module_groups my_module_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_groups
    ADD CONSTRAINT my_module_groups_pkey PRIMARY KEY (id);


--
-- Name: my_module_repository_rows my_module_repository_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_repository_rows
    ADD CONSTRAINT my_module_repository_rows_pkey PRIMARY KEY (id);


--
-- Name: my_module_status_conditions my_module_status_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_conditions
    ADD CONSTRAINT my_module_status_conditions_pkey PRIMARY KEY (id);


--
-- Name: my_module_status_consequences my_module_status_consequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_consequences
    ADD CONSTRAINT my_module_status_consequences_pkey PRIMARY KEY (id);


--
-- Name: my_module_status_flows my_module_status_flows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_flows
    ADD CONSTRAINT my_module_status_flows_pkey PRIMARY KEY (id);


--
-- Name: my_module_status_implications my_module_status_implications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_implications
    ADD CONSTRAINT my_module_status_implications_pkey PRIMARY KEY (id);


--
-- Name: my_module_statuses my_module_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_statuses
    ADD CONSTRAINT my_module_statuses_pkey PRIMARY KEY (id);


--
-- Name: my_module_tags my_module_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_tags
    ADD CONSTRAINT my_module_tags_pkey PRIMARY KEY (id);


--
-- Name: my_modules my_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT my_modules_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: project_folders project_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders
    ADD CONSTRAINT project_folders_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: protocol_keywords protocol_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_keywords
    ADD CONSTRAINT protocol_keywords_pkey PRIMARY KEY (id);


--
-- Name: protocol_protocol_keywords protocol_protocol_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_protocol_keywords
    ADD CONSTRAINT protocol_protocol_keywords_pkey PRIMARY KEY (id);


--
-- Name: protocols protocols_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: report_elements report_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT report_elements_pkey PRIMARY KEY (id);


--
-- Name: report_template_values report_template_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_template_values
    ADD CONSTRAINT report_template_values_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: repositories repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: repository_asset_values repository_asset_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_asset_values
    ADD CONSTRAINT repository_asset_values_pkey PRIMARY KEY (id);


--
-- Name: repository_cells repository_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_cells
    ADD CONSTRAINT repository_cells_pkey PRIMARY KEY (id);


--
-- Name: repository_checklist_items repository_checklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items
    ADD CONSTRAINT repository_checklist_items_pkey PRIMARY KEY (id);


--
-- Name: repository_checklist_items_values repository_checklist_items_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items_values
    ADD CONSTRAINT repository_checklist_items_values_pkey PRIMARY KEY (id);


--
-- Name: repository_checklist_values repository_checklist_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_values
    ADD CONSTRAINT repository_checklist_values_pkey PRIMARY KEY (id);


--
-- Name: repository_columns repository_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_columns
    ADD CONSTRAINT repository_columns_pkey PRIMARY KEY (id);


--
-- Name: repository_date_time_range_values repository_date_time_range_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_range_values
    ADD CONSTRAINT repository_date_time_range_values_pkey PRIMARY KEY (id);


--
-- Name: repository_date_time_values repository_date_time_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_values
    ADD CONSTRAINT repository_date_time_values_pkey PRIMARY KEY (id);


--
-- Name: repository_ledger_records repository_ledger_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ledger_records
    ADD CONSTRAINT repository_ledger_records_pkey PRIMARY KEY (id);


--
-- Name: repository_list_items repository_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_items
    ADD CONSTRAINT repository_list_items_pkey PRIMARY KEY (id);


--
-- Name: repository_list_values repository_list_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_values
    ADD CONSTRAINT repository_list_values_pkey PRIMARY KEY (id);


--
-- Name: repository_number_values repository_number_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_number_values
    ADD CONSTRAINT repository_number_values_pkey PRIMARY KEY (id);


--
-- Name: repository_rows repository_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows
    ADD CONSTRAINT repository_rows_pkey PRIMARY KEY (id);


--
-- Name: repository_status_items repository_status_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_items
    ADD CONSTRAINT repository_status_items_pkey PRIMARY KEY (id);


--
-- Name: repository_status_values repository_status_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_values
    ADD CONSTRAINT repository_status_values_pkey PRIMARY KEY (id);


--
-- Name: repository_stock_unit_items repository_stock_unit_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_unit_items
    ADD CONSTRAINT repository_stock_unit_items_pkey PRIMARY KEY (id);


--
-- Name: repository_stock_values repository_stock_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_values
    ADD CONSTRAINT repository_stock_values_pkey PRIMARY KEY (id);


--
-- Name: repository_table_filter_elements repository_table_filter_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_filter_elements
    ADD CONSTRAINT repository_table_filter_elements_pkey PRIMARY KEY (id);


--
-- Name: repository_table_filters repository_table_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_filters
    ADD CONSTRAINT repository_table_filters_pkey PRIMARY KEY (id);


--
-- Name: repository_table_states repository_table_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_states
    ADD CONSTRAINT repository_table_states_pkey PRIMARY KEY (id);


--
-- Name: repository_text_values repository_text_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_text_values
    ADD CONSTRAINT repository_text_values_pkey PRIMARY KEY (id);


--
-- Name: result_assets result_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_assets
    ADD CONSTRAINT result_assets_pkey PRIMARY KEY (id);


--
-- Name: result_tables result_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_tables
    ADD CONSTRAINT result_tables_pkey PRIMARY KEY (id);


--
-- Name: result_texts result_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_texts
    ADD CONSTRAINT result_texts_pkey PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: step_assets step_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_assets
    ADD CONSTRAINT step_assets_pkey PRIMARY KEY (id);


--
-- Name: step_orderable_elements step_orderable_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_orderable_elements
    ADD CONSTRAINT step_orderable_elements_pkey PRIMARY KEY (id);


--
-- Name: step_tables step_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_tables
    ADD CONSTRAINT step_tables_pkey PRIMARY KEY (id);


--
-- Name: step_texts step_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_texts
    ADD CONSTRAINT step_texts_pkey PRIMARY KEY (id);


--
-- Name: steps steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steps
    ADD CONSTRAINT steps_pkey PRIMARY KEY (id);


--
-- Name: system_notifications system_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_notifications
    ADD CONSTRAINT system_notifications_pkey PRIMARY KEY (id);


--
-- Name: tables tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tables
    ADD CONSTRAINT tables_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: team_shared_objects team_shared_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_shared_objects
    ADD CONSTRAINT team_shared_objects_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: temp_files temp_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_files
    ADD CONSTRAINT temp_files_pkey PRIMARY KEY (id);


--
-- Name: tiny_mce_assets tiny_mce_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiny_mce_assets
    ADD CONSTRAINT tiny_mce_assets_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: user_assignments user_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments
    ADD CONSTRAINT user_assignments_pkey PRIMARY KEY (id);


--
-- Name: user_identities user_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_pkey PRIMARY KEY (id);


--
-- Name: user_my_modules user_my_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_my_modules
    ADD CONSTRAINT user_my_modules_pkey PRIMARY KEY (id);


--
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- Name: user_projects user_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT user_projects_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_system_notifications user_system_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_system_notifications
    ADD CONSTRAINT user_system_notifications_pkey PRIMARY KEY (id);


--
-- Name: user_teams user_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT user_teams_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: view_states view_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.view_states
    ADD CONSTRAINT view_states_pkey PRIMARY KEY (id);


--
-- Name: webhooks webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks
    ADD CONSTRAINT webhooks_pkey PRIMARY KEY (id);


--
-- Name: wopi_actions wopi_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_actions
    ADD CONSTRAINT wopi_actions_pkey PRIMARY KEY (id);


--
-- Name: wopi_apps wopi_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_apps
    ADD CONSTRAINT wopi_apps_pkey PRIMARY KEY (id);


--
-- Name: wopi_discoveries wopi_discoveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_discoveries
    ADD CONSTRAINT wopi_discoveries_pkey PRIMARY KEY (id);


--
-- Name: zip_exports zip_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_exports
    ADD CONSTRAINT zip_exports_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: delayed_jobs_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_queue ON public.delayed_jobs USING btree (queue);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_activities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_created_at ON public.activities USING btree (created_at);


--
-- Name: index_activities_on_created_at_and_team_id_and_no_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_created_at_and_team_id_and_no_project_id ON public.activities USING btree (created_at DESC, team_id) WHERE (project_id IS NULL);


--
-- Name: index_activities_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_experiment_id ON public.activities USING btree (experiment_id);


--
-- Name: index_activities_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_my_module_id ON public.activities USING btree (my_module_id);


--
-- Name: index_activities_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_owner_id ON public.activities USING btree (owner_id);


--
-- Name: index_activities_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_project_id ON public.activities USING btree (project_id);


--
-- Name: index_activities_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_subject_type_and_subject_id ON public.activities USING btree (subject_type, subject_id);


--
-- Name: index_activities_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_team_id ON public.activities USING btree (team_id);


--
-- Name: index_activities_on_type_of; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_type_of ON public.activities USING btree (type_of);


--
-- Name: index_asset_text_data_on_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_asset_text_data_on_asset_id ON public.asset_text_data USING btree (asset_id);


--
-- Name: index_asset_text_data_on_data_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_text_data_on_data_vector ON public.asset_text_data USING gin (data_vector);


--
-- Name: index_assets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_created_at ON public.assets USING btree (created_at);


--
-- Name: index_assets_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_created_by_id ON public.assets USING btree (created_by_id);


--
-- Name: index_assets_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_last_modified_by_id ON public.assets USING btree (last_modified_by_id);


--
-- Name: index_assets_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_team_id ON public.assets USING btree (team_id);


--
-- Name: index_bmt_filters_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bmt_filters_on_created_by_id ON public.bmt_filters USING btree (created_by_id);


--
-- Name: index_checklist_items_on_checklist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklist_items_on_checklist_id ON public.checklist_items USING btree (checklist_id);


--
-- Name: index_checklist_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklist_items_on_created_by_id ON public.checklist_items USING btree (created_by_id);


--
-- Name: index_checklist_items_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklist_items_on_last_modified_by_id ON public.checklist_items USING btree (last_modified_by_id);


--
-- Name: index_checklist_items_on_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklist_items_on_text ON public.checklist_items USING gin (public.trim_html_tags((text)::text) public.gin_trgm_ops);


--
-- Name: index_checklists_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklists_on_created_by_id ON public.checklists USING btree (created_by_id);


--
-- Name: index_checklists_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklists_on_last_modified_by_id ON public.checklists USING btree (last_modified_by_id);


--
-- Name: index_checklists_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklists_on_name ON public.checklists USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_checklists_on_step_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_checklists_on_step_id ON public.checklists USING btree (step_id);


--
-- Name: index_comments_on_associated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_associated_id ON public.comments USING btree (associated_id);


--
-- Name: index_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_created_at ON public.comments USING btree (created_at);


--
-- Name: index_comments_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_last_modified_by_id ON public.comments USING btree (last_modified_by_id);


--
-- Name: index_comments_on_message; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_message ON public.comments USING gin (public.trim_html_tags((message)::text) public.gin_trgm_ops);


--
-- Name: index_comments_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_type ON public.comments USING btree (type);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_connections_on_input_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connections_on_input_id ON public.connections USING btree (input_id);


--
-- Name: index_connections_on_output_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connections_on_output_id ON public.connections USING btree (output_id);


--
-- Name: index_experiments_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_archived_by_id ON public.experiments USING btree (archived_by_id);


--
-- Name: index_experiments_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_created_by_id ON public.experiments USING btree (created_by_id);


--
-- Name: index_experiments_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_description ON public.experiments USING gin (public.trim_html_tags(description) public.gin_trgm_ops);


--
-- Name: index_experiments_on_experiment_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_experiment_code ON public.experiments USING gin ((('EX'::text || id)) public.gin_trgm_ops);


--
-- Name: index_experiments_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_last_modified_by_id ON public.experiments USING btree (last_modified_by_id);


--
-- Name: index_experiments_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_name ON public.experiments USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_experiments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_project_id ON public.experiments USING btree (project_id);


--
-- Name: index_experiments_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_experiments_on_restored_by_id ON public.experiments USING btree (restored_by_id);


--
-- Name: index_hidden_repository_cell_reminders_on_repository_cell_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hidden_repository_cell_reminders_on_repository_cell_id ON public.hidden_repository_cell_reminders USING btree (repository_cell_id);


--
-- Name: index_hidden_repository_cell_reminders_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hidden_repository_cell_reminders_on_user_id ON public.hidden_repository_cell_reminders USING btree (user_id);


--
-- Name: index_label_templates_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_label_templates_on_created_by_id ON public.label_templates USING btree (created_by_id);


--
-- Name: index_label_templates_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_label_templates_on_last_modified_by_id ON public.label_templates USING btree (last_modified_by_id);


--
-- Name: index_label_templates_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_label_templates_on_team_id ON public.label_templates USING btree (team_id);


--
-- Name: index_my_module_groups_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_groups_on_created_by_id ON public.my_module_groups USING btree (created_by_id);


--
-- Name: index_my_module_groups_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_groups_on_experiment_id ON public.my_module_groups USING btree (experiment_id);


--
-- Name: index_my_module_ids_repository_row_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_my_module_ids_repository_row_ids ON public.my_module_repository_rows USING btree (my_module_id, repository_row_id);


--
-- Name: index_my_module_repository_rows_on_repository_row_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_repository_rows_on_repository_row_id ON public.my_module_repository_rows USING btree (repository_row_id);


--
-- Name: index_my_module_status_conditions_on_my_module_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_status_conditions_on_my_module_status_id ON public.my_module_status_conditions USING btree (my_module_status_id);


--
-- Name: index_my_module_status_consequences_on_my_module_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_status_consequences_on_my_module_status_id ON public.my_module_status_consequences USING btree (my_module_status_id);


--
-- Name: index_my_module_status_flows_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_status_flows_on_team_id ON public.my_module_status_flows USING btree (team_id);


--
-- Name: index_my_module_status_flows_on_visibility; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_status_flows_on_visibility ON public.my_module_status_flows USING btree (visibility);


--
-- Name: index_my_module_status_implications_on_my_module_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_status_implications_on_my_module_status_id ON public.my_module_status_implications USING btree (my_module_status_id);


--
-- Name: index_my_module_statuses_on_my_module_status_flow_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_statuses_on_my_module_status_flow_id ON public.my_module_statuses USING btree (my_module_status_flow_id);


--
-- Name: index_my_module_statuses_on_previous_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_my_module_statuses_on_previous_status_id ON public.my_module_statuses USING btree (previous_status_id);


--
-- Name: index_my_module_tags_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_tags_on_created_by_id ON public.my_module_tags USING btree (created_by_id);


--
-- Name: index_my_module_tags_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_tags_on_my_module_id ON public.my_module_tags USING btree (my_module_id);


--
-- Name: index_my_module_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_module_tags_on_tag_id ON public.my_module_tags USING btree (tag_id);


--
-- Name: index_my_modules_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_archived_by_id ON public.my_modules USING btree (archived_by_id);


--
-- Name: index_my_modules_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_created_by_id ON public.my_modules USING btree (created_by_id);


--
-- Name: index_my_modules_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_description ON public.my_modules USING gin (public.trim_html_tags((description)::text) public.gin_trgm_ops);


--
-- Name: index_my_modules_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_experiment_id ON public.my_modules USING btree (experiment_id);


--
-- Name: index_my_modules_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_last_modified_by_id ON public.my_modules USING btree (last_modified_by_id);


--
-- Name: index_my_modules_on_my_module_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_my_module_code ON public.my_modules USING gin ((('TA'::text || id)) public.gin_trgm_ops);


--
-- Name: index_my_modules_on_my_module_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_my_module_group_id ON public.my_modules USING btree (my_module_group_id);


--
-- Name: index_my_modules_on_my_module_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_my_module_status_id ON public.my_modules USING btree (my_module_status_id);


--
-- Name: index_my_modules_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_name ON public.my_modules USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_my_modules_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_my_modules_on_restored_by_id ON public.my_modules USING btree (restored_by_id);


--
-- Name: index_notifications_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_created_at ON public.notifications USING btree (created_at);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_on_rep_status_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_rep_status_type_id ON public.repository_status_values USING btree (repository_status_item_id);


--
-- Name: index_on_repository_checklist_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_repository_checklist_item_id ON public.repository_checklist_items_values USING btree (repository_checklist_item_id);


--
-- Name: index_on_repository_checklist_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_repository_checklist_value_id ON public.repository_checklist_items_values USING btree (repository_checklist_value_id);


--
-- Name: index_on_repository_stock_unit_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_repository_stock_unit_item_id ON public.my_module_repository_rows USING btree (repository_stock_unit_item_id);


--
-- Name: index_on_repository_table_filter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_repository_table_filter_id ON public.repository_table_filter_elements USING btree (repository_table_filter_id);


--
-- Name: index_project_folders_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_folders_on_name ON public.project_folders USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_project_folders_on_parent_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_folders_on_parent_folder_id ON public.project_folders USING btree (parent_folder_id);


--
-- Name: index_project_folders_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_folders_on_team_id ON public.project_folders USING btree (team_id);


--
-- Name: index_projects_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_archived_by_id ON public.projects USING btree (archived_by_id);


--
-- Name: index_projects_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_created_by_id ON public.projects USING btree (created_by_id);


--
-- Name: index_projects_on_default_public_user_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_default_public_user_role_id ON public.projects USING btree (default_public_user_role_id);


--
-- Name: index_projects_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_last_modified_by_id ON public.projects USING btree (last_modified_by_id);


--
-- Name: index_projects_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_name ON public.projects USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_projects_on_project_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_project_code ON public.projects USING gin ((('PR'::text || id)) public.gin_trgm_ops);


--
-- Name: index_projects_on_project_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_project_folder_id ON public.projects USING btree (project_folder_id);


--
-- Name: index_projects_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_restored_by_id ON public.projects USING btree (restored_by_id);


--
-- Name: index_projects_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_team_id ON public.projects USING btree (team_id);


--
-- Name: index_protocol_keywords_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocol_keywords_on_name ON public.protocol_keywords USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_protocol_keywords_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocol_keywords_on_team_id ON public.protocol_keywords USING btree (team_id);


--
-- Name: index_protocol_protocol_keywords_on_protocol_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocol_protocol_keywords_on_protocol_id ON public.protocol_protocol_keywords USING btree (protocol_id);


--
-- Name: index_protocol_protocol_keywords_on_protocol_keyword_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocol_protocol_keywords_on_protocol_keyword_id ON public.protocol_protocol_keywords USING btree (protocol_keyword_id);


--
-- Name: index_protocols_on_added_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_added_by_id ON public.protocols USING btree (added_by_id);


--
-- Name: index_protocols_on_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_archived ON public.protocols USING btree (archived);


--
-- Name: index_protocols_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_archived_by_id ON public.protocols USING btree (archived_by_id);


--
-- Name: index_protocols_on_authors; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_authors ON public.protocols USING gin (public.trim_html_tags(authors) public.gin_trgm_ops);


--
-- Name: index_protocols_on_default_public_user_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_default_public_user_role_id ON public.protocols USING btree (default_public_user_role_id);


--
-- Name: index_protocols_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_description ON public.protocols USING gin (public.trim_html_tags(description) public.gin_trgm_ops);


--
-- Name: index_protocols_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_last_modified_by_id ON public.protocols USING btree (last_modified_by_id);


--
-- Name: index_protocols_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_my_module_id ON public.protocols USING btree (my_module_id);


--
-- Name: index_protocols_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_name ON public.protocols USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_protocols_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_parent_id ON public.protocols USING btree (parent_id);


--
-- Name: index_protocols_on_previous_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_previous_version_id ON public.protocols USING btree (previous_version_id);


--
-- Name: index_protocols_on_protocol_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_protocol_code ON public.protocols USING gin ((('PT'::text || id)) public.gin_trgm_ops);


--
-- Name: index_protocols_on_protocol_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_protocol_type ON public.protocols USING btree (protocol_type);


--
-- Name: index_protocols_on_published_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_published_by_id ON public.protocols USING btree (published_by_id);


--
-- Name: index_protocols_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_restored_by_id ON public.protocols USING btree (restored_by_id);


--
-- Name: index_protocols_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_team_id ON public.protocols USING btree (team_id);


--
-- Name: index_protocols_on_visibility; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_visibility ON public.protocols USING btree (visibility);


--
-- Name: index_report_elements_on_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_asset_id ON public.report_elements USING btree (asset_id);


--
-- Name: index_report_elements_on_checklist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_checklist_id ON public.report_elements USING btree (checklist_id);


--
-- Name: index_report_elements_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_experiment_id ON public.report_elements USING btree (experiment_id);


--
-- Name: index_report_elements_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_my_module_id ON public.report_elements USING btree (my_module_id);


--
-- Name: index_report_elements_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_parent_id ON public.report_elements USING btree (parent_id);


--
-- Name: index_report_elements_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_project_id ON public.report_elements USING btree (project_id);


--
-- Name: index_report_elements_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_report_id ON public.report_elements USING btree (report_id);


--
-- Name: index_report_elements_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_repository_id ON public.report_elements USING btree (repository_id);


--
-- Name: index_report_elements_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_result_id ON public.report_elements USING btree (result_id);


--
-- Name: index_report_elements_on_step_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_step_id ON public.report_elements USING btree (step_id);


--
-- Name: index_report_elements_on_table_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_elements_on_table_id ON public.report_elements USING btree (table_id);


--
-- Name: index_report_template_values_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_template_values_on_report_id ON public.report_template_values USING btree (report_id);


--
-- Name: index_report_template_values_on_view_component_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_template_values_on_view_component_name ON public.report_template_values USING btree (view_component, name);


--
-- Name: index_reports_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_description ON public.reports USING gin (public.trim_html_tags((description)::text) public.gin_trgm_ops);


--
-- Name: index_reports_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_last_modified_by_id ON public.reports USING btree (last_modified_by_id);


--
-- Name: index_reports_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_name ON public.reports USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_reports_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_project_id ON public.reports USING btree (project_id);


--
-- Name: index_reports_on_report_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_report_code ON public.reports USING gin ((('RP'::text || id)) public.gin_trgm_ops);


--
-- Name: index_reports_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_team_id ON public.reports USING btree (team_id);


--
-- Name: index_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_user_id ON public.reports USING btree (user_id);


--
-- Name: index_repositories_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_archived_by_id ON public.repositories USING btree (archived_by_id);


--
-- Name: index_repositories_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_discarded_at ON public.repositories USING btree (discarded_at);


--
-- Name: index_repositories_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_my_module_id ON public.repositories USING btree (my_module_id);


--
-- Name: index_repositories_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_restored_by_id ON public.repositories USING btree (restored_by_id);


--
-- Name: index_repositories_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_team_id ON public.repositories USING btree (team_id);


--
-- Name: index_repository_asset_values_on_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_asset_values_on_asset_id ON public.repository_asset_values USING btree (asset_id);


--
-- Name: index_repository_asset_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_asset_values_on_created_by_id ON public.repository_asset_values USING btree (created_by_id);


--
-- Name: index_repository_asset_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_asset_values_on_last_modified_by_id ON public.repository_asset_values USING btree (last_modified_by_id);


--
-- Name: index_repository_cells_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_cells_on_repository_column_id ON public.repository_cells USING btree (repository_column_id);


--
-- Name: index_repository_cells_on_repository_row_and_repository_column; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repository_cells_on_repository_row_and_repository_column ON public.repository_cells USING btree (repository_row_id, repository_column_id);


--
-- Name: index_repository_cells_on_repository_row_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_cells_on_repository_row_id ON public.repository_cells USING btree (repository_row_id);


--
-- Name: index_repository_cells_on_value_type_and_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_cells_on_value_type_and_value_id ON public.repository_cells USING btree (value_type, value_id);


--
-- Name: index_repository_checklist_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_items_on_created_by_id ON public.repository_checklist_items USING btree (created_by_id);


--
-- Name: index_repository_checklist_items_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_items_on_data ON public.repository_checklist_items USING gin (public.trim_html_tags((data)::text) public.gin_trgm_ops);


--
-- Name: index_repository_checklist_items_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_items_on_last_modified_by_id ON public.repository_checklist_items USING btree (last_modified_by_id);


--
-- Name: index_repository_checklist_items_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_items_on_repository_column_id ON public.repository_checklist_items USING btree (repository_column_id);


--
-- Name: index_repository_checklist_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_values_on_created_by_id ON public.repository_checklist_values USING btree (created_by_id);


--
-- Name: index_repository_checklist_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_checklist_values_on_last_modified_by_id ON public.repository_checklist_values USING btree (last_modified_by_id);


--
-- Name: index_repository_columns_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_columns_on_repository_id ON public.repository_columns USING btree (repository_id);


--
-- Name: index_repository_date_time_range_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_created_by_id ON public.repository_date_time_range_values USING btree (created_by_id);


--
-- Name: index_repository_date_time_range_values_on_end_time_as_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_end_time_as_date ON public.repository_date_time_range_values USING btree (((end_time)::date)) WHERE ((type)::text = 'RepositoryDateRangeValue'::text);


--
-- Name: index_repository_date_time_range_values_on_end_time_as_date_tim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_end_time_as_date_tim ON public.repository_date_time_range_values USING btree (end_time) WHERE ((type)::text = 'RepositoryDateTimeRangeValue'::text);


--
-- Name: index_repository_date_time_range_values_on_end_time_as_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_end_time_as_time ON public.repository_date_time_range_values USING btree (((end_time)::time without time zone)) WHERE ((type)::text = 'RepositoryTimeRangeValue'::text);


--
-- Name: index_repository_date_time_range_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_last_modified_by_id ON public.repository_date_time_range_values USING btree (last_modified_by_id);


--
-- Name: index_repository_date_time_range_values_on_start_time_as_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_start_time_as_date ON public.repository_date_time_range_values USING btree (((start_time)::date)) WHERE ((type)::text = 'RepositoryDateRangeValue'::text);


--
-- Name: index_repository_date_time_range_values_on_start_time_as_date_t; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_start_time_as_date_t ON public.repository_date_time_range_values USING btree (start_time) WHERE ((type)::text = 'RepositoryDateTimeRangeValue'::text);


--
-- Name: index_repository_date_time_range_values_on_start_time_as_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_range_values_on_start_time_as_time ON public.repository_date_time_range_values USING btree (((start_time)::time without time zone)) WHERE ((type)::text = 'RepositoryTimeRangeValue'::text);


--
-- Name: index_repository_date_time_values_on_data_as_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_values_on_data_as_date ON public.repository_date_time_values USING btree (((data)::date)) WHERE ((type)::text = 'RepositoryDateValue'::text);


--
-- Name: index_repository_date_time_values_on_data_as_date_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_values_on_data_as_date_time ON public.repository_date_time_values USING btree (data) WHERE ((type)::text = 'RepositoryDateTimeValue'::text);


--
-- Name: index_repository_date_time_values_on_data_as_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_date_time_values_on_data_as_time ON public.repository_date_time_values USING btree (((data)::time without time zone)) WHERE ((type)::text = 'RepositoryTimeValue'::text);


--
-- Name: index_repository_ledger_records_on_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ledger_records_on_reference ON public.repository_ledger_records USING btree (reference_type, reference_id);


--
-- Name: index_repository_ledger_records_on_repository_stock_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ledger_records_on_repository_stock_value_id ON public.repository_ledger_records USING btree (repository_stock_value_id);


--
-- Name: index_repository_ledger_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_ledger_records_on_user_id ON public.repository_ledger_records USING btree (user_id);


--
-- Name: index_repository_list_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_items_on_created_by_id ON public.repository_list_items USING btree (created_by_id);


--
-- Name: index_repository_list_items_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_items_on_data ON public.repository_list_items USING gin (public.trim_html_tags(data) public.gin_trgm_ops);


--
-- Name: index_repository_list_items_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_items_on_last_modified_by_id ON public.repository_list_items USING btree (last_modified_by_id);


--
-- Name: index_repository_list_items_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_items_on_repository_column_id ON public.repository_list_items USING btree (repository_column_id);


--
-- Name: index_repository_list_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_values_on_created_by_id ON public.repository_list_values USING btree (created_by_id);


--
-- Name: index_repository_list_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_values_on_last_modified_by_id ON public.repository_list_values USING btree (last_modified_by_id);


--
-- Name: index_repository_list_values_on_repository_list_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_list_values_on_repository_list_item_id ON public.repository_list_values USING btree (repository_list_item_id);


--
-- Name: index_repository_number_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_number_values_on_created_by_id ON public.repository_number_values USING btree (created_by_id);


--
-- Name: index_repository_number_values_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_number_values_on_data ON public.repository_number_values USING btree (data);


--
-- Name: index_repository_number_values_on_data_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_number_values_on_data_text ON public.repository_number_values USING gin (((data)::text) public.gin_trgm_ops);


--
-- Name: index_repository_number_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_number_values_on_last_modified_by_id ON public.repository_number_values USING btree (last_modified_by_id);


--
-- Name: index_repository_rows_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_archived_by_id ON public.repository_rows USING btree (archived_by_id);


--
-- Name: index_repository_rows_on_archived_on_as_date_time_minutes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_archived_on_as_date_time_minutes ON public.repository_rows USING btree (date_trunc('minute'::text, archived_on));


--
-- Name: index_repository_rows_on_created_at_as_date_time_minutes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_created_at_as_date_time_minutes ON public.repository_rows USING btree (date_trunc('minute'::text, created_at));


--
-- Name: index_repository_rows_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_external_id ON public.repository_rows USING gin (public.trim_html_tags((external_id)::text) public.gin_trgm_ops);


--
-- Name: index_repository_rows_on_id_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_id_text ON public.repository_rows USING gin (((id)::text) public.gin_trgm_ops);


--
-- Name: index_repository_rows_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_name ON public.repository_rows USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_repository_rows_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_repository_id ON public.repository_rows USING btree (repository_id);


--
-- Name: index_repository_rows_on_repository_row_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_repository_row_code ON public.repository_rows USING gin ((('IT'::text || id)) public.gin_trgm_ops);


--
-- Name: index_repository_rows_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_rows_on_restored_by_id ON public.repository_rows USING btree (restored_by_id);


--
-- Name: index_repository_status_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_items_on_created_by_id ON public.repository_status_items USING btree (created_by_id);


--
-- Name: index_repository_status_items_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_items_on_last_modified_by_id ON public.repository_status_items USING btree (last_modified_by_id);


--
-- Name: index_repository_status_items_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_items_on_repository_column_id ON public.repository_status_items USING btree (repository_column_id);


--
-- Name: index_repository_status_items_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_items_on_status ON public.repository_status_items USING gin (public.trim_html_tags((status)::text) public.gin_trgm_ops);


--
-- Name: index_repository_status_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_values_on_created_by_id ON public.repository_status_values USING btree (created_by_id);


--
-- Name: index_repository_status_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_status_values_on_last_modified_by_id ON public.repository_status_values USING btree (last_modified_by_id);


--
-- Name: index_repository_stock_unit_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_unit_items_on_created_by_id ON public.repository_stock_unit_items USING btree (created_by_id);


--
-- Name: index_repository_stock_unit_items_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_unit_items_on_data ON public.repository_stock_unit_items USING gin (public.trim_html_tags((data)::text) public.gin_trgm_ops);


--
-- Name: index_repository_stock_unit_items_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_unit_items_on_last_modified_by_id ON public.repository_stock_unit_items USING btree (last_modified_by_id);


--
-- Name: index_repository_stock_unit_items_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_unit_items_on_repository_column_id ON public.repository_stock_unit_items USING btree (repository_column_id);


--
-- Name: index_repository_stock_values_on_amount; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_values_on_amount ON public.repository_stock_values USING btree (amount);


--
-- Name: index_repository_stock_values_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_values_on_created_by_id ON public.repository_stock_values USING btree (created_by_id);


--
-- Name: index_repository_stock_values_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_values_on_last_modified_by_id ON public.repository_stock_values USING btree (last_modified_by_id);


--
-- Name: index_repository_stock_values_on_repository_stock_unit_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_stock_values_on_repository_stock_unit_item_id ON public.repository_stock_values USING btree (repository_stock_unit_item_id);


--
-- Name: index_repository_table_filter_elements_on_repository_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_table_filter_elements_on_repository_column_id ON public.repository_table_filter_elements USING btree (repository_column_id);


--
-- Name: index_repository_table_filters_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_table_filters_on_created_by_id ON public.repository_table_filters USING btree (created_by_id);


--
-- Name: index_repository_table_filters_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_table_filters_on_repository_id ON public.repository_table_filters USING btree (repository_id);


--
-- Name: index_repository_table_states_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_table_states_on_repository_id ON public.repository_table_states USING btree (repository_id);


--
-- Name: index_repository_table_states_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_table_states_on_user_id ON public.repository_table_states USING btree (user_id);


--
-- Name: index_repository_text_values_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_text_values_on_data ON public.repository_text_values USING gin (public.trim_html_tags((data)::text) public.gin_trgm_ops);


--
-- Name: index_result_assets_on_result_id_and_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_assets_on_result_id_and_asset_id ON public.result_assets USING btree (result_id, asset_id);


--
-- Name: index_result_tables_on_result_id_and_table_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_tables_on_result_id_and_table_id ON public.result_tables USING btree (result_id, table_id);


--
-- Name: index_result_texts_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_texts_on_result_id ON public.result_texts USING btree (result_id);


--
-- Name: index_result_texts_on_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_texts_on_text ON public.result_texts USING gin (public.trim_html_tags((text)::text) public.gin_trgm_ops);


--
-- Name: index_results_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_archived_by_id ON public.results USING btree (archived_by_id);


--
-- Name: index_results_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_created_at ON public.results USING btree (created_at);


--
-- Name: index_results_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_last_modified_by_id ON public.results USING btree (last_modified_by_id);


--
-- Name: index_results_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_my_module_id ON public.results USING btree (my_module_id);


--
-- Name: index_results_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_name ON public.results USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_results_on_restored_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_restored_by_id ON public.results USING btree (restored_by_id);


--
-- Name: index_results_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_user_id ON public.results USING btree (user_id);


--
-- Name: index_settings_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_type ON public.settings USING btree (type);


--
-- Name: index_step_assets_on_step_id_and_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_step_assets_on_step_id_and_asset_id ON public.step_assets USING btree (step_id, asset_id);


--
-- Name: index_step_orderable_elements_on_orderable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_step_orderable_elements_on_orderable ON public.step_orderable_elements USING btree (orderable_type, orderable_id);


--
-- Name: index_step_orderable_elements_on_step_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_step_orderable_elements_on_step_id ON public.step_orderable_elements USING btree (step_id);


--
-- Name: index_step_tables_on_step_id_and_table_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_step_tables_on_step_id_and_table_id ON public.step_tables USING btree (step_id, table_id);


--
-- Name: index_step_texts_on_step_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_step_texts_on_step_id ON public.step_texts USING btree (step_id);


--
-- Name: index_step_texts_on_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_step_texts_on_text ON public.step_texts USING gin (public.trim_html_tags((text)::text) public.gin_trgm_ops);


--
-- Name: index_steps_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_created_at ON public.steps USING btree (created_at);


--
-- Name: index_steps_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_description ON public.steps USING gin (public.trim_html_tags((description)::text) public.gin_trgm_ops);


--
-- Name: index_steps_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_last_modified_by_id ON public.steps USING btree (last_modified_by_id);


--
-- Name: index_steps_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_name ON public.steps USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_steps_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_position ON public.steps USING btree ("position");


--
-- Name: index_steps_on_protocol_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_protocol_id ON public.steps USING btree (protocol_id);


--
-- Name: index_steps_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steps_on_user_id ON public.steps USING btree (user_id);


--
-- Name: index_system_notifications_on_last_time_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_system_notifications_on_last_time_changed_at ON public.system_notifications USING btree (last_time_changed_at);


--
-- Name: index_system_notifications_on_source_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_system_notifications_on_source_created_at ON public.system_notifications USING btree (source_created_at);


--
-- Name: index_system_notifications_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_system_notifications_on_source_id ON public.system_notifications USING btree (source_id);


--
-- Name: index_tables_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_created_at ON public.tables USING btree (created_at);


--
-- Name: index_tables_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_created_by_id ON public.tables USING btree (created_by_id);


--
-- Name: index_tables_on_data_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_data_vector ON public.tables USING gin (data_vector);


--
-- Name: index_tables_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_last_modified_by_id ON public.tables USING btree (last_modified_by_id);


--
-- Name: index_tables_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_name ON public.tables USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_tables_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tables_on_team_id ON public.tables USING btree (team_id);


--
-- Name: index_tags_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_created_by_id ON public.tags USING btree (created_by_id);


--
-- Name: index_tags_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_last_modified_by_id ON public.tags USING btree (last_modified_by_id);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_name ON public.tags USING gin (public.trim_html_tags((name)::text) public.gin_trgm_ops);


--
-- Name: index_tags_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_project_id ON public.tags USING btree (project_id);


--
-- Name: index_team_shared_objects_on_shared_type_and_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_shared_objects_on_shared_type_and_id_and_team_id ON public.team_shared_objects USING btree (shared_object_type, shared_object_id, team_id);


--
-- Name: index_team_shared_objects_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_shared_objects_on_team_id ON public.team_shared_objects USING btree (team_id);


--
-- Name: index_teams_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_created_by_id ON public.teams USING btree (created_by_id);


--
-- Name: index_teams_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_last_modified_by_id ON public.teams USING btree (last_modified_by_id);


--
-- Name: index_teams_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_name ON public.teams USING btree (name);


--
-- Name: index_tiny_mce_assets_on_object_type_and_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tiny_mce_assets_on_object_type_and_object_id ON public.tiny_mce_assets USING btree (object_type, object_id);


--
-- Name: index_tiny_mce_assets_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tiny_mce_assets_on_team_id ON public.tiny_mce_assets USING btree (team_id);


--
-- Name: index_user_assignments_on_assignable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_assignments_on_assignable ON public.user_assignments USING btree (assignable_type, assignable_id);


--
-- Name: index_user_assignments_on_assigned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_assignments_on_assigned_by_id ON public.user_assignments USING btree (assigned_by_id);


--
-- Name: index_user_assignments_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_assignments_on_team_id ON public.user_assignments USING btree (team_id);


--
-- Name: index_user_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_assignments_on_user_id ON public.user_assignments USING btree (user_id);


--
-- Name: index_user_assignments_on_user_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_assignments_on_user_role_id ON public.user_assignments USING btree (user_role_id);


--
-- Name: index_user_identities_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_provider_and_uid ON public.user_identities USING btree (provider, uid);


--
-- Name: index_user_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_identities_on_user_id ON public.user_identities USING btree (user_id);


--
-- Name: index_user_identities_on_user_id_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_user_id_and_provider ON public.user_identities USING btree (user_id, provider);


--
-- Name: index_user_my_modules_on_assigned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_my_modules_on_assigned_by_id ON public.user_my_modules USING btree (assigned_by_id);


--
-- Name: index_user_my_modules_on_my_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_my_modules_on_my_module_id ON public.user_my_modules USING btree (my_module_id);


--
-- Name: index_user_my_modules_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_my_modules_on_user_id ON public.user_my_modules USING btree (user_id);


--
-- Name: index_user_notifications_on_checked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_checked ON public.user_notifications USING btree (checked);


--
-- Name: index_user_notifications_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_notification_id ON public.user_notifications USING btree (notification_id);


--
-- Name: index_user_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_user_id ON public.user_notifications USING btree (user_id);


--
-- Name: index_user_projects_on_assigned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_projects_on_assigned_by_id ON public.user_projects USING btree (assigned_by_id);


--
-- Name: index_user_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_projects_on_project_id ON public.user_projects USING btree (project_id);


--
-- Name: index_user_projects_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_projects_on_user_id ON public.user_projects USING btree (user_id);


--
-- Name: index_user_projects_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_projects_on_user_id_and_project_id ON public.user_projects USING btree (user_id, project_id);


--
-- Name: index_user_roles_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_created_by_id ON public.user_roles USING btree (created_by_id);


--
-- Name: index_user_roles_on_last_modified_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_last_modified_by_id ON public.user_roles USING btree (last_modified_by_id);


--
-- Name: index_user_system_notifications_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_system_notifications_on_read_at ON public.user_system_notifications USING btree (read_at);


--
-- Name: index_user_system_notifications_on_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_system_notifications_on_seen_at ON public.user_system_notifications USING btree (seen_at);


--
-- Name: index_user_system_notifications_on_system_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_system_notifications_on_system_notification_id ON public.user_system_notifications USING btree (system_notification_id);


--
-- Name: index_user_system_notifications_on_user_and_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_system_notifications_on_user_and_notification_id ON public.user_system_notifications USING btree (user_id, system_notification_id);


--
-- Name: index_user_system_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_system_notifications_on_user_id ON public.user_system_notifications USING btree (user_id);


--
-- Name: index_user_teams_on_assigned_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_teams_on_assigned_by_id ON public.user_teams USING btree (assigned_by_id);


--
-- Name: index_user_teams_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_teams_on_team_id ON public.user_teams USING btree (team_id);


--
-- Name: index_user_teams_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_teams_on_user_id ON public.user_teams USING btree (user_id);


--
-- Name: index_user_teams_on_user_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_teams_on_user_id_and_team_id ON public.user_teams USING btree (user_id, team_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON public.users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_full_name ON public.users USING gin (public.trim_html_tags((full_name)::text) public.gin_trgm_ops);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_view_states_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_view_states_on_user_id ON public.view_states USING btree (user_id);


--
-- Name: index_view_states_on_viewable_type_and_viewable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_view_states_on_viewable_type_and_viewable_id ON public.view_states USING btree (viewable_type, viewable_id);


--
-- Name: index_webhooks_on_activity_filter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhooks_on_activity_filter_id ON public.webhooks USING btree (activity_filter_id);


--
-- Name: index_wopi_actions_on_extension_and_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wopi_actions_on_extension_and_action ON public.wopi_actions USING btree (extension, action);


--
-- Name: index_zip_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zip_exports_on_user_id ON public.zip_exports USING btree (user_id);


--
-- Name: unique_index_repository_rows_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_repository_rows_on_external_id ON public.repository_rows USING btree (external_id);


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: report_elements fk_rails_050025324a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_050025324a FOREIGN KEY (report_id) REFERENCES public.reports(id);


--
-- Name: report_elements fk_rails_0510000a52; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_0510000a52 FOREIGN KEY (table_id) REFERENCES public.tables(id);


--
-- Name: project_folders fk_rails_05fe6e31fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders
    ADD CONSTRAINT fk_rails_05fe6e31fe FOREIGN KEY (parent_folder_id) REFERENCES public.project_folders(id);


--
-- Name: repository_ledger_records fk_rails_062bed0c26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_ledger_records
    ADD CONSTRAINT fk_rails_062bed0c26 FOREIGN KEY (repository_stock_value_id) REFERENCES public.repository_stock_values(id);


--
-- Name: hidden_repository_cell_reminders fk_rails_08be8c52e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_repository_cell_reminders
    ADD CONSTRAINT fk_rails_08be8c52e0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: repository_stock_values fk_rails_08ce900341; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_values
    ADD CONSTRAINT fk_rails_08ce900341 FOREIGN KEY (repository_stock_unit_item_id) REFERENCES public.repository_stock_unit_items(id);


--
-- Name: assets fk_rails_0916329f9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_rails_0916329f9e FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: label_templates fk_rails_09d7cc0c34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_templates
    ADD CONSTRAINT fk_rails_09d7cc0c34 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: user_assignments fk_rails_0b13c65ab0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments
    ADD CONSTRAINT fk_rails_0b13c65ab0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: my_modules fk_rails_0d264d93f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_0d264d93f8 FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: steps fk_rails_0f28e70afa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steps
    ADD CONSTRAINT fk_rails_0f28e70afa FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: repositories fk_rails_111f913cb7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_rails_111f913cb7 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_139478354a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_139478354a FOREIGN KEY (published_by_id) REFERENCES public.users(id);


--
-- Name: tables fk_rails_147b6eced4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tables
    ADD CONSTRAINT fk_rails_147b6eced4 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: team_shared_objects fk_rails_15daa6a6bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_shared_objects
    ADD CONSTRAINT fk_rails_15daa6a6bf FOREIGN KEY (shared_object_id) REFERENCES public.repositories(id);


--
-- Name: zip_exports fk_rails_1952fc2261; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_exports
    ADD CONSTRAINT fk_rails_1952fc2261 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_assignments fk_rails_19dca62dfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments
    ADD CONSTRAINT fk_rails_19dca62dfc FOREIGN KEY (user_role_id) REFERENCES public.user_roles(id);


--
-- Name: label_templates fk_rails_1aa41d1093; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_templates
    ADD CONSTRAINT fk_rails_1aa41d1093 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: user_system_notifications fk_rails_20d9487a3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_system_notifications
    ADD CONSTRAINT fk_rails_20d9487a3c FOREIGN KEY (system_notification_id) REFERENCES public.system_notifications(id);


--
-- Name: repository_list_items fk_rails_2335e4c02c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_items
    ADD CONSTRAINT fk_rails_2335e4c02c FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: connections fk_rails_23d19dbe67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT fk_rails_23d19dbe67 FOREIGN KEY (output_id) REFERENCES public.my_modules(id);


--
-- Name: user_system_notifications fk_rails_26dd7f4a47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_system_notifications
    ADD CONSTRAINT fk_rails_26dd7f4a47 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: connections fk_rails_27a1675060; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT fk_rails_27a1675060 FOREIGN KEY (input_id) REFERENCES public.my_modules(id);


--
-- Name: steps fk_rails_28e8f7466e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steps
    ADD CONSTRAINT fk_rails_28e8f7466e FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: user_my_modules fk_rails_29bdcb176c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_my_modules
    ADD CONSTRAINT fk_rails_29bdcb176c FOREIGN KEY (my_module_id) REFERENCES public.my_modules(id);


--
-- Name: activities fk_rails_2a8dd8e5f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT fk_rails_2a8dd8e5f4 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: my_modules fk_rails_2c8021ee5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_2c8021ee5f FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: step_texts fk_rails_2cc1715bcd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_texts
    ADD CONSTRAINT fk_rails_2cc1715bcd FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: repository_text_values fk_rails_2d9a33cbb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_text_values
    ADD CONSTRAINT fk_rails_2d9a33cbb0 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: asset_text_data fk_rails_2e588e7391; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_text_data
    ADD CONSTRAINT fk_rails_2e588e7391 FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: user_teams fk_rails_2f270d1725; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT fk_rails_2f270d1725 FOREIGN KEY (assigned_by_id) REFERENCES public.users(id);


--
-- Name: tags fk_rails_2f90b9163e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_2f90b9163e FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: my_modules fk_rails_312bc61327; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_312bc61327 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: oauth_access_grants fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: my_module_statuses fk_rails_357ee33309; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_statuses
    ADD CONSTRAINT fk_rails_357ee33309 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: experiments fk_rails_35ad21e487; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT fk_rails_35ad21e487 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: checklist_items fk_rails_3605ca8e4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT fk_rails_3605ca8e4d FOREIGN KEY (checklist_id) REFERENCES public.checklists(id);


--
-- Name: step_assets fk_rails_38ebde94cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_assets
    ADD CONSTRAINT fk_rails_38ebde94cb FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: repository_number_values fk_rails_3df53c9b27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_number_values
    ADD CONSTRAINT fk_rails_3df53c9b27 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: report_template_values fk_rails_423a0bad87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_template_values
    ADD CONSTRAINT fk_rails_423a0bad87 FOREIGN KEY (report_id) REFERENCES public.reports(id);


--
-- Name: my_modules fk_rails_4768515e2e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_4768515e2e FOREIGN KEY (changing_from_my_module_status_id) REFERENCES public.my_module_statuses(id);


--
-- Name: projects fk_rails_47aee20018; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_47aee20018 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: result_assets fk_rails_48803d79ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_assets
    ADD CONSTRAINT fk_rails_48803d79ff FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: user_assignments fk_rails_4a5764985b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments
    ADD CONSTRAINT fk_rails_4a5764985b FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: experiments fk_rails_4a63cb023e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT fk_rails_4a63cb023e FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: repository_stock_unit_items fk_rails_4c20ff4c1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_unit_items
    ADD CONSTRAINT fk_rails_4c20ff4c1f FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_4c4d4f815a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_4c4d4f815a FOREIGN KEY (default_public_user_role_id) REFERENCES public.user_roles(id);


--
-- Name: repository_status_values fk_rails_4cf67f9f1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_values
    ADD CONSTRAINT fk_rails_4cf67f9f1e FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: experiments fk_rails_4d671c16af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT fk_rails_4d671c16af FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_list_items fk_rails_4e75dc8e18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_items
    ADD CONSTRAINT fk_rails_4e75dc8e18 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_date_time_values fk_rails_5d809fca2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_values
    ADD CONSTRAINT fk_rails_5d809fca2c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: tags fk_rails_5f245fd6a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_5f245fd6a7 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: webhooks fk_rails_61458d031d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks
    ADD CONSTRAINT fk_rails_61458d031d FOREIGN KEY (activity_filter_id) REFERENCES public.activity_filters(id);


--
-- Name: user_my_modules fk_rails_62fa90cb51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_my_modules
    ADD CONSTRAINT fk_rails_62fa90cb51 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_assignments fk_rails_6467e12fc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_assignments
    ADD CONSTRAINT fk_rails_6467e12fc3 FOREIGN KEY (assigned_by_id) REFERENCES public.users(id);


--
-- Name: user_teams fk_rails_64c25f3fe6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT fk_rails_64c25f3fe6 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: repository_checklist_items fk_rails_664f0498be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items
    ADD CONSTRAINT fk_rails_664f0498be FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: projects fk_rails_6981ffffd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_6981ffffd4 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: projects fk_rails_6b025b17ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_6b025b17ca FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: repository_rows fk_rails_6b4114fff4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows
    ADD CONSTRAINT fk_rails_6b4114fff4 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: report_elements fk_rails_6cc9abd66b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_6cc9abd66b FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: repository_rows fk_rails_6d0c4bdace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows
    ADD CONSTRAINT fk_rails_6d0c4bdace FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_6f01627d5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_6f01627d5c FOREIGN KEY (current_team_id) REFERENCES public.teams(id);


--
-- Name: report_elements fk_rails_711b154213; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_711b154213 FOREIGN KEY (my_module_id) REFERENCES public.my_modules(id);


--
-- Name: report_elements fk_rails_712893ccb2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_712893ccb2 FOREIGN KEY (result_id) REFERENCES public.results(id);


--
-- Name: repository_rows fk_rails_7186e2b731; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows
    ADD CONSTRAINT fk_rails_7186e2b731 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: wopi_actions fk_rails_736b4e5a7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_actions
    ADD CONSTRAINT fk_rails_736b4e5a7d FOREIGN KEY (wopi_app_id) REFERENCES public.wopi_apps(id);


--
-- Name: protocols fk_rails_73d601aab1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_73d601aab1 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_status_items fk_rails_74e5e4cacc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_items
    ADD CONSTRAINT fk_rails_74e5e4cacc FOREIGN KEY (repository_column_id) REFERENCES public.repository_columns(id);


--
-- Name: project_folders fk_rails_7931975dd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders
    ADD CONSTRAINT fk_rails_7931975dd0 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: project_folders fk_rails_795296de66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders
    ADD CONSTRAINT fk_rails_795296de66 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: results fk_rails_79fcaa8e37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_rails_79fcaa8e37 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: my_module_repository_rows fk_rails_7b302dfece; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_repository_rows
    ADD CONSTRAINT fk_rails_7b302dfece FOREIGN KEY (repository_stock_unit_item_id) REFERENCES public.repository_stock_unit_items(id);


--
-- Name: repositories fk_rails_7b4cac148c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_rails_7b4cac148c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: checklist_items fk_rails_7b68a8f1d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT fk_rails_7b68a8f1d8 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_status_items fk_rails_7bc42f7363; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_items
    ADD CONSTRAINT fk_rails_7bc42f7363 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: activities fk_rails_7e11bb717f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT fk_rails_7e11bb717f FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: results fk_rails_7f0d5a2cd6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_rails_7f0d5a2cd6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: results fk_rails_8034d7ca7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_rails_8034d7ca7b FOREIGN KEY (my_module_id) REFERENCES public.my_modules(id);


--
-- Name: checklists fk_rails_803dbd5290; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklists
    ADD CONSTRAINT fk_rails_803dbd5290 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: report_elements fk_rails_831f89b951; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_831f89b951 FOREIGN KEY (checklist_id) REFERENCES public.checklists(id);


--
-- Name: repository_date_time_range_values fk_rails_87cdb60fa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_range_values
    ADD CONSTRAINT fk_rails_87cdb60fa9 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_checklist_items fk_rails_885781d47e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items
    ADD CONSTRAINT fk_rails_885781d47e FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: checklist_items fk_rails_887d280d4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT fk_rails_887d280d4d FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: my_modules fk_rails_8a801283d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_8a801283d1 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_8b9893a7ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_8b9893a7ff FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: comments fk_rails_8c4e16c503; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_8c4e16c503 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: wopi_apps fk_rails_8e13eee4a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wopi_apps
    ADD CONSTRAINT fk_rails_8e13eee4a9 FOREIGN KEY (wopi_discovery_id) REFERENCES public.wopi_discoveries(id);


--
-- Name: reports fk_rails_8e98747719; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_8e98747719 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_number_values fk_rails_8f8a2f87f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_number_values
    ADD CONSTRAINT fk_rails_8f8a2f87f1 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_list_values fk_rails_903285a9b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_values
    ADD CONSTRAINT fk_rails_903285a9b0 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_columns fk_rails_90670dacf2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_columns
    ADD CONSTRAINT fk_rails_90670dacf2 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: result_tables fk_rails_9269d5e204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_tables
    ADD CONSTRAINT fk_rails_9269d5e204 FOREIGN KEY (result_id) REFERENCES public.results(id);


--
-- Name: tables fk_rails_943e1b03e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tables
    ADD CONSTRAINT fk_rails_943e1b03e5 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repositories fk_rails_94481f7751; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_rails_94481f7751 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: steps fk_rails_954ff833e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steps
    ADD CONSTRAINT fk_rails_954ff833e4 FOREIGN KEY (protocol_id) REFERENCES public.protocols(id);


--
-- Name: step_tables fk_rails_97489f2789; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_tables
    ADD CONSTRAINT fk_rails_97489f2789 FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: user_teams fk_rails_978858c8ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_teams
    ADD CONSTRAINT fk_rails_978858c8ea FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_roles fk_rails_983264fab9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_rails_983264fab9 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_checklist_values fk_rails_98a7704432; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_values
    ADD CONSTRAINT fk_rails_98a7704432 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: hidden_repository_cell_reminders fk_rails_98e782ebf2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_repository_cell_reminders
    ADD CONSTRAINT fk_rails_98e782ebf2 FOREIGN KEY (repository_cell_id) REFERENCES public.repository_cells(id);


--
-- Name: activities fk_rails_992865be13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT fk_rails_992865be13 FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: reports fk_rails_9a0a9c9bec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_9a0a9c9bec FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: repository_status_items fk_rails_9acc03f846; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_items
    ADD CONSTRAINT fk_rails_9acc03f846 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: projects fk_rails_9b9763cd55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_9b9763cd55 FOREIGN KEY (default_public_user_role_id) REFERENCES public.user_roles(id);


--
-- Name: results fk_rails_9be849c454; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_rails_9be849c454 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: my_module_status_flows fk_rails_9c3936bd7a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_flows
    ADD CONSTRAINT fk_rails_9c3936bd7a FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_status_values fk_rails_9d357798c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_values
    ADD CONSTRAINT fk_rails_9d357798c5 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: step_tables fk_rails_9e0e7dea0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_tables
    ADD CONSTRAINT fk_rails_9e0e7dea0d FOREIGN KEY (table_id) REFERENCES public.tables(id);


--
-- Name: my_module_repository_rows fk_rails_9e9b0a61ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_repository_rows
    ADD CONSTRAINT fk_rails_9e9b0a61ec FOREIGN KEY (assigned_by_id) REFERENCES public.users(id);


--
-- Name: teams fk_rails_a068b3a692; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT fk_rails_a068b3a692 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_checklist_items fk_rails_a08ff8e2ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_items
    ADD CONSTRAINT fk_rails_a08ff8e2ba FOREIGN KEY (repository_column_id) REFERENCES public.repository_columns(id);


--
-- Name: my_module_groups fk_rails_a0acffc536; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_groups
    ADD CONSTRAINT fk_rails_a0acffc536 FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: view_states fk_rails_a165f49e98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.view_states
    ADD CONSTRAINT fk_rails_a165f49e98 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: teams fk_rails_a1fd43f535; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT fk_rails_a1fd43f535 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_status_values fk_rails_a3a2aede5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_status_values
    ADD CONSTRAINT fk_rails_a3a2aede5b FOREIGN KEY (repository_status_item_id) REFERENCES public.repository_status_items(id);


--
-- Name: my_module_statuses fk_rails_a3f7cd509a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_statuses
    ADD CONSTRAINT fk_rails_a3f7cd509a FOREIGN KEY (previous_status_id) REFERENCES public.my_module_statuses(id);


--
-- Name: result_assets fk_rails_a418904d39; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_assets
    ADD CONSTRAINT fk_rails_a418904d39 FOREIGN KEY (result_id) REFERENCES public.results(id);


--
-- Name: results fk_rails_a77d65dc36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_rails_a77d65dc36 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_a8a49e0a51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_a8a49e0a51 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: tokens fk_rails_ac8a5d0441; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT fk_rails_ac8a5d0441 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: repository_list_items fk_rails_ace46bca57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_items
    ADD CONSTRAINT fk_rails_ace46bca57 FOREIGN KEY (repository_column_id) REFERENCES public.repository_columns(id);


--
-- Name: protocols fk_rails_ae930efae7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_ae930efae7 FOREIGN KEY (previous_version_id) REFERENCES public.protocols(id);


--
-- Name: my_module_statuses fk_rails_b024d15104; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_statuses
    ADD CONSTRAINT fk_rails_b024d15104 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_b2c86b4f11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_b2c86b4f11 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: protocol_protocol_keywords fk_rails_b8f3d92c10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_protocol_keywords
    ADD CONSTRAINT fk_rails_b8f3d92c10 FOREIGN KEY (protocol_keyword_id) REFERENCES public.protocol_keywords(id);


--
-- Name: repository_asset_values fk_rails_babef4c14f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_asset_values
    ADD CONSTRAINT fk_rails_babef4c14f FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: repository_asset_values fk_rails_bb983a4d66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_asset_values
    ADD CONSTRAINT fk_rails_bb983a4d66 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_stock_values fk_rails_c111ff8695; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_values
    ADD CONSTRAINT fk_rails_c111ff8695 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: my_module_status_flows fk_rails_c19dc6b9e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_status_flows
    ADD CONSTRAINT fk_rails_c19dc6b9e9 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_stock_unit_items fk_rails_c200d845a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_unit_items
    ADD CONSTRAINT fk_rails_c200d845a5 FOREIGN KEY (repository_column_id) REFERENCES public.repository_columns(id);


--
-- Name: protocols fk_rails_c2952dc4b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_c2952dc4b7 FOREIGN KEY (added_by_id) REFERENCES public.users(id);


--
-- Name: repository_table_filters fk_rails_c2b1aff901; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_table_filters
    ADD CONSTRAINT fk_rails_c2b1aff901 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: step_assets fk_rails_c3d0fa4e01; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_assets
    ADD CONSTRAINT fk_rails_c3d0fa4e01 FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: repository_list_values fk_rails_c66a6a1980; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_list_values
    ADD CONSTRAINT fk_rails_c66a6a1980 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: reports fk_rails_c7699d537d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_c7699d537d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: report_elements fk_rails_c835a09180; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_c835a09180 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: checklists fk_rails_c89d59efd3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklists
    ADD CONSTRAINT fk_rails_c89d59efd3 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: user_roles fk_rails_c958cec38d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_rails_c958cec38d FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: my_module_tags fk_rails_cb98be233f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_tags
    ADD CONSTRAINT fk_rails_cb98be233f FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: user_my_modules fk_rails_cc63105d69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_my_modules
    ADD CONSTRAINT fk_rails_cc63105d69 FOREIGN KEY (assigned_by_id) REFERENCES public.users(id);


--
-- Name: user_notifications fk_rails_cdbff2ee9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT fk_rails_cdbff2ee9e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: result_texts fk_rails_ce7b70760d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_texts
    ADD CONSTRAINT fk_rails_ce7b70760d FOREIGN KEY (result_id) REFERENCES public.results(id);


--
-- Name: repository_date_time_values fk_rails_cfb9b16b76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_values
    ADD CONSTRAINT fk_rails_cfb9b16b76 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: protocol_keywords fk_rails_d16ba92dcb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_keywords
    ADD CONSTRAINT fk_rails_d16ba92dcb FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: user_projects fk_rails_d19c0da646; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT fk_rails_d19c0da646 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_notifications fk_rails_d238d8ef07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT fk_rails_d238d8ef07 FOREIGN KEY (notification_id) REFERENCES public.notifications(id);


--
-- Name: repository_checklist_values fk_rails_d2f015ade2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_checklist_values
    ADD CONSTRAINT fk_rails_d2f015ade2 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: activities fk_rails_d3946086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT fk_rails_d3946086d2 FOREIGN KEY (my_module_id) REFERENCES public.my_modules(id);


--
-- Name: step_orderable_elements fk_rails_d3d1eee15c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.step_orderable_elements
    ADD CONSTRAINT fk_rails_d3d1eee15c FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: notifications fk_rails_d44c385bb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_d44c385bb8 FOREIGN KEY (generator_user_id) REFERENCES public.users(id);


--
-- Name: repository_stock_unit_items fk_rails_d5b7257ea2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_unit_items
    ADD CONSTRAINT fk_rails_d5b7257ea2 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: experiments fk_rails_d683124fa4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT fk_rails_d683124fa4 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: label_templates fk_rails_d6ac71e421; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_templates
    ADD CONSTRAINT fk_rails_d6ac71e421 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_d8007e2f63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_d8007e2f63 FOREIGN KEY (my_module_id) REFERENCES public.my_modules(id);


--
-- Name: user_projects fk_rails_d826794aab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT fk_rails_d826794aab FOREIGN KEY (assigned_by_id) REFERENCES public.users(id);


--
-- Name: assets fk_rails_d9346d216d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_rails_d9346d216d FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: protocols fk_rails_dcb4ab6aa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT fk_rails_dcb4ab6aa9 FOREIGN KEY (parent_id) REFERENCES public.protocols(id);


--
-- Name: bmt_filters fk_rails_de5b654b84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bmt_filters
    ADD CONSTRAINT fk_rails_de5b654b84 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: my_modules fk_rails_e21638fa54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_e21638fa54 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: checklists fk_rails_e49efc98e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklists
    ADD CONSTRAINT fk_rails_e49efc98e6 FOREIGN KEY (step_id) REFERENCES public.steps(id);


--
-- Name: repository_text_values fk_rails_e4c61d807b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_text_values
    ADD CONSTRAINT fk_rails_e4c61d807b FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: repository_rows fk_rails_e7c4398649; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_rows
    ADD CONSTRAINT fk_rails_e7c4398649 FOREIGN KEY (restored_by_id) REFERENCES public.users(id);


--
-- Name: my_module_groups fk_rails_eaffa16fc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_module_groups
    ADD CONSTRAINT fk_rails_eaffa16fc3 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: projects fk_rails_ecc227a0c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_ecc227a0c2 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: oauth_access_tokens fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: repository_date_time_range_values fk_rails_efe428fafe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_date_time_range_values
    ADD CONSTRAINT fk_rails_efe428fafe FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: protocol_protocol_keywords fk_rails_f04cc911dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_protocol_keywords
    ADD CONSTRAINT fk_rails_f04cc911dd FOREIGN KEY (protocol_id) REFERENCES public.protocols(id);


--
-- Name: project_folders fk_rails_f27fa590f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_folders
    ADD CONSTRAINT fk_rails_f27fa590f4 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: report_elements fk_rails_f36eac136b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_f36eac136b FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: user_projects fk_rails_f58e9073ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT fk_rails_f58e9073ce FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: report_elements fk_rails_f5d944fc4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_elements
    ADD CONSTRAINT fk_rails_f5d944fc4d FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: repository_stock_values fk_rails_f83c438412; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_stock_values
    ADD CONSTRAINT fk_rails_f83c438412 FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: tags fk_rails_f95c7c81ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_f95c7c81ac FOREIGN KEY (last_modified_by_id) REFERENCES public.users(id);


--
-- Name: team_shared_objects fk_rails_f99472b670; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_shared_objects
    ADD CONSTRAINT fk_rails_f99472b670 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: projects fk_rails_fbf93d1a3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_fbf93d1a3d FOREIGN KEY (project_folder_id) REFERENCES public.project_folders(id);


--
-- Name: my_modules fk_rails_fd094f363d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.my_modules
    ADD CONSTRAINT fk_rails_fd094f363d FOREIGN KEY (my_module_group_id) REFERENCES public.my_module_groups(id);


--
-- Name: result_tables fk_rails_ff13ac2e84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_tables
    ADD CONSTRAINT fk_rails_ff13ac2e84 FOREIGN KEY (table_id) REFERENCES public.tables(id);


--
-- Name: projects fk_rails_ff595c9009; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_ff595c9009 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20150713060702'),
('20150713063224'),
('20150713070738'),
('20150713071921'),
('20150713072417'),
('20150714125221'),
('20150715122019'),
('20150715124934'),
('20150715131400'),
('20150715132459'),
('20150715132920'),
('20150715133511'),
('20150715133709'),
('20150715134133'),
('20150715135452'),
('20150715141810'),
('20150715142704'),
('20150715142929'),
('20150715143134'),
('20150716060140'),
('20150716061004'),
('20150716061555'),
('20150716061937'),
('20150716062013'),
('20150716062110'),
('20150716062801'),
('20150716064453'),
('20150716120130'),
('20150716120659'),
('20150717084645'),
('20150717085043'),
('20150717085133'),
('20150722095027'),
('20150722112911'),
('20150723134648'),
('20150730090021'),
('20150804055341'),
('20150820120553'),
('20150820123018'),
('20150820124022'),
('20150827130647'),
('20150827130822'),
('20150911125914'),
('20150915074650'),
('20150923065605'),
('20150923110208'),
('20150923154140'),
('20150924115001'),
('20150924181017'),
('20151005122041'),
('20151021082639'),
('20151021085335'),
('20151022123530'),
('20151028091615'),
('20151103155048'),
('20151111135802'),
('20151117083839'),
('20151119141714'),
('20151130160157'),
('20151203100514'),
('20151207151820'),
('20151214110800'),
('20151215103642'),
('20151215134147'),
('20151216095259'),
('20160114155705'),
('20160118114850'),
('20160119101947'),
('20160125200130'),
('20160125205500'),
('20160201085344'),
('20160205192344'),
('20160407063323'),
('20160421100400'),
('20160425133500'),
('20160429082100'),
('20160429102200'),
('20160513143117'),
('20160513165000'),
('20160527152000'),
('20160531094100'),
('20160704110900'),
('20160722082700'),
('20160803082801'),
('20160809074757'),
('20160928114119'),
('20160928114915'),
('20161004074754'),
('20161006065203'),
('20161011074804'),
('20161012112900'),
('20161123161514'),
('20161125153600'),
('20161129111100'),
('20161129171012'),
('20161208145354'),
('20170105162500'),
('20170116143350'),
('20170124135736'),
('20170207100731'),
('20170217141402'),
('20170306121855'),
('20170321131116'),
('20170322095856'),
('20170330092353'),
('20170404150845'),
('20170407082423'),
('20170407104322'),
('20170418153541'),
('20170420075905'),
('20170515073041'),
('20170515141252'),
('20170619125051'),
('20170803153030'),
('20170809131000'),
('20171003082333'),
('20171005135350'),
('20171026090804'),
('20180109102914'),
('20180207095200'),
('20180308094354'),
('20180416114040'),
('20180524091143'),
('20180806115201'),
('20180813120338'),
('20180905142400'),
('20180930205254'),
('20181008130519'),
('20181212162649'),
('20190116101127'),
('20190117155006'),
('20190125122852'),
('20190125123107'),
('20190213064847'),
('20190227110801'),
('20190227125306'),
('20190227125352'),
('20190304153544'),
('20190307102521'),
('20190308092130'),
('20190410110605'),
('20190424113216'),
('20190520135317'),
('20190613094834'),
('20190613134100'),
('20190711125513'),
('20190715150326'),
('20190726102200'),
('20190812065432'),
('20190812072649'),
('20190830141257'),
('20190903145834'),
('20190910125740'),
('20191001133557'),
('20191003091614'),
('20191007144622'),
('20191023162335'),
('20191105143702'),
('20191115143747'),
('20191204112549'),
('20191205133522'),
('20191206105058'),
('20191210103004'),
('20191218072619'),
('20200113143828'),
('20200204100934'),
('20200326114643'),
('20200331183640'),
('20200603125407'),
('20200604210943'),
('20200622140843'),
('20200622155632'),
('20200709142830'),
('20200713142353'),
('20200714082503'),
('20200826143431'),
('20200902093234'),
('20200909121441'),
('20201027133634'),
('20201028103608'),
('20201126203713'),
('20201209165626'),
('20201215161050'),
('20210128105457'),
('20210128105458'),
('20210202214508'),
('20210217114042'),
('20210222123822'),
('20210222123823'),
('20210312185911'),
('20210325152257'),
('20210407143303'),
('20210410100006'),
('20210506125657'),
('20210531114633'),
('20210603152345'),
('20210616071836'),
('20210622101238'),
('20210715125349'),
('20210716124649'),
('20210720112050'),
('20210811103123'),
('20210812095254'),
('20210825112050'),
('20210906132120'),
('20211103115450'),
('20211123103711'),
('20220110151005'),
('20220110151006'),
('20220203122802'),
('20220217104635'),
('20220224153705'),
('20220307120010'),
('20220310105144'),
('20220321122111'),
('20220325101011'),
('20220328164215'),
('20220414095100'),
('20220414143955'),
('20220429083335'),
('20220516111152'),
('20220530144300'),
('20220602120714'),
('20220621153016'),
('20220624091046'),
('20220705091621'),
('20220726133419'),
('20220803122405'),
('20220818094636'),
('20220914124900'),
('20221007113010'),
('20221028085051'),
('20221122132857'),
('20221125133611'),
('20221222123021'),
('20230120141017'),
('20230206095817'),
('20230223142119'),
('20230227131215');



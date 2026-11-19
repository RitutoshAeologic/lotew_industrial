-- ======================================================================================
-- LOTEW INDUSTRIAL CORE DATABASE SCHEMA (lotew-industrial)
-- Fully Idempotent Migration Script (Safely Re-runnable without errors)
-- ======================================================================================

-- Step 1: Create Schemas
CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS industrial;
CREATE SCHEMA IF NOT EXISTS outcomes;

-- Step 2: Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ======================================================================================
-- DATABASE ROLES & ACCESS CONTROL (No-Look-Ahead Enforcement at DB Engine Level)
-- ======================================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'industrial_app_role') THEN
        CREATE ROLE industrial_app_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'claim_replay_role') THEN
        CREATE ROLE claim_replay_role;
    END IF;
END
$$;

-- Online Decision Pipeline Role: Permitted on platform and industrial, STRICTLY BLOCKED from outcomes!
GRANT USAGE ON SCHEMA platform TO industrial_app_role;
GRANT USAGE ON SCHEMA industrial TO industrial_app_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA platform TO industrial_app_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA industrial TO industrial_app_role;
REVOKE ALL ON SCHEMA outcomes FROM industrial_app_role; -- HARD NO-LOOK-AHEAD ENFORCEMENT

-- Dedicated Claim Replay Role: Authorized for historical post-incident forensic replay
GRANT USAGE ON SCHEMA outcomes TO claim_replay_role;
GRANT SELECT ON ALL TABLES IN SCHEMA outcomes TO claim_replay_role;

-- ======================================================================================
-- SCHEMA: platform (Tenancy & User Roles)
-- ======================================================================================

-- 1. Tenants Registry
CREATE TABLE IF NOT EXISTS platform.tenants (
    tenant_id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    updated_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

-- 2. Users and Roles
CREATE TABLE IF NOT EXISTS platform.users_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL,
    role VARCHAR(64) NOT NULL,
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT uq_user_tenant_role UNIQUE (tenant_id, user_id, role)
);

-- ======================================================================================
-- SCHEMA: industrial (Assets, Components, Evidence Streams, Decisions, Hash Chain)
-- ======================================================================================

-- 3. Assets
CREATE TABLE IF NOT EXISTS industrial.assets (
    asset_id VARCHAR(128) NOT NULL,
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE CASCADE,
    asset_name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(64) NOT NULL,
    commission_date DATE,
    status VARCHAR(32) NOT NULL DEFAULT 'OPERATIONAL',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    PRIMARY KEY (tenant_id, asset_id)
);

-- 4. Components
CREATE TABLE IF NOT EXISTS industrial.components (
    component_id VARCHAR(128) NOT NULL,
    asset_id VARCHAR(128) NOT NULL,
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    component_type VARCHAR(64) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    PRIMARY KEY (tenant_id, asset_id, component_id),
    FOREIGN KEY (tenant_id, asset_id) REFERENCES industrial.assets(tenant_id, asset_id) ON DELETE CASCADE
);

-- 5. Evidence Streams (Core Backbone Memory)
CREATE TABLE IF NOT EXISTS industrial.evidence_streams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE RESTRICT,
    asset_id VARCHAR(128) NOT NULL,
    component_id VARCHAR(128) NOT NULL DEFAULT 'system',
    evidence_type VARCHAR(64) NOT NULL,
    cycle_id INT NULL,
    raw_file_name VARCHAR(255) NOT NULL,
    raw_storage_path TEXT NOT NULL,
    raw_file_sha256 VARCHAR(64) NOT NULL,
    event_time TIMESTAMPTZ(3) NULL,
    ingestion_time TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    available_time TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    ingestion_latency_ms NUMERIC(12, 3) NULL,
    processing_latency_ms NUMERIC(12, 3) NULL,
    quality_flag VARCHAR(32) NOT NULL DEFAULT 'NOMINAL',
    extracted_text TEXT NULL,
    canonical_data JSONB NOT NULL,
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

-- Ensure columns exist if table was already created in an earlier run
ALTER TABLE industrial.evidence_streams ADD COLUMN IF NOT EXISTS component_id VARCHAR(128) NOT NULL DEFAULT 'system';
ALTER TABLE industrial.evidence_streams ADD COLUMN IF NOT EXISTS cycle_id INT NULL;
ALTER TABLE industrial.evidence_streams ADD COLUMN IF NOT EXISTS ingestion_latency_ms NUMERIC(12, 3) NULL;
ALTER TABLE industrial.evidence_streams ADD COLUMN IF NOT EXISTS processing_latency_ms NUMERIC(12, 3) NULL;

-- Idempotency & Deduplication index
CREATE UNIQUE INDEX IF NOT EXISTS uq_cycle_telemetry 
    ON industrial.evidence_streams (tenant_id, asset_id, cycle_id) 
    WHERE evidence_type = 'TELEMETRY_CYCLE';

CREATE INDEX IF NOT EXISTS idx_evidence_tenant_asset_time 
    ON industrial.evidence_streams(tenant_id, asset_id, event_time DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_evidence_sha256 
    ON industrial.evidence_streams(raw_file_sha256);

CREATE INDEX IF NOT EXISTS idx_evidence_type 
    ON industrial.evidence_streams(tenant_id, evidence_type);

-- 6. Decisions Table
CREATE TABLE IF NOT EXISTS industrial.decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE RESTRICT,
    asset_id VARCHAR(128) NOT NULL,
    component_id VARCHAR(128) NULL,
    action_requested VARCHAR(128) NOT NULL,
    verdict VARCHAR(32) NOT NULL,
    why_code VARCHAR(64) NOT NULL,
    evidence_ids UUID[] NOT NULL DEFAULT '{}'::uuid[],
    authority_score NUMERIC(5, 4) NOT NULL,
    spin_cost_matrix JSONB NOT NULL DEFAULT '{}'::jsonb,
    rationale_summary TEXT NOT NULL,
    decided_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    decided_by VARCHAR(128) NOT NULL DEFAULT 'LOTEW_DECISION_ENGINE'
);

CREATE INDEX IF NOT EXISTS idx_decisions_tenant_asset 
    ON industrial.decisions(tenant_id, asset_id, decided_at DESC);

-- 7. Hash Chain (Tamper-Evident Forensic Audit Ledger)
CREATE TABLE IF NOT EXISTS industrial.hash_chain (
    sequence_number BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    block_index BIGINT NOT NULL,
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE RESTRICT,
    decision_id UUID NOT NULL REFERENCES industrial.decisions(id) ON DELETE RESTRICT,
    canonical_data_sha256 VARCHAR(64) NOT NULL,
    previous_hash VARCHAR(64) NOT NULL,
    block_hash VARCHAR(64) NOT NULL,
    timestamp TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT uq_block_hash UNIQUE (tenant_id, block_hash),
    CONSTRAINT uq_tenant_block_index UNIQUE (tenant_id, block_index)
);

-- ======================================================================================
-- SCHEMA: outcomes (Strictly Isolated Ground Truth for No-Look-Ahead Evaluation)
-- ======================================================================================

-- 8. Canonical Outcomes Table
CREATE TABLE IF NOT EXISTS outcomes.canonical_outcomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id) ON DELETE RESTRICT,
    asset_id VARCHAR(128) NOT NULL,
    component_id VARCHAR(128) NOT NULL,
    cycle_id INT NULL,
    observation_time TIMESTAMPTZ(3) NOT NULL,
    ground_truth_state VARCHAR(64) NOT NULL,
    ground_truth_score NUMERIC(8, 3) NOT NULL,
    is_failure BOOLEAN NOT NULL DEFAULT FALSE,
    source VARCHAR(64) NOT NULL DEFAULT 'PHYSICAL_TEST_RIG_LABEL',
    created_at TIMESTAMPTZ(3) NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

CREATE INDEX IF NOT EXISTS idx_outcomes_lookup 
    ON outcomes.canonical_outcomes(tenant_id, asset_id, cycle_id);

-- ======================================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES (Idempotent: DROP IF EXISTS before CREATE)
-- ======================================================================================

ALTER TABLE platform.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.users_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE industrial.assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE industrial.components ENABLE ROW LEVEL SECURITY;
ALTER TABLE industrial.evidence_streams ENABLE ROW LEVEL SECURITY;
ALTER TABLE industrial.decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE industrial.hash_chain ENABLE ROW LEVEL SECURITY;
ALTER TABLE outcomes.canonical_outcomes ENABLE ROW LEVEL SECURITY;

-- 1. Service Role Bypass Policies (Drop & Recreate for safe re-runs)
DROP POLICY IF EXISTS service_role_all_tenants ON platform.tenants;
CREATE POLICY service_role_all_tenants ON platform.tenants FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_users ON platform.users_roles;
CREATE POLICY service_role_all_users ON platform.users_roles FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_assets ON industrial.assets;
CREATE POLICY service_role_all_assets ON industrial.assets FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_components ON industrial.components;
CREATE POLICY service_role_all_components ON industrial.components FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_evidence ON industrial.evidence_streams;
CREATE POLICY service_role_all_evidence ON industrial.evidence_streams FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_decisions ON industrial.decisions;
CREATE POLICY service_role_all_decisions ON industrial.decisions FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_hash_chain ON industrial.hash_chain;
CREATE POLICY service_role_all_hash_chain ON industrial.hash_chain FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS service_role_all_outcomes ON outcomes.canonical_outcomes;
CREATE POLICY service_role_all_outcomes ON outcomes.canonical_outcomes FOR ALL TO service_role USING (true);

-- 2. Authenticated Users Tenant Isolation Policies (Drop & Recreate)
DROP POLICY IF EXISTS tenant_isolation_evidence ON industrial.evidence_streams;
CREATE POLICY tenant_isolation_evidence ON industrial.evidence_streams FOR ALL TO authenticated
    USING (tenant_id = (auth.jwt() ->> 'tenant_id'));

DROP POLICY IF EXISTS tenant_isolation_assets ON industrial.assets;
CREATE POLICY tenant_isolation_assets ON industrial.assets FOR ALL TO authenticated
    USING (tenant_id = (auth.jwt() ->> 'tenant_id'));

DROP POLICY IF EXISTS tenant_isolation_decisions ON industrial.decisions;
CREATE POLICY tenant_isolation_decisions ON industrial.decisions FOR ALL TO authenticated
    USING (tenant_id = (auth.jwt() ->> 'tenant_id'));

-- ======================================================================================
-- STORAGE BUCKET CONFIGURATION & SEED DATA
-- ======================================================================================

-- Storage Bucket: industrial-raw
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'industrial-raw',
    'industrial-raw',
    false,
    104857600, -- 100MB limit per file
    ARRAY['application/pdf', 'application/octet-stream', 'application/x-parquet']
) ON CONFLICT (id) DO NOTHING;

-- Seed Tenants
INSERT INTO platform.tenants (tenant_id, name, domain) VALUES
('hydraulic_lab', 'UCI Hydraulic Systems Test Rig', 'MANUFACTURING_HYDRAULICS'),
('metro_porto', 'Metro do Porto Compressor Telemetry', 'RAIL_TRANSPORT'),
('scania_fleet', 'SCANIA Component Failure Fleet', 'HEAVY_TRUCK_FLEET'),
('petrobras_3w', 'Petrobras Offshore Well Dynamics', 'OFFSHORE_OIL_GAS')
ON CONFLICT (tenant_id) DO NOTHING;

-- Seed Primary Hydraulic Asset & Components
INSERT INTO industrial.assets (tenant_id, asset_id, asset_name, asset_type, commission_date) VALUES
('hydraulic_lab', 'hydraulic_rig_01', 'Hydraulic Systems Test Rig - Primary Bench', 'HYDRAULIC_TEST_BENCH', '2026-01-01')
ON CONFLICT (tenant_id, asset_id) DO NOTHING;

INSERT INTO industrial.components (tenant_id, asset_id, component_id, name, component_type) VALUES
('hydraulic_lab', 'hydraulic_rig_01', 'system', 'Full Rig Integrated Hydraulic Circuit', 'SYSTEM_OVERALL'),
('hydraulic_lab', 'hydraulic_rig_01', 'cooler', 'Hydraulic Cooler / Heat Exchanger', 'HEAT_EXCHANGER'),
('hydraulic_lab', 'hydraulic_rig_01', 'valve', 'Directional Control Valve', 'DIRECTIONAL_VALVE'),
('hydraulic_lab', 'hydraulic_rig_01', 'pump', 'Axial Piston Main Pump', 'HYDRAULIC_PUMP'),
('hydraulic_lab', 'hydraulic_rig_01', 'accumulator', 'Hydraulic Pressure Accumulator', 'PRESSURE_ACCUMULATOR')
ON CONFLICT (tenant_id, asset_id, component_id) DO NOTHING;

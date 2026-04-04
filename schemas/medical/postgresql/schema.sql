-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : Medical
-- Database : PostgreSQL 14+
-- File     : schema.sql
-- Version  : 1.0.0
-- Description:
--   A production-ready medical / healthcare schema covering patients,
--   practitioners, departments, appointments, clinical encounters, diagnoses,
--   prescriptions, a medication catalog, and lab orders/results.
--   Designed to reflect real-world best practices: surrogate UUID PKs, FK
--   constraints, CHECK constraints for business rules, partial indexes, and
--   clear comments throughout.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text for emails

-- ---------------------------------------------------------------------------
-- Enum types
-- ---------------------------------------------------------------------------

CREATE TYPE gender AS ENUM (
    'male',
    'female',
    'other',
    'prefer_not_to_say'
);

CREATE TYPE practitioner_role AS ENUM (
    'physician',
    'nurse',
    'nurse_practitioner',
    'physician_assistant',
    'specialist',
    'admin'
);

CREATE TYPE appointment_status AS ENUM (
    'scheduled',
    'confirmed',
    'checked_in',
    'completed',
    'cancelled',
    'no_show'
);

CREATE TYPE encounter_type AS ENUM (
    'outpatient',
    'inpatient',
    'emergency',
    'telehealth'
);

CREATE TYPE prescription_status AS ENUM (
    'active',
    'completed',
    'cancelled',
    'on_hold'
);

CREATE TYPE lab_order_status AS ENUM (
    'ordered',
    'collected',
    'in_progress',
    'resulted',
    'cancelled'
);

-- ---------------------------------------------------------------------------
-- departments
-- ---------------------------------------------------------------------------
-- Hospital departments and clinical specialties. Practitioners are assigned
-- to a department; appointments can be routed by department.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    id              SERIAL          PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    code            VARCHAR(20)     NOT NULL,
    description     TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_departments_code UNIQUE (code)
);

COMMENT ON TABLE  departments      IS 'Hospital departments and clinical specialties.';
COMMENT ON COLUMN departments.code IS 'Short identifier, e.g. "CARD" for Cardiology.';

-- ---------------------------------------------------------------------------
-- patients
-- ---------------------------------------------------------------------------
-- Demographic information for registered patients. Email uses citext so
-- uniqueness is enforced case-insensitively. Date of birth is stored as DATE
-- rather than a computed age to avoid staleness.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT          NOT NULL,
    password_hash   TEXT            NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    date_of_birth   DATE            NOT NULL,
    gender          gender,
    phone           VARCHAR(30),
    address_line1   VARCHAR(255),
    address_line2   VARCHAR(255),
    city            VARCHAR(100),
    state           VARCHAR(100),
    postal_code     VARCHAR(20),
    country_code    CHAR(2)         NOT NULL DEFAULT 'US',  -- ISO 3166-1 alpha-2
    emergency_contact_name  VARCHAR(200),
    emergency_contact_phone VARCHAR(30),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_patients_email UNIQUE (email)
);

CREATE INDEX idx_patients_email         ON patients (email);
CREATE INDEX idx_patients_last_name     ON patients (last_name);
CREATE INDEX idx_patients_date_of_birth ON patients (date_of_birth);
CREATE INDEX idx_patients_created_at    ON patients (created_at DESC);

COMMENT ON TABLE  patients                      IS 'Registered patient demographic records.';
COMMENT ON COLUMN patients.email                IS 'Login email — unique, case-insensitive.';
COMMENT ON COLUMN patients.password_hash        IS 'bcrypt / Argon2 hash; never store plain-text.';
COMMENT ON COLUMN patients.date_of_birth        IS 'Stored as DATE to avoid stale computed-age issues.';
COMMENT ON COLUMN patients.country_code         IS 'ISO 3166-1 alpha-2 country code, e.g. US, GB.';

-- ---------------------------------------------------------------------------
-- practitioners
-- ---------------------------------------------------------------------------
-- Medical professionals who deliver care. A practitioner belongs to a primary
-- department but may serve in others. License number must be unique across
-- the system.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS practitioners (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id   INTEGER         REFERENCES departments (id) ON DELETE SET NULL,
    email           CITEXT          NOT NULL,
    password_hash   TEXT            NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    role            practitioner_role NOT NULL DEFAULT 'physician',
    specialization  VARCHAR(150),
    license_number  VARCHAR(100)    NOT NULL,
    phone           VARCHAR(30),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_practitioners_email          UNIQUE (email),
    CONSTRAINT uq_practitioners_license_number UNIQUE (license_number)
);

CREATE INDEX idx_practitioners_email         ON practitioners (email);
CREATE INDEX idx_practitioners_department_id ON practitioners (department_id);
CREATE INDEX idx_practitioners_role          ON practitioners (role);
-- Partial index: most lookups target active practitioners
CREATE INDEX idx_practitioners_active        ON practitioners (last_name, first_name) WHERE is_active = TRUE;

COMMENT ON TABLE  practitioners                   IS 'Medical professionals who deliver patient care.';
COMMENT ON COLUMN practitioners.role              IS 'Clinical role — governs access and scheduling rules.';
COMMENT ON COLUMN practitioners.license_number    IS 'State/national medical license number — must be unique.';
COMMENT ON COLUMN practitioners.specialization    IS 'Free-text specialty, e.g. "Interventional Cardiology".';

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
-- Scheduled appointments link a patient to a practitioner. An appointment
-- may later be converted to a clinical encounter when the patient is seen.
-- reason is a brief free-text field supplied by the patient at booking time.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS appointments (
    id                  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id          UUID                NOT NULL REFERENCES patients (id),
    practitioner_id     UUID                NOT NULL REFERENCES practitioners (id),
    department_id       INTEGER             REFERENCES departments (id) ON DELETE SET NULL,
    scheduled_at        TIMESTAMPTZ         NOT NULL,
    duration_minutes    SMALLINT            NOT NULL DEFAULT 30,
    status              appointment_status  NOT NULL DEFAULT 'scheduled',
    reason              TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_appointments_duration CHECK (duration_minutes > 0)
);

CREATE INDEX idx_appointments_patient_id      ON appointments (patient_id);
CREATE INDEX idx_appointments_practitioner_id ON appointments (practitioner_id);
CREATE INDEX idx_appointments_scheduled_at    ON appointments (scheduled_at);
CREATE INDEX idx_appointments_status          ON appointments (status);
-- Partial index: upcoming scheduled/confirmed appointments are the hot path
CREATE INDEX idx_appointments_upcoming        ON appointments (scheduled_at, practitioner_id)
    WHERE status IN ('scheduled', 'confirmed');

COMMENT ON TABLE  appointments                    IS 'Scheduled patient–practitioner appointments.';
COMMENT ON COLUMN appointments.scheduled_at       IS 'UTC timestamp of the planned appointment start.';
COMMENT ON COLUMN appointments.duration_minutes   IS 'Planned duration in minutes; default 30.';
COMMENT ON COLUMN appointments.reason             IS 'Chief complaint or reason for visit as stated by the patient.';

-- ---------------------------------------------------------------------------
-- encounters
-- ---------------------------------------------------------------------------
-- A clinical encounter is the actual visit record. It is typically created
-- when a patient checks in for an appointment, but may also arise from
-- walk-in or emergency presentations.
-- chief_complaint and clinical_notes are free-text clinical documentation.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS encounters (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id          UUID            NOT NULL REFERENCES patients (id),
    practitioner_id     UUID            NOT NULL REFERENCES practitioners (id),
    appointment_id      UUID            REFERENCES appointments (id) ON DELETE SET NULL,
    department_id       INTEGER         REFERENCES departments (id) ON DELETE SET NULL,
    type                encounter_type  NOT NULL DEFAULT 'outpatient',
    started_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ended_at            TIMESTAMPTZ,
    chief_complaint     TEXT,
    clinical_notes      TEXT,
    discharge_summary   TEXT,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_encounters_ended_after_start
        CHECK (ended_at IS NULL OR ended_at > started_at)
);

CREATE INDEX idx_encounters_patient_id      ON encounters (patient_id);
CREATE INDEX idx_encounters_practitioner_id ON encounters (practitioner_id);
CREATE INDEX idx_encounters_appointment_id  ON encounters (appointment_id);
CREATE INDEX idx_encounters_started_at      ON encounters (started_at DESC);
CREATE INDEX idx_encounters_type            ON encounters (type);

COMMENT ON TABLE  encounters                   IS 'Clinical visit records — the core of the patient chart.';
COMMENT ON COLUMN encounters.appointment_id    IS 'NULL for walk-in or emergency visits without a prior appointment.';
COMMENT ON COLUMN encounters.chief_complaint   IS 'Patient''s primary concern in their own words.';
COMMENT ON COLUMN encounters.clinical_notes    IS 'Clinician''s SOAP or free-text notes for the encounter.';
COMMENT ON COLUMN encounters.discharge_summary IS 'Populated when the patient is discharged (inpatient/emergency).';

-- ---------------------------------------------------------------------------
-- diagnoses
-- ---------------------------------------------------------------------------
-- One or more diagnoses may be recorded per encounter. code follows ICD-10
-- (e.g. "J06.9" for an acute upper respiratory infection).
-- is_primary flags the principal diagnosis for the encounter.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnoses (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id    UUID            NOT NULL REFERENCES encounters (id) ON DELETE CASCADE,
    code            VARCHAR(20)     NOT NULL,   -- ICD-10 / ICD-11 code
    description     TEXT            NOT NULL,
    is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,
    noted_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_diagnoses_encounter_id ON diagnoses (encounter_id);
CREATE INDEX idx_diagnoses_code         ON diagnoses (code);
-- Partial index: primary diagnoses are the most common filter
CREATE INDEX idx_diagnoses_primary      ON diagnoses (encounter_id) WHERE is_primary = TRUE;

COMMENT ON TABLE  diagnoses              IS 'ICD-coded diagnoses linked to a clinical encounter.';
COMMENT ON COLUMN diagnoses.code         IS 'ICD-10 / ICD-11 code, e.g. "J06.9" or "I10".';
COMMENT ON COLUMN diagnoses.is_primary   IS 'TRUE for the principal diagnosis of the encounter.';

-- ---------------------------------------------------------------------------
-- medications
-- ---------------------------------------------------------------------------
-- Catalog of medications that may be prescribed. RxNorm codes provide a
-- standardised identifier compatible with pharmacy systems.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS medications (
    id              SERIAL          PRIMARY KEY,
    rxnorm_code     VARCHAR(20),    -- RxNorm concept code (CUI)
    name            VARCHAR(255)    NOT NULL,
    generic_name    VARCHAR(255),
    drug_class      VARCHAR(150),
    dosage_form     VARCHAR(100),   -- e.g. 'tablet', 'capsule', 'injection', 'syrup'
    strength        VARCHAR(100),   -- e.g. '500 mg', '10 mg/5 mL'
    is_controlled   BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_medications_rxnorm UNIQUE (rxnorm_code)
);

CREATE INDEX idx_medications_name        ON medications (name);
CREATE INDEX idx_medications_drug_class  ON medications (drug_class);
CREATE INDEX idx_medications_controlled  ON medications (is_controlled) WHERE is_controlled = TRUE;

COMMENT ON TABLE  medications                IS 'Approved medication catalog with standardised identifiers.';
COMMENT ON COLUMN medications.rxnorm_code    IS 'RxNorm concept unique identifier (CUI).';
COMMENT ON COLUMN medications.is_controlled  IS 'TRUE for controlled substances requiring additional oversight.';
COMMENT ON COLUMN medications.dosage_form    IS 'Physical form, e.g. "tablet", "capsule", "injection".';

-- ---------------------------------------------------------------------------
-- prescriptions
-- ---------------------------------------------------------------------------
-- A prescription links a medication to an encounter and specifies dosing
-- instructions. prescribed_by is denormalised from the encounter's
-- practitioner_id to allow future model flexibility.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS prescriptions (
    id                  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id        UUID                NOT NULL REFERENCES encounters (id) ON DELETE CASCADE,
    medication_id       INTEGER             NOT NULL REFERENCES medications (id),
    prescribed_by       UUID                NOT NULL REFERENCES practitioners (id),
    dosage              VARCHAR(100)        NOT NULL,  -- e.g. '500 mg'
    frequency           VARCHAR(100)        NOT NULL,  -- e.g. 'twice daily'
    route               VARCHAR(100)        NOT NULL DEFAULT 'oral',  -- e.g. 'oral', 'IV', 'topical'
    duration_days       SMALLINT,
    refills_allowed     SMALLINT            NOT NULL DEFAULT 0,
    instructions        TEXT,
    status              prescription_status NOT NULL DEFAULT 'active',
    prescribed_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_prescriptions_duration    CHECK (duration_days IS NULL OR duration_days > 0),
    CONSTRAINT chk_prescriptions_refills     CHECK (refills_allowed >= 0)
);

CREATE INDEX idx_prescriptions_encounter_id  ON prescriptions (encounter_id);
CREATE INDEX idx_prescriptions_medication_id ON prescriptions (medication_id);
CREATE INDEX idx_prescriptions_prescribed_by ON prescriptions (prescribed_by);
CREATE INDEX idx_prescriptions_status        ON prescriptions (status);
-- Partial index: active prescriptions are the most-queried subset
CREATE INDEX idx_prescriptions_active        ON prescriptions (encounter_id, prescribed_at DESC)
    WHERE status = 'active';

COMMENT ON TABLE  prescriptions                IS 'Medication orders written during a clinical encounter.';
COMMENT ON COLUMN prescriptions.dosage         IS 'Dose amount per administration, e.g. "500 mg".';
COMMENT ON COLUMN prescriptions.frequency      IS 'Administration schedule, e.g. "twice daily", "every 8 hours".';
COMMENT ON COLUMN prescriptions.route          IS 'Route of administration, e.g. "oral", "IV", "topical".';
COMMENT ON COLUMN prescriptions.refills_allowed IS '0 means no refills; each fill decrements the pharmacy counter.';

-- ---------------------------------------------------------------------------
-- lab_orders
-- ---------------------------------------------------------------------------
-- Lab test orders placed during an encounter. panel_name is a free-text
-- field describing the ordered test or panel (e.g. "CBC", "BMP", "HbA1c").
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lab_orders (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id    UUID                NOT NULL REFERENCES encounters (id) ON DELETE CASCADE,
    ordered_by      UUID                NOT NULL REFERENCES practitioners (id),
    panel_name      VARCHAR(255)        NOT NULL,
    loinc_code      VARCHAR(20),        -- LOINC test identifier
    priority        VARCHAR(20)         NOT NULL DEFAULT 'routine',  -- 'routine', 'urgent', 'stat'
    status          lab_order_status    NOT NULL DEFAULT 'ordered',
    notes           TEXT,
    ordered_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    collected_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_lab_orders_priority
        CHECK (priority IN ('routine', 'urgent', 'stat'))
);

CREATE INDEX idx_lab_orders_encounter_id ON lab_orders (encounter_id);
CREATE INDEX idx_lab_orders_ordered_by   ON lab_orders (ordered_by);
CREATE INDEX idx_lab_orders_status       ON lab_orders (status);
CREATE INDEX idx_lab_orders_loinc_code   ON lab_orders (loinc_code);

COMMENT ON TABLE  lab_orders              IS 'Laboratory test orders placed during encounters.';
COMMENT ON COLUMN lab_orders.panel_name   IS 'Test or panel name, e.g. "CBC", "BMP", "HbA1c".';
COMMENT ON COLUMN lab_orders.loinc_code   IS 'LOINC standardised test identifier.';
COMMENT ON COLUMN lab_orders.priority     IS 'Urgency: routine (default), urgent, or stat (immediate).';
COMMENT ON COLUMN lab_orders.collected_at IS 'Timestamp when the sample was collected; NULL if not yet collected.';

-- ---------------------------------------------------------------------------
-- lab_results
-- ---------------------------------------------------------------------------
-- Individual result lines for a lab order. A single order may produce
-- multiple result rows (e.g. a CBC order returns WBC, RBC, Hgb, etc.).
-- reference_range and unit allow the application to flag abnormal values.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lab_results (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_order_id    UUID            NOT NULL REFERENCES lab_orders (id) ON DELETE CASCADE,
    test_name       VARCHAR(255)    NOT NULL,
    loinc_code      VARCHAR(20),
    value           TEXT            NOT NULL,   -- stored as text to support qualitative results
    unit            VARCHAR(50),
    reference_range VARCHAR(100),   -- e.g. '4.5–11.0 × 10³/µL'
    is_abnormal     BOOLEAN         NOT NULL DEFAULT FALSE,
    resulted_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lab_results_lab_order_id ON lab_results (lab_order_id);
CREATE INDEX idx_lab_results_loinc_code   ON lab_results (loinc_code);
CREATE INDEX idx_lab_results_is_abnormal  ON lab_results (lab_order_id) WHERE is_abnormal = TRUE;

COMMENT ON TABLE  lab_results                   IS 'Individual result values for a laboratory order.';
COMMENT ON COLUMN lab_results.value             IS 'Result value stored as text to support numeric and qualitative results.';
COMMENT ON COLUMN lab_results.reference_range   IS 'Normal range for this analyte, e.g. "4.5–11.0 × 10³/µL".';
COMMENT ON COLUMN lab_results.is_abnormal       IS 'TRUE when the value falls outside the reference range.';

-- ---------------------------------------------------------------------------
-- Trigger helper: auto-update updated_at columns
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'patients', 'practitioners', 'appointments',
        'encounters', 'prescriptions', 'lab_orders'
    ] LOOP
        EXECUTE format(
            'CREATE OR REPLACE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;

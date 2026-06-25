-- =============================================================
-- HR Analytics - Schema & Table Creation
-- =============================================================
-- This script creates the 2-schema architecture:
--   raw       → untouched landing zone   (preserved if exists)
--   clean     → transformed records      (rebuilt on each run)
-- =============================================================

-- ── Raw layer: preserved (IF NOT EXISTS) ──────────────────
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.hr_employees_raw (
    employee_id         TEXT,
    full_name           TEXT,
    department          TEXT,
    job_title           TEXT,
    hire_date           TEXT,           -- parsed to DATE during cleaning
    performance_rating  TEXT,
    experience_years    INTEGER,
    status              TEXT,
    work_mode           TEXT,
    salary              NUMERIC(10, 2),
    year                INTEGER,
    country             TEXT,
    city                TEXT,
    age                 INTEGER,
    job_level           TEXT
);

COMMENT ON TABLE raw.hr_employees_raw IS
    'Landing table for raw CSV data. No transformations applied.';

COMMENT ON COLUMN raw.hr_employees_raw.hire_date IS
    'Stored as TEXT; parsed to DATE in clean.employees.';

COMMENT ON COLUMN raw.hr_employees_raw.performance_rating IS
    'Contains intentional NULLs (~0.17%) for imputation practice.';

-- ── Clean layers: rebuilt each run ────────────
DROP SCHEMA IF EXISTS clean     CASCADE;

CREATE SCHEMA clean;

DROP TABLE IF EXISTS clean.hr_employees;

CREATE TABLE clean.hr_employees (
    employee_id TEXT PRIMARY KEY,
    full_name TEXT,
    department TEXT,
    job_title TEXT,
    hire_date DATE,
    performance_rating TEXT,
    experience_years INTEGER,
    status TEXT,
    work_mode TEXT,
    salary NUMERIC(10,2),
    hire_year INTEGER,
    country TEXT,
    city TEXT,
    age INTEGER,
    job_level TEXT,
    tenure INTEGER
);
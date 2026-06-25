-- =============================================================
-- HR Analytics - Kimball Star Schema
-- =============================================================
-- Schema   : mart
-- Grain    : One row = one employee snapshot
-- =============================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.fact_employee         CASCADE;
DROP TABLE IF EXISTS mart.dim_date              CASCADE;
DROP TABLE IF EXISTS mart.dim_department        CASCADE;
DROP TABLE IF EXISTS mart.dim_job_level         CASCADE;
DROP TABLE IF EXISTS mart.dim_location          CASCADE;
DROP TABLE IF EXISTS mart.dim_performance_rating CASCADE;
DROP TABLE IF EXISTS mart.dim_status            CASCADE;
DROP TABLE IF EXISTS mart.dim_work_mode         CASCADE;

-- ═════════════════════════════════════════════════════════════
-- Dimensions
-- ═════════════════════════════════════════════════════════════

-- ── dim_department ──────────────────────────────────────────
CREATE TABLE mart.dim_department (
    department_key   SERIAL PRIMARY KEY,
    department_name  VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO mart.dim_department (department_name)
SELECT DISTINCT department
FROM clean.hr_employees
ORDER BY department;

-- ── dim_job_level ───────────────────────────────────────────
CREATE TABLE mart.dim_job_level (
    job_level_key    SERIAL PRIMARY KEY,
    job_level_name   VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO mart.dim_job_level (job_level_name)
SELECT DISTINCT job_level
FROM clean.hr_employees
ORDER BY job_level;

-- ── dim_location ────────────────────────────────────────────
CREATE TABLE mart.dim_location (
    location_key    SERIAL PRIMARY KEY,
    country         VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    UNIQUE (country, city)
);

INSERT INTO mart.dim_location (country, city)
SELECT DISTINCT country, city
FROM clean.hr_employees
ORDER BY country, city;

-- ── dim_performance_rating ──────────────────────────────────
CREATE TABLE mart.dim_performance_rating (
    performance_rating_key  SERIAL PRIMARY KEY,
    performance_rating      VARCHAR(50) NOT NULL UNIQUE,
    rating_score            SMALLINT    NOT NULL
);

INSERT INTO mart.dim_performance_rating (performance_rating, rating_score)
SELECT performance_rating,
    CASE performance_rating
        WHEN 'Excellent' THEN 4
        WHEN 'Good'      THEN 3
        WHEN 'Satisfactory'   THEN 2
        WHEN 'Needs Improvement'      THEN 1
        ELSE NULL
    END AS rating_score
FROM (SELECT DISTINCT performance_rating FROM clean.hr_employees) AS _
ORDER BY performance_rating;

-- ── dim_status ──────────────────────────────────────────────
CREATE TABLE mart.dim_status (
    status_key   SERIAL PRIMARY KEY,
    status_name  VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO mart.dim_status (status_name)
SELECT DISTINCT status
FROM clean.hr_employees
ORDER BY status;

-- ── dim_work_mode ───────────────────────────────────────────
CREATE TABLE mart.dim_work_mode (
    work_mode_key   SERIAL PRIMARY KEY,
    work_mode_name  VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO mart.dim_work_mode (work_mode_name)
SELECT DISTINCT work_mode
FROM clean.hr_employees
ORDER BY work_mode;

-- ── dim_date ────────────────────────────────────────────────
CREATE TABLE mart.dim_date (
    date_key    INTEGER PRIMARY KEY,
    full_date   DATE NOT NULL UNIQUE,
    year        SMALLINT NOT NULL,
    quarter     SMALLINT NOT NULL,
    month       SMALLINT NOT NULL,
    month_name  VARCHAR(20) NOT NULL
);

INSERT INTO mart.dim_date (date_key, full_date, year, quarter, month, month_name)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER             AS date_key,
    d                                           AS full_date,
    EXTRACT(YEAR  FROM d)::SMALLINT             AS year,
    EXTRACT(QUARTER FROM d)::SMALLINT           AS quarter,
    EXTRACT(MONTH  FROM d)::SMALLINT            AS month,
    TO_CHAR(d, 'Month')                         AS month_name
FROM generate_series(
    (SELECT MIN(hire_date) FROM clean.hr_employees),
    (SELECT MAX(hire_date) FROM clean.hr_employees),
    '1 day'::INTERVAL
) AS d;

-- ═════════════════════════════════════════════════════════════
-- Fact Table
-- ═════════════════════════════════════════════════════════════

CREATE TABLE mart.fact_employee (
    employee_id              VARCHAR(20)   NOT NULL PRIMARY KEY,
    department_key           INTEGER       NOT NULL,
    job_level_key            INTEGER       NOT NULL,
    location_key             INTEGER       NOT NULL,
    hire_date_key            INTEGER       NOT NULL,
    performance_rating_key   INTEGER       NOT NULL,
    status_key               INTEGER       NOT NULL,
    work_mode_key            INTEGER       NOT NULL,
    salary                   NUMERIC(10,2) NOT NULL,
    age                      INTEGER       NOT NULL,
    experience_years         INTEGER       NOT NULL,
    tenure_years             NUMERIC(5,1)  NOT NULL
);

INSERT INTO mart.fact_employee (
    employee_id,
    department_key,
    job_level_key,
    location_key,
    hire_date_key,
    performance_rating_key,
    status_key,
    work_mode_key,
    salary,
    age,
    experience_years,
    tenure_years
)
SELECT
    h.employee_id,
    d.department_key,
    j.job_level_key,
    l.location_key,
    TO_CHAR(h.hire_date, 'YYYYMMDD')::INTEGER,
    p.performance_rating_key,
    s.status_key,
    w.work_mode_key,
    h.salary,
    h.age,
    h.experience_years,
    h.tenure_years
FROM clean.hr_employees h
JOIN mart.dim_department d          ON h.department         = d.department_name
JOIN mart.dim_job_level j           ON h.job_level          = j.job_level_name
JOIN mart.dim_location l            ON h.country            = l.country
                                   AND h.city               = l.city
JOIN mart.dim_performance_rating p  ON h.performance_rating = p.performance_rating
JOIN mart.dim_status s              ON h.status             = s.status_name
JOIN mart.dim_work_mode w           ON h.work_mode          = w.work_mode_name;

-- ═════════════════════════════════════════════════════════════
-- Constraints
-- ═════════════════════════════════════════════════════════════

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_department
    FOREIGN KEY (department_key) REFERENCES mart.dim_department(department_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_job_level
    FOREIGN KEY (job_level_key) REFERENCES mart.dim_job_level(job_level_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_location
    FOREIGN KEY (location_key) REFERENCES mart.dim_location(location_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_hire_date
    FOREIGN KEY (hire_date_key) REFERENCES mart.dim_date(date_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_performance_rating
    FOREIGN KEY (performance_rating_key) REFERENCES mart.dim_performance_rating(performance_rating_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_status
    FOREIGN KEY (status_key) REFERENCES mart.dim_status(status_key);

ALTER TABLE mart.fact_employee ADD CONSTRAINT fk_fact_work_mode
    FOREIGN KEY (work_mode_key) REFERENCES mart.dim_work_mode(work_mode_key);

-- ═════════════════════════════════════════════════════════════
-- Indexes
-- ═════════════════════════════════════════════════════════════

CREATE INDEX idx_fact_department_key        ON mart.fact_employee(department_key);
CREATE INDEX idx_fact_job_level_key         ON mart.fact_employee(job_level_key);
CREATE INDEX idx_fact_location_key          ON mart.fact_employee(location_key);
CREATE INDEX idx_fact_hire_date_key         ON mart.fact_employee(hire_date_key);
CREATE INDEX idx_fact_performance_rating    ON mart.fact_employee(performance_rating_key);
CREATE INDEX idx_fact_status_key            ON mart.fact_employee(status_key);
CREATE INDEX idx_fact_work_mode_key         ON mart.fact_employee(work_mode_key);
CREATE INDEX idx_fact_employee_id           ON mart.fact_employee(employee_id);

-- ═════════════════════════════════════════════════════════════
-- Statistics
-- ═════════════════════════════════════════════════════════════

ANALYZE mart.dim_department;
ANALYZE mart.dim_job_level;
ANALYZE mart.dim_location;
ANALYZE mart.dim_performance_rating;
ANALYZE mart.dim_status;
ANALYZE mart.dim_work_mode;
ANALYZE mart.dim_date;
ANALYZE mart.fact_employee;

-- ═════════════════════════════════════════════════════════════
-- Validation
-- ═════════════════════════════════════════════════════════════

SELECT 'dim_department'         AS table_name, COUNT(*) AS row_count FROM mart.dim_department
UNION ALL
SELECT 'dim_job_level',                        COUNT(*)             FROM mart.dim_job_level
UNION ALL
SELECT 'dim_location',                         COUNT(*)             FROM mart.dim_location
UNION ALL
SELECT 'dim_performance_rating',               COUNT(*)             FROM mart.dim_performance_rating
UNION ALL
SELECT 'dim_status',                           COUNT(*)             FROM mart.dim_status
UNION ALL
SELECT 'dim_work_mode',                        COUNT(*)             FROM mart.dim_work_mode
UNION ALL
SELECT 'dim_date',                             COUNT(*)             FROM mart.dim_date
UNION ALL
SELECT 'fact_employee',                        COUNT(*)             FROM mart.fact_employee
ORDER BY table_name;

-- =============================================================
-- HR Analytics - Data Cleaning & Transformation
-- =============================================================
-- Pipeline order:
--   1. Fix negative Experience_Years     → 0
--   2. Fix negative/zero Salary          → median by (dept, job_level)
--   3. Fix Age / Exp violations          → Age = Exp + 22
--   4. Impute missing Performance_Rating → mode by department
--   5. Feature engineering               → hire_year, tenure_years
-- Quality flags added for full traceability in Power BI.
-- Dataset snapshot year = 2026
-- Tenure computed relative to 2026-12-31
-- (not current system date)
-- =============================================================

DROP TABLE IF EXISTS clean.hr_employees;

CREATE TABLE clean.hr_employees AS

WITH global_median AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS global_median_salary
    FROM raw.hr_employees_raw
    WHERE salary > 0
),

-- ── 1. Fix negative Experience_Years ──────────────────────────
exp_fixed AS (
    SELECT
        *,
        CASE
            WHEN experience_years < 0 THEN 0
            ELSE experience_years
        END                                 AS exp_corrected,
        (experience_years < 0)
                                            AS was_exp_corrected
    FROM raw.hr_employees_raw
),

-- ── 2. Fix negative / zero Salary ────────────────────────────
salary_medians AS (
    SELECT
        department,
        job_level,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
    FROM raw.hr_employees_raw
    WHERE salary > 0
    GROUP BY department, job_level
),
salary_fixed AS (
    SELECT
        e.*,
        CASE
            WHEN e.salary <= 0 THEN COALESCE(m.median_salary, g.global_median_salary)
            ELSE e.salary
        END                                 AS salary_corrected,
        (e.salary <= 0)
                                            AS was_salary_corrected
    FROM exp_fixed e
    LEFT JOIN salary_medians m ON e.department = m.department AND e.job_level = m.job_level
    CROSS JOIN global_median g
),

-- ── 3. Fix Age / Experience violations ───────────────────────
age_fixed AS (
    SELECT
        *,
        CASE
            WHEN age < exp_corrected + 22 THEN exp_corrected + 22
            ELSE age
        END                                 AS age_corrected,
        (age < exp_corrected + 22)
                                            AS was_age_corrected
    FROM salary_fixed
),

-- ── 4. Impute missing Performance_Rating ─────────────────────
dept_rating_counts AS (
    SELECT
        department,
        performance_rating,
        COUNT(*) AS cnt
    FROM raw.hr_employees_raw
    WHERE performance_rating IS NOT NULL
    GROUP BY department, performance_rating
),
dept_mode AS (
    SELECT DISTINCT ON (department)
        department,
        performance_rating                  AS dept_mode_rating
    FROM dept_rating_counts
    ORDER BY department, cnt DESC, performance_rating
),
ratings_fixed AS (
    SELECT
        a.*,
        COALESCE(a.performance_rating, m.dept_mode_rating) AS rating_corrected,
        (a.performance_rating IS NULL)                       AS was_rating_imputed
    FROM age_fixed a
    LEFT JOIN dept_mode m ON a.department = m.department
),

-- ── 5. Feature engineering ───────────────────────────────────
tenure_computed AS (
    SELECT *,
        ROUND(
            ((DATE '2026-12-31' - hire_date::DATE)::numeric / 365.25),
            1
        ) AS tenure_years
    FROM ratings_fixed
)

SELECT
    employee_id,
    full_name,
    department,
    job_title,
    hire_date::DATE                                             AS hire_date,
    EXTRACT(YEAR FROM hire_date::DATE)::INTEGER                 AS hire_year,
    rating_corrected                                            AS performance_rating,
    exp_corrected                                               AS experience_years,
    age_corrected                                               AS age,
    salary_corrected                                            AS salary,
    was_exp_corrected,
    was_salary_corrected,
    was_age_corrected,
    was_rating_imputed,
    (
        was_exp_corrected
        OR was_salary_corrected
        OR was_age_corrected
        OR was_rating_imputed
    )                                                           AS was_corrected,
    (
        was_exp_corrected::int
        + was_salary_corrected::int
        + was_age_corrected::int
        + was_rating_imputed::int
    )                                                           AS correction_count,
    tenure_years,
    status,
    work_mode,
    country,
    city,
    job_level,
    CURRENT_TIMESTAMP                                           AS cleaned_at
FROM tenure_computed;

-- ── Constraints ─────────────────────────────────────────────
ALTER TABLE clean.hr_employees ALTER COLUMN employee_id SET NOT NULL;
ALTER TABLE clean.hr_employees ADD PRIMARY KEY (employee_id);

ALTER TABLE clean.hr_employees ADD CONSTRAINT chk_salary_positive
    CHECK (salary > 0);

ALTER TABLE clean.hr_employees ADD CONSTRAINT chk_age_experience
    CHECK (age >= experience_years + 22);

-- ── Analytical indexes ──────────────────────────────────────
CREATE INDEX idx_clean_department  ON clean.hr_employees(department);
CREATE INDEX idx_clean_job_level   ON clean.hr_employees(job_level);
CREATE INDEX idx_clean_hire_year   ON clean.hr_employees(hire_year);
CREATE INDEX idx_clean_salary      ON clean.hr_employees(salary);
CREATE INDEX idx_clean_dept_level  ON clean.hr_employees(department, job_level);

